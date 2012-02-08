module LastObelus
  module ActionView
    module Helpers
      module ConditionalParserHelper
        def unless_partial(partial, locals={}, &block)
          begin
            output = render :partial => "#{partial}", :locals => locals
            if block_given?
                # block given, so they may not be using <%= on the helper call, so you can't just return it.
              concat(output || '', block.binding)
            else
                # no block given, they used <%=
              return output
            end
          rescue ::ActionView::NoTemplateError => e# no overriding partial
            RAILS_DEFAULT_LOGGER.debug("unless_partial")
            yield if block_given?
          end
          # contingency for <%= on a with block--the block is doing the concatting
          return ''
        end

        def options_for_mail(delivery, form, entity, mail_name, locals={})
          entity_name = entity.class.name.underscore
          mailer_name = "#{entity_name}_mailer"
          partial = "#{mailer_name}/#{mail_name}_options"
          RAILS_DEFAULT_LOGGER.debug("options_for_mail: entity_name: #{entity_name.inspect}\n   mailer_name: #{mailer_name.inspect}   partial: #{partial.inspect}")
          unless_partial(partial, {:delivery => delivery, entity_name => entity, :f => form}.merge(locals))
        end
      end
    end
  end
end

ActionView::Base.send(:include, LastObelus::ActionView::Helpers::ConditionalParserHelper)