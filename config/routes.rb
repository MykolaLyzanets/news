# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :users, skip: %i[registrations]

  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?

  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  namespace :admin do
    root to: 'home#index'
    resources :sources, except: :show do
      post :fetch, on: :member
      post :test, on: :member
      post :toggle, on: :member
      post :parse, on: :member
      post :parse_all, on: :collection
      post :fetch_all, on: :collection
    end
    resources :posts, only: %i[index edit update destroy] do
      post :rewrite, on: :member
      post :publish, on: :member
      post :hide, on: :member
      post :rewrite_all, on: :collection
      post :regenerate, on: :member
    end
    resources :events, only: %i[index show] do
      post :publish, on: :member
      post :hide, on: :member
      post :regenerate, on: :member
      post :merge, on: :member
      post :split, on: :member
      post :ignore, on: :member
    end
  end

  get '(*path)', to: redirect { |_params, request|
    request.original_url.sub('www.', '')
  }, constraints: { host: /^www\./ }

  scope '(:locale)', locale: /(#{I18n.available_locales.map(&:to_s).join('|')})/ do
    root 'home#index'
    get 'articles/:id', to: 'articles#show', as: :article
    get 'topics/:id', to: 'topics#show', as: :topic
    get ':section', to: 'categories#show', as: :section,
        constraints: { section: /world|politics|business|technology|science|culture|sport/ }

    match '*path', to: 'home#not_found', via: :all, constraints: lambda { |req|
      path = req.path
      path.exclude?('uploads') &&
        !path.start_with?('/rails/') &&
        !path.start_with?('/assets/')
    }
  end
end
