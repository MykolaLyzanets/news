# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  layout :set_layout

  def default_url_options
    { protocol: Rails.env.production? ? 'https' : 'http' }
  end

  def after_sign_in_path_for(resource)
    if resource.respond_to?(:admin?) && resource.admin?
      stored_location_for(resource) || admin_root_path
    else
      super
    end
  end

  private

  def set_layout
    devise_controller? ? 'auth' : 'application'
  end

  def render_not_found
    @not_found = true
    @noindex = true
    render template: 'home/not_found', status: :not_found
  end
end
