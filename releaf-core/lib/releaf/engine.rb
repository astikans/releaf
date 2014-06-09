require 'gravatar_image_tag'
require 'jquery-cookie-rails'
require 'rails-settings-cached'
require 'stringex'
require 'tinymce-rails'
require 'will_paginate'
require 'font-awesome-rails'
require 'haml'
require 'haml-rails'
require 'jquery-rails'
require 'jquery-ui-rails'
require 'acts_as_list'
require 'awesome_nested_set'
require 'devise'
require 'dragonfly'
require 'axlsx_rails'
require 'globalize'
require 'globalize-accessors'

module Releaf::Core
  require 'releaf/core/attachments_component'
end

module Releaf
  class Engine < ::Rails::Engine
  end

  ActiveSupport.on_load :action_controller do
    ActionDispatch::Routing::Mapper.send(:include, Releaf::RouteMapper)
  end
end
