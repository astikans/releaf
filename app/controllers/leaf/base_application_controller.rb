module Leaf
  class BaseApplicationController < ActionController::Base
    before_filter :authenticate_admin!
    # check_authorization :unless => :devise_controller?
    layout 'leaf/admin'
    protect_from_forgery

    def current_ability
      @current_ability ||= AdminAbility.new(current_admin)
    end
  end
end