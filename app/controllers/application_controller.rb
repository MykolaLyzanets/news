# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Localable

  protect_from_forgery with: :exception
  layout :set_layout

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
end
