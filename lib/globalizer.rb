module Globalizer
  include ActionView::Helpers::NumberHelper
  
  # This takes the JSON just before it is handed to the EXT grid and parses the currency for the current locale
  # why? because some countries use different decimal points. 
  # what decimal points where is stored in countries.yml - number_to_currency with magically look there.
  
  CURRENCY_FIELDS = %w[owing_amount total_amount subtotal_amount tax_1_amount tax_2_amount paid_amount discount_amount amount_owing invoice_full_amount amount]

  # todo it should determin which are currency fields itself. I shouldn't have to specify
  def globalize_for_ext(json)
    obj = ActiveSupport::JSON.decode(json)   
      ["invoices", "payments", "customers"].each { |t| obj[t].each {|o| convert_numbers_to_currency(o, CURRENCY_FIELDS)} unless obj[t].blank? }   
      # summaries
      CURRENCY_FIELDS.each {|k| obj["summary"].has_key?(k) ? (obj["summary"][k] = number_to_currency(obj["summary"][k]) unless k=="count(id)") : obj["summary"][k]} unless obj["summary"].blank?
    obj.to_json
  end

  def convert_numbers_to_currency(i, fields)
    fields.each {|k| i.has_key?(k) ? (i[k] = number_to_currency(i[k])) : i[k]}
  end
    
  def remove_commas_and_spaces(value_string)
    delimiter = GettextLocalize::country_options[:currency][:delimiter]
    unless value_string.blank?
      value_string.to_s.delete!(" #{delimiter}")
      value_string.to_s.gsub!(/,/,'.')
    end
  end
  
  def format_date_for_locale(date)
    GettextLocalize::country_options
  end

end