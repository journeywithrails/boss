# use this module to have an Active Record object address labels based on the selected country
module CountrySettings
  
  def country_settings(country = nil)    
    country ||= self.country
    CountrySettings.new(country)
  end
  
  
  class CountrySettings 
    
    attr_reader :country
    
    # this hash matches the country value selected to the name of array in state_select (eg US_STATES)
    # and the label to use for province or state and postal code or zip
    SETTINGS={'Argentina'     => {:state_key => 'ARGENTINA', :state_label => N_('Province'), :postalcode_label => N_('Postal Code')},
                      'Australia'     => {:state_key => 'AUSTRALIA', :state_label => N_('Province'), :postalcode_label => N_('Postal Code')},
                      'Brazil'        => {:state_key => 'BRAZIL', :state_label => N_('State'), :postalcode_label => N_('Postal Code')},
                      'Canada'        => {:state_key => 'CANADA', :state_label => N_('Province'), :postalcode_label => N_('Postal Code')},
                      'Costa Rica'    => {:state_key => 'COSTARICA', :state_label => N_('Province'), :postalcode_label => N_('Postal Code')},
                      'Cuba'          => {:state_key => 'CUBA', :state_label => N_('Province'), :postalcode_label => N_('Postal Code')},
                      'France'        => {:state_key => 'FRANCE', :state_label => N_('Region'), :postalcode_label => N_('Postal Code')},
                      'Germany'       => {:state_key => 'GERMAN', :state_label => N_('State'), :postalcode_label => N_('PLZ')},
                      'India'         => {:state_key => 'INDIA', :state_label => N_('Province'), :postalcode_label => N_('Pincode')},
                      'Japan'         => {:state_key => 'JAPAN', :state_label => N_('Prefecture'), :postalcode_label => N_('Postal Code')},
                      'Mexico'        => {:state_key => 'MEXICO', :state_label => N_('State'), :postalcode_label => N_('Postal Code')},
                      'South Africa'  => {:state_key => 'SOUTHAFRICA', :state_label => N_('Province'), :postalcode_label => N_('Postal Code')},
                      'Spain'         => {:state_key => 'SPAIN',:state_label => N_('Province'), :postalcode_label => N_('Postal Code')},
                      'Uganda'        => {:state_key => 'UGANDA', :state_label => N_('Province'), :postalcode_label => N_('Postal Code')},
                      'United States' => {:state_key => 'US', :state_label => N_('State'), :postalcode_label => N_('Zip Code')},
                      'Venezuela'     => {:state_key => 'VENEZUELA', :state_label => N_('State'), :postalcode_label => N_('Postal Code')},
                      'default'       => {:state_key => 'CANADA', :state_label => N_('Province'), :postalcode_label => N_('Postal Code')}}
                  
     def initialize(country)
       @country = country
       mapping = Sage::ActionView::Helpers::ActiveMerchantCountryHelper::CountryList.code_to_country_mapping
       @country = mapping[@country] if mapping.has_key?(@country) unless @country.nil?
     end
                    
    def partial      
      return 'known_country' if @country.nil? # because the we will be using the default country
      return SETTINGS[@country].nil? ? 'unknown_country' : 'known_country'
    end
    
    def setting(key)
      SETTINGS[@country].nil? ? SETTINGS['default'][key] : SETTINGS[@country][key]  
    end
                  
    def state_label
      setting(:state_label)
    end

    def postalcode_label
      setting(:postalcode_label)
    end

    def state_key    
      setting(:state_key)
    end

  end

end
