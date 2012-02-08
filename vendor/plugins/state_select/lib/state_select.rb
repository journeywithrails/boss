module ActionView::Helpers::FormOptionsHelper
  
  # Return select and option tags for the given object and method, using state_options_for_select to generate the list of option tags.
  def state_select(object, method, country='US', options = {}, html_options = {})
    ActionView::Helpers::InstanceTag.new(object, method, self, nil, options.delete(:object)).to_state_select_tag(country, options, html_options)
  end
  
  # Returns a string of option tags for states in a country. Supply a state name as +selected+ to
  # have it marked as the selected option tag. 
  #
  # NOTE: Only the option tags are returned, you have to wrap this call in a regular HTML select tag.
  
  def state_options_for_select(selected = nil, country = 'US')
    state_options = ""
    if country
      state_options += options_for_select(eval(country.upcase+'_STATES'), selected)
    end
    return state_options
  end
  
  private
  
  ARGENTINA_STATES=[_("Buenos Aires"), _("Catamarca"), _("Chaco"), _("Chubut"), _("Ciudad autónoma de Buenos Aires"), _("Córdoba"), _("Corrientes"), _("Entre Ríos"), _("Formosa"), _("Jujuy"), _("Pampa"), _("La Rioja"), _("Mendoza"), _("Misiones"), _("Neuquén"), _("Río Negro"), _("Salta"), _("San Juan"), _("San Luis"), _("Santa Cruz"), _("Santa Fe"), _("Santiago del Estero"), _("Tierra del Fuego, Antártida e Islas del Atlántico Sur"), _("Tucumán")] unless const_defined?("ARGENTINA_STATES")
  AUSTRALIA_STATES=[_("Australian Capital Territory"), _("New South Wales"), _("Northern Territory"), _("Queensland"), _("South Australia"), _("Tasmania"), _("Victoria"), _("Western Australia")] unless const_defined?("AUSTRALIA_STATES")
  BRAZIL_STATES=[_("Acre"), _("Alagoas"), _("Amapá"), _("Amazonas"), _("Bahia"), _("Ceará"), _("Distrito Federal"), _("Espírito Santo"), _("Goiás"), _("Maranhão"), _("Mato Grosso"), _("Mato Grosso do Sul"), _("Minas Gerais"), _("Pará"), _("Paraíba"), _("Paraná"), _("Pernambuco"), _("Piauí"), _("Rio de Janeiro"), _("Rio Grande do Norte"), _("Rio Grande do Sul"), _("Rondônia"), _("Roraima"), _("Santa Catarina"), _("São Paulo"), _("Sergipe"), _("Tocantins")]  unless const_defined?("BRAZIL_STATES")
  CANADA_STATES=[_("Alberta"), _("British Columbia"), _("Manitoba"), _("New Brunswick"), _("Newfoundland and Labrador"), _("Northwest Territories"), _("Nova Scotia"), _("Nunavut"), _("Ontario"), _("Prince Edward Island"), _("Quebec"), _("Saskatchewan"), _("Yukon")] unless const_defined?("CANADA_STATES")
  COSTARICA_STATES=[_("Alajuela"), _("Cartago"), _("Guanacaste"), _("Heredia"), _("Limón"), _("Puntarenas"), _("San José")] unless const_defined?("COSTARICA_STATES")
  CUBA_STATES=[_("Pinar del Río"),_("La Habana"),_("Ciudad de La Habana"),_("Matanzas"),_("Cienfuegos"),_("Villa Clara"),_("Sancti Spíritus"),_("Ciego de Ávila"),_("Camagüey"),_("Las Tunas"),_("Granma"),_("Holguín"),_("Santiago de Cuba"),_("Guantánamo")] unless const_defined?("CUBA_STATES")
  FRANCE_STATES=[_("Alsace"),_("Aquitaine"),_("Auvergne"),_("Bourgogne"),_("Bretagne"),_("Centre"),_("Champagne-Ardenne"),_("Corse"),_("Franche-Comte"),_("Ile-de-France"),_("Languedoc-Roussillon"),_("Limousin"),_("Lorraine"),_("Midi-Pyrenees"),_("Nord-Pas-de-Calais"),_("Basse-Normandie"),_("Haute-Normandie"),_("Pays de la Loire"),_("Picardie"),_("Poitou-Charentes"),_("Provence-Alpes-Cote d'Azur"),_("Rhone-Alpes")] unless const_defined?("FRANCE_STATES")
  GERMAN_STATES=[_("Baden-Wurttemberg"), _("Bayern"), _("Berlin"), _("Brandenburg"), _("Bremen"), _("Hamburg"), _("Hessen"), _("Mecklenburg-Vorpommern"), _("Niedersachsen"), _("Nordrhein-Westfalen"), _("Rhineland-Pfaltz"), _("Saarland"), _("Sachsen"), _("Sachsen-Anhalt"), _("Schleswig-Holstein"), _("Thuringen")]  unless const_defined?("GERMAN_STATES")
  INDIA_STATES=[_("Andhra Pradesh"),  _("Arunachal Pradesh"),  _("Assam"), _("Bihar"), _("Chhattisgarh"), _("New Delhi"), _("Goa"), _("Gujarat"), _("Haryana"), _("Himachal Pradesh"), _("Jammu and Kashmir"), _("Jharkhand"), _("Karnataka"), _("Kerala"), _("Madhya Pradesh"), _("Maharashtra"), _("Manipur"), _("Meghalaya"), _("Mizoram"), _("Nagaland"), _("Orissa"),_("Punjab"), _("Rajasthan"), _("Sikkim"), _("Tamil Nadu"), _("Tripura"), _("Uttaranchal"), _("Uttar Pradesh"), _("West Bengal")] unless const_defined?("INDIA_STATES")
  JAPAN_STATES=[_("Aichi"), _("Akita"), _("Aomori"), _("Chiba"), _("Ehime"), _("Fukui"), _("Fukuoka"), _("Fukushima"), _("Gifu"), _("Gunma"), _("Hiroshima"), _("Hokkaidō"), _("Hyōgo"), _("Ibaraki"), _("Ishikawa"), _("Iwate"), _("Kagawa"), _("Kagoshima"), _("Kanagawa"), _("Kōchi"), _("Kumamoto"), _("Kyoto"), _("Mie"), _("Miyagi"), _("Miyazaki"), _("Nagano"), _("Nagasaki"), _("Nara"), _("Niigata"), _("Ōita"), _("Okayama"), _("Okinawa"), _("Osaka"), _("Saga"), _("Saitama"), _("Shiga"), _("Shimane"), _("Shizuoka"), _("Tochigi"), _("Tokushima"), _("Tokyo"), _("Tottori"), _("Toyama"), _("Wakayama"), _("Yamagata"), _("Yamaguchi"), _("Yamanashi")] unless const_defined?("JAPAN_STATES")
  MEXICO_STATES=[_("Aguascalientes"), _("Baja California"), _("Baja California Sur"), _("Campeche"), _("Chiapas"), _("Chihuahua"), _("Coahuila"), _("Colima"), _("Distrito Federal"), _("Durango"), _("Guanajuato"), _("Guerrero"), _("Hidalgo"), _("Jalisco"), _("México"), _("Michoacán"), _("Morelos"), _("Nayarit"), _("Nuevo León"), _("Oaxaca"), _("Puebla"), _("Querétaro"), _("Quintana Roo"), _("San Luis Potosí"), _("Sinaloa"), _("Sonora"), _("Tabasco"), _("Tamaulipas"), _("Tlaxcala"), _("Veracruz"), _("Yucatán"), _("Zacatecas")] unless const_defined?("MEXICO_STATES")
  SOUTHAFRICA_STATES=[_("Western Cape"), _("Northern Cape"), _("Eastern Cape"), _("KwaZulu-Natal"), _("Free State"), _("North West"), _("Gauteng"), _("Mpumalanga"), _("Limpopo")] unless const_defined?("SOUTHAFRICA_STATES")
  SPAIN_STATES=[_("Alava"), _("Albacete"), _("Alicante"), _("Almeria"), _("Asturias"), _("Avila"), _("Badajoz"), _("Barcelona"), _("Burgos"), _("Caceres"), _("Cadiz"), _("Cantabria"), _("Castellon"), _("Ceuta"), _("Ciudad Real"), _("Cordoba"), _("Cuenca"), _("Girona"), _("Granada"), _("Guadalajara"), _("Guipuzcoa"), _("Huelva"), _("Huesca"), _("Islas Baleares"), _("Jaen"), _("La Coruna"),_("Leon"), _("Lleida"), _("Lugo"), _("Madrid"), _("Malaga"), _("Melilla"), _("Murcia"), _("Navarra"), _("Ourense"), _("Palencia"), _("Palmas, Las"), _("Pontevedra"), _("Rioja, La"), _("Salamanda"),  _("Santa Cruz de Tenerife"), _("Segovia"), _("Sevilla"), _("Soria"), _("Tarragona"), _("Teruel"), _("Toledo"), _("Valencia"), _("Valladolid"), _("Vizcaya"), _("Zamora"), _("Zaragoza")] unless const_defined?("SPAIN_STATES")
  UGANDA_STATES=[_("Abim"), _("Adjumani"), _("Amolatar"), _("Amuria"), _("Apac"), _("Arua"), _("Budaka"), _("Bugiri"), _("Bukwa"), _("Bulisa"), _("Bundibugyo"), _("Bushenyi"), _("Busia"), _("Busiki"), _("Butaleja"), _("Dokolo"), _("Gulu"), _("Hoima"), _("Ibanda"), _("Iganga"), _("Jinja"), _("Kaabong"), _("Kabale"), _("Kabarole"), _("Kaberamaido"), _("Kabingo"), _("Kalangala"), _("Kaliro"), _("Kampala"), _("Kamuli"), _("Kamwenge"), _("Kanungu"), _("Kapchorwa"), _("Kasese"), _("Katakwi"), _("Kayunga"), _("Kibale"), _("Kiboga"), _("Kilak"), _("Kiruhura"), _("Kisoro"), _("Kitgum"), _("Koboko"), _("Kotido"), _("Kumi"), _("Kyenjojo"), _("Lira"), _("Luwero"), _("Manafwa"), _("Maracha"), _("Masaka"), _("Masindi"), _("Mayuge"), _("Mbale"), _("Mbarara"), _("Mityana"), _("Moroto"), _("Moyo"), _("Mpigi"), _("Mubende"), _("Mukono"), _("Nakapiripirit"), _("Nakaseke"), _("Nakasongola"), _("Nebbi"), _("Ntungamo"), _("Oyam"), _("Pader"), _("Pallisa"), _("Rakai"), _("Rukungiri"), _("Sembabule"), _("Sironko"), _("Soroti"), _("Tororo"), _("Wakiso"), _("Yumbe")] unless const_defined?("UGANDA_STATES")
  US_STATES=[_("Alabama"), _("Alaska"), _("Arizona"), _("Arkansas"), _("California"), _("Colorado"), _("Connecticut"), _("Delaware"), _("Florida"), _("Georgia"), _("Hawaii"), _("Idaho"), _("Illinois"), _("Indiana"), _("Iowa"), _("Kansas"), _("Kentucky"), _("Louisiana"), _("Maine"), _("Maryland"), _("Massachusetts"), _("Michigan"), _("Minnesota"), _("Mississippi"), _("Missouri"), _("Montana"), _("Nebraska"), _("Nevada"), _("New Hampshire"), _("New Jersey"), _("New Mexico"), _("New York"), _("North Carolina"), _("North Dakota"), _("Ohio"), _("Oklahoma"), _("Oregon"), _("Pennsylvania"), _("Puerto Rico"), _("Rhode Island"), _("South Carolina"), _("South Dakota"), _("Tennessee"), _("Texas"), _("Utah"), _("Vermont"), _("Virginia"), _("Washington"), _("Washington D.C."), _("West Virginia"), _("Wisconsin"), _("Wyoming")] unless const_defined?("US_STATES")
  VENEZUELA_STATES=[_("Amazonas"), _("Anzoátegui"), _("Apure"), _("Aragua"), _("Barinas"), _("Bolívar"), _("Carabobo"), _("Cojedes"), _("Delta Amacuro"), _("Distrito Capital"), _("Falcón"), _("Guárico"), _("Lara"), _("Mérida"), _("Miranda"), _("Monagas"), _("Nueva Esparta"), _("Portuguesa"), _("Sucre"), _("Táchira"), _("Trujillo"), _("Vargas"), _("Yaracuy"), _("Zulia")] unless const_defined?("VENEZUELA_STATES")
end

class ActionView::Helpers::InstanceTag
  
  
  def to_state_select_tag(country, options, html_options)
    html_options = html_options.stringify_keys
    add_default_name_and_id(html_options)
    value = value(object)
    selected_value = options.has_key?(:selected) ? options[:selected] : value
    content_tag("select", add_options(state_options_for_select(selected_value, country), options, value), html_options)
  end
end


class ActionView::Helpers::FormBuilder
  def state_select(method, country = 'US', options = {}, html_options = {})
    @template.state_select(@object_name, method, country, options.merge(:object => @object), html_options)
  end
end 

