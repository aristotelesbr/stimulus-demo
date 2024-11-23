# frozen_string_literal: true

require 'erb'
require 'tilt'

class Lennarb
  module Plugins
    module Render
      class TemplateNotFound < StandardError; end
      class LayoutNotFound < StandardError; end

      def self.configure(app, *, templates_path: 'templates', default_layout: 'layout')
        raise TemplateNotFound, "Template path not found: #{templates_path}" unless Dir.exist?(templates_path)
        raise LayoutNotFound, "Layout not found: #{default_layout}" unless File.exist?(
          File.join(
            templates_path,
            "#{default_layout}.erb"
          )
        )

        app.instance_variable_set(:@templates_path, templates_path)
        app.instance_variable_set(:@default_layout, default_layout)
        app.extend(ClassMethods)
        app.include(InstanceMethods)
      end

      module ClassMethods
        def templates_path(path)
          @templates_path = path
        end

        def default_layout(layout_name)
          @default_layout = layout_name
        end
      end

      module InstanceMethods
        def render(template_name, locals: {}, layout: true)
          template_content = render_template(template_name, locals)

          if layout
            layout_name = layout.is_a?(String) ? layout : self.class.instance_variable_get(:@default_layout)
            layout_template = find_template("#{layout_name}.erb")
            layout_template.render(self, locals) { template_content }
          else
            template_content
          end
        end

        private

        def render_template(template_name, locals = {})
          template =
            if template_name.end_with?('.erb')
              find_template(template_name)
            else
              find_template("#{template_name}.erb")
            end

          template.render(self, locals)
        rescue Tilt::TemplateNotFound
          raise TemplateNotFound, "Template not found: #{template_name}"
        end

        def find_template(template_name)
          templates_path = self.class.instance_variable_get(:@templates_path)
          template_path = File.join(templates_path, template_name)

          partial_path = File.join(File.dirname(template_path), "_#{File.basename(template_name)}")
          template_path = partial_path if File.exist?(partial_path)

          Tilt.new(template_path)
        end

        def partial(template_name, locals: {})
          render(template_name, locals: locals, layout: false)
        end
      end
    end

    Lennarb::Plugin.register(:render, Render)
  end
end
