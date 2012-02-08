module Sage
  module ActionView
    module Helpers
      module ActiveMerchantCountryList
        
        #Use ActiveMerchant's list of countries and country codes to create a select list.
        class CountryList < ActiveMerchant::Country
          def self.code_to_country_mapping
            list = COUNTRIES.inject({}) do |l, c|
              l[c[:alpha2]] = c[:name]
              l
            end
          end

          def self.country_to_code_array
            list = COUNTRIES.collect do |c|
              [c[:name], c[:alpha2]]
            end
          end

          def self.names
            list = COUNTRIES.collect do |c|
              c[:name]
            end
          end
        end
        
      end
    end
  end
end
