module ZeroRails
  module OpenApi
    module Generator
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def generate_docs(api_name = nil)
          Rails.application.eager_load!
          docs = if api_name.present?
                   generate_doc api_name
                 else
                   ZeroRails::OpenApi.apis.keys.map { |n| generate_doc n }
                 end
          puts docs
        end

        def generate_doc(api_name)
          settings = ZeroRails::OpenApi.apis[api_name]
          doc = { openapi: '3.0.0' }.merge(settings.slice :info, :servers).merge({
                  security: settings[:global_security],
                  tags: [ ],
                  paths: { }
                })
          settings[:root_controller].descendants.each do |ctrl|
            doc[:paths].merge! ctrl.instance_variable_get '@api_infos'
            doc[:tags] << ctrl.instance_variable_get('@ctrl_infos')
          end
          doc
        end

        def write_docs
          docs = generate_docs
          puts docs
        end
      end

      def self.generate_routes_list
        # see https://github.com/rails/rails/blob/master/railties/lib/rails/tasks/routes.rake
        require './config/routes'
        all_routes = Rails.application.routes.routes
        require "action_dispatch/routing/inspector"
        inspector = ActionDispatch::Routing::RoutesInspector.new(all_routes)

        inspector.format(ActionDispatch::Routing::ConsoleFormatter.new, nil).split("\n")[1..-1].map do |line|
          infos = line.match(/[A-Z].*/).to_s.split(' ')
          {
              http_verb: infos[0],                  # => "GET"
              path: infos[1].sub('(.:format)', ''), # => "/api/v1/examples"
              ctrl_action: infos[2]                 # => "api/v1/examples#index"
          }
        end.group_by {|api| api[:ctrl_action].split('#').first } # => { "api/v1/examples" => [..] }
      end
    end
  end
end