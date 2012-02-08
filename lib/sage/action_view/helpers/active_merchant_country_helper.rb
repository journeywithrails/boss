module Sage
  module ActionView
    module Helpers
      module ActiveMerchantCountryHelper
        
        include Sage::ActionView::Helpers::ActiveMerchantCountryList
        
        module FormOptionsHelper
          # Mostly copied from country_options_for_select
          def active_merchant_country_options_for_select(selected = nil, priority_countries = nil)
            country_options = ""

            if priority_countries
              country_options += options_for_select(priority_countries, selected)
              country_options += "<option value=\"\" disabled=\"disabled\">-------------</option>\n"
            end
            
            countries = Sage::ActionView::Helpers::ActiveMerchantCountryHelper::CountryList.country_to_code_array

            return country_options + options_for_select(countries, selected)
          end
        end
        
        module ActiveMerchantCountryInstanceTag
          # Mostly copied from to_country_select_tag
          def to_country_select_tag_with_active_merchant(priority_countries, options, html_options)
            return to_country_select_tag_without_active_merchant(priority_countries, options, html_options) unless options.delete(:active_merchant)
            html_options = html_options.stringify_keys
            add_default_name_and_id(html_options)
            value = value(object)
            content_tag("select",
              add_options(
                active_merchant_country_options_for_select(value, priority_countries),
                options, value
              ), html_options
            )
          end

          def self.included(base)
            base.alias_method_chain :to_country_select_tag, :active_merchant
          end
        end
        
      end
    end
  end
end

::ActionView::Helpers::FormOptionsHelper.send(:include, Sage::ActionView::Helpers::ActiveMerchantCountryHelper::FormOptionsHelper)
::ActionView::Helpers::InstanceTag.send(:include, Sage::ActionView::Helpers::ActiveMerchantCountryHelper::ActiveMerchantCountryInstanceTag)
# InstanceTag already included FormOptionsHelper, so include it for InstanceTag too.
::ActionView::Helpers::InstanceTag.send(:include, Sage::ActionView::Helpers::ActiveMerchantCountryHelper::FormOptionsHelper)
