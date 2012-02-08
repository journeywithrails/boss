module PaymentsHelper
  
  def invoice_id_if_present
    field_if_not_blank(params[:invoice_id], {}){{:invoice_id => params[:invoice_id]}}
  end

  def form_row(name, field)
    <<-row
      <tr>
        <th>#{ name }</th>
        <td>#{ field }</td>
      </tr>
    row
  end

  def select_provinces
    ActiveMerchant::Billing::Integrations::Paypal::Helper::
      CANADIAN_PROVINCES.sort.map do |code, name| 
        ["#{ code } - #{ _(name) }", code] 
      end
  end

  def select_states
    [['AL - '+_('Alabama'), 'AL'],
      ['AK - '+_('Alaska'), 'AK'],
      ['AZ - '+_('Arizona'), 'AZ'],
      ['AR - '+_('Arkansas'), 'AR'],
      ['CA - '+_('California'), 'CA'],
      ['CO - '+_('Colorado'), 'CO'],
      ['CT - '+_('Connecticut'), 'CT'],
      ['DE - '+_('Delaware'), 'DE'],
      ['DC - '+_('District of Columbia'), 'DC'],
      ['FL - '+_('Florida'), 'FL'],
      ['GA - '+_('Georgia'), 'GA'],
      ['HI - '+_('Hawaii'), 'HI'],
      ['ID - '+_('Idaho'), 'ID'],
      ['IL - '+_('Illinois'), 'IL'],
      ['IN - '+_('Indiana'), 'IN'],
      ['IA - '+_('Iowa'), 'IA'],
      ['KS - '+_('Kansas'), 'KS'],
      ['KY - '+_('Kentucky'), 'KY'],
      ['LA - '+_('Louisiana'), 'LA'],
      ['ME - '+_('Maine'), 'ME'],
      ['MD - '+_('Maryland'), 'MD'],
      ['MA - '+_('Massachusetts'), 'MA'],
      ['MI - '+_('Michigan'), 'MI'],
      ['MN - '+_('Minnesota'), 'MN'],
      ['MS - '+_('Mississippi'), 'MS'],
      ['MO - '+_('Missouri'), 'MO'],
      ['MT - '+_('Montana'), 'MT'],
      ['NE - '+_('Nebraska'), 'NE'],
      ['NV - '+_('Nevada'), 'NV'],
      ['NH - '+_('New Hampshire'), 'NH'],
      ['NJ - '+_('New Jersey'), 'NJ'],
      ['NM - '+_('New Mexico'), 'NM'],
      ['NY - '+_('New York'), 'NY'],
      ['NC - '+_('North Carolina'), 'NC'],
      ['ND - '+_('North Dakota'), 'ND'],
      ['OH - '+_('Ohio'), 'OH'],
      ['OK - '+_('Oklahoma'), 'OK'],
      ['OR - '+_('Oregon'), 'OR'],
      ['PA - '+_('Pennsylvania'), 'PA'],
      ['RI - '+_('Rhode Island'), 'RI'],
      ['SC - '+_('South Carolina'), 'SC'],
      ['SD - '+_('South Dakota'), 'SD'],
      ['TN - '+_('Tennessee'), 'TN'],
      ['TX - '+_('Texas'), 'TX'],
      ['UT - '+_('Utah'), 'UT'],
      ['VT - '+_('Vermont'), 'VT'],
      ['VA - '+_('Virginia'), 'VA'],
      ['WA - '+_('Washington'), 'WA'],
      ['WV - '+_('West Virginia'), 'WV'],
      ['WI - '+_('Wisconsin'), 'WI'],
      ['WY - '+_('Wyoming'), 'WY'],
      ['AS - '+_('American Samoa'), 'AS'],
      ['FM - '+_('Federated States of Micronesia'), 'FM'],
      ['GU - '+_('Guam'), 'GU'],
      ['MH - '+_('Marshall Islands'), 'MH'],
      ['MP - '+_('Northern Mariana Islands'), 'MP'],
      ['PW - '+_('Palau'), 'PW'],
      ['PR - '+_('Puerto Rico'), 'PR'],
      ['VI - '+_('Virgin Islands'), 'VI'],
      ['AA - '+_('Armed Forces Americas'), 'AA'],
      ['AE - '+_('Armed Forces'), 'AE'],
      ['AP - '+_('Armed Forces Pacific'), 'AP']
    ]
  end

  def select_states_and_provinces
    select_provinces + select_states
  end

  #These countries appear at the top of the country list.
  def payment_priority_countries
    [[_('Canada'), 'CA'], [_('United States'), 'US']]
  end
  
  def select_countries(*countries)
    if countries.empty?
      #Use all countries
      Sage::ActionView::Helpers::ActiveMerchantCountryHelper::CountryList.country_to_code_array
    else
      mapping = Sage::ActionView::Helpers::ActiveMerchantCountryHelper::CountryList.code_to_country_mapping
      countries.map do |code|
        name = mapping[code]
        [name, code]
      end
    end
  end

  #Because we only have state/province codes for Canada and US, use text field for everything else.
  def province_state_selector_for_payment(billing_address)
    result =  case billing_address.country
      when 'CA' then select(:billing_address, :state, select_provinces, {:prompt => _('– Select %{statelabel} –') % { :statelabel => _( billing_address.country_settings.state_label)}})
      when 'US' then select(:billing_address, :state, select_states,    {:prompt => _('– Select %{statelabel} –') % { :statelabel => _( billing_address.country_settings.state_label)}})
      else text_field(:billing_address, :state)
    end
  end
  
end
