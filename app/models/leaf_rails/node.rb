module LeafRails
  class Node < ActiveRecord::Base
    acts_as_nested_set
    acts_as_list :scope => :parent_id
    self.table_name = 'leaf_rails_nodes'

    serialize :data, Hash
    default_scope :order => 'position'

    attr_accessible :name, :parent_id, :slug, :position, :data, :content_class, :content_string

    alias_attribute :to_text, :name

    def content_object
      if id && content_id
        @content_object = content_class.classify.constantize.find(content_id)
      end
    end

    def url
      if parent_id
        url = parent.url + "/" + slug.to_s
      else
        url = slug.to_s
      end

      url
    end

    def controller
      controller_class = nil

      if  (content_class =~ /Controller$/i) != nil
        controller_class = content_class.constantize
      elsif content_object
          controller_class = content_class.constantize::PUBLIC_CONTROLLER.constantize
      end

      controller_class
    end

    def is_controller_node
      if  (content_class =~ /Controller$/i) != nil && content_class.constantize < LeafController
        return true
      else
        return false
      end
    end

    def self.maintain_base_controllers
      locales = Settings.i18n_locales
      tree = {}

      # 1) build up controller tree
      Rails.application.routes.routes.routes.map do|r|
        # skip /admin controllers
        if (r.path.spec.to_s =~ /^\/admin/) == nil && !r.defaults[:controller].to_s.empty?
          class_name = "#{r.defaults[:controller]}_controller".classify.constantize
          if class_name < LeafController
            path = r.path.spec.to_s.gsub("(.:format)", "")
            path = path.split("/").reject(&:empty?)

            item = {:controller => class_name, :action => r.defaults[:action]}

            if path.last != ":id"
              if path[0] == ":locale"
                locales.each do |locale|
                  path[0] = locale
                  tree[path.join("/")] = item
                end
              else
                tree[path.join("/")] = item
              end
            end
          end
        end
      end

        # 2) maintain tree against node content
        tree = Hash[tree.sort]
        tree.each do | url, item |
          parent_path = url.split("/")[0...-1].join("/")
          create = false
          n = nil

          slug = url.split("/").last
          content_string = slug + ":" + item[:action].to_s

          if parent_path.empty?
            parent_id = nil
            n = self::get_object_from_path url, :strict => true
            if !n
              create = true
            end
          else
            parent_item = tree[parent_path]
            if parent_item && parent_item[:node]
              parent_id = parent_item[:node].id
              n = Node.where(:parent_id => parent_id, :content_class => item[:controller].to_s, :content_string => content_string ).first
              if !n
                create = true
              end
            end
          end

          if create
            n = Node.create!(:name => slug, :content_class => item[:controller].to_s, :content_string => content_string, :parent_id => parent_id, :slug => slug)
          end

          item[:node] = n
          tree[url] = item

        end
    end

    def self.get_object_from_path path, params = {}
      node = nil
      parent_node = nil

      if path.class == String
        path = path.split("/").reject(&:empty?)
      end

      unless params[:locale].nil?
        parent_node = Node.roots.find_by_slug(params[:locale])
      end

      path.each do |part|
        node = Node.where(:parent_id => (parent_node ? parent_node.id : nil), :slug => part).limit(1).first
        if node
          parent_node = node
        else
          unless params[:strict].blank?
            node = nil
          else
            node = parent_node
          end
          break
        end
      end

      unless params[:controller].nil?
        if params[:controller] != node.controller.to_s
          node = nil
        end
      end

      node
    end

    def to_s
      name
    end

  end
end
