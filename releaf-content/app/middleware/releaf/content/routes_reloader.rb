module Releaf::Content
  class RoutesReloader
    def initialize(app)
      @app = app
      self.class.routes_loaded
    end

    def call(env)
      self.class.reload_if_expired
      @app.call(env)
    end

    def self.routes_loaded
      @updated_at = Time.now
    end

    def self.reload_if_expired
      # TODO Node class should be configurable
      return unless ::Node.updated_at.present? && @updated_at && @updated_at < ::Node.updated_at
      Rails.application.reload_routes!
      routes_loaded
    end

  end
end
