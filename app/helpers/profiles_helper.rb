module ProfilesHelper

  def selected_time_zone(country)
    case country
    when "CA", "US"
      selected = "PST8PDT"
    when "ZA"
      selected = "Africa/Johannesburg"
    when "FR"
      selected = "Europe/Paris"
    when "JP"
      selected = "Asia/Tokyo"
    when "PT"
      selected = "WET"
    when "AU"
      selected = "Australia/Sydney"
    else
      selected = "GMT"
    end
  end
  
  def select_heard_from(object, method)
    # Radar : it shows the text field depending on the matched string
    select_options = [
  			[_("Please select one"), ""],
        [_("Accountant / Bookkeeper"), "accountantbookkeeper"],
        [_("Banks"), "Banks"],
        [_("Business expert blog"), "Business expert blog"],
        [_("Educational Institutions"), "Educational Institutions"],
        [_("Friend / colleague"), "Friend / colleague"],
        [_("Newspaper"), "Newspaper"],
        [_("Online Magazine"), "Online Magazine"],
        [_("Print Magazine"), "Print Magazine"],
        [_("Search engine"), "Search engine"],
        [_("Small business website"), "Small business website"],
        [_("Social Network (Facebook, Twitter, LinkedIn, etc)"), "Social Network (Facebook, Twitter, LinkedIn, etc)"],
        [_("Small Business / Industry Associations"), "Small Business / Industry Associations"],
        [_("Other (please specify)"), "other"]
      ]
   return select(object, method, select_options)
  end
  
  def display_text_field?(profile)
    if profile.heard_from == "other" or profile.heard_from == "accountantbookkeeper"
      return true
    else
      return false
    end
  end
    
  def get_sections_js(profile)
    str = "["
    profile.sections.each_with_index do |s, i|
      str += "\""
      str += s
      str += "\""
      str += ", " unless ((profile.sections.size - 1) == i)
    end
    str += "]"
    str
  end
  
  #the method below might belong in model,
  #not sure where it best belongs
  def tab_errored?(tab)

    case tab
      when "user_addressing_link"
        return false
      when "user_taxes_link"
        return true if @profile.errors[:tax_1_name]
        return true if @profile.errors[:tax_2_name]
        return true if @profile.errors[:tax_1_rate]
        return true if @profile.errors[:tax_2_rate]
        return false
      when "user_logo_link"
        return true if @profile.logo && (@profile.logo.errors.size > 0)
        return false
      when "user_communications_link"
        return false
      when "user_payments_link"
        return true if @user_gateway && !@user_gateway.valid?
        return false
    end
    return false
  end
  
  def highlight_on_error_for(tab)
    tab_errored?(tab) ? "errored" : ""
  end

  def form_for_designated_profiles_tab
    RAILS_DEFAULT_LOGGER.debug("@designated_tab: #{@designated_tab.inspect}")
    "form_user_#{@designated_tab || 'addressing'}"
  end
end

