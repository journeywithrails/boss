module LocalizationHelper

  # http://en.wikipedia.org/wiki/ISO_639-1 codes localized into the users language
  # not all of these are supported, but they are the likely candidates
  # define them here; enabled in available_languages in application.yml
  def known_languages
    [['af', 'Afrikaans', s_('iso_639-1 af|Afrikaans') ],
    ['ar', 'العربية', s_('iso_639-1 ar|Arabic') ],
    ['bn', 'বাংলা', s_('iso_639-1 bn|Bengali') ],
    ['cs', 'Česky', s_('iso_639-1 cs|Czech') ],
    ['da', 'Dansk', s_('iso_639-1 da|Danish') ],
    ['de', 'Deutsch', s_('iso_639-1 de|German') ],
    ['el', 'Ελληνικά', s_('iso_639-1 el|Greek') ],
    ['en', 'English', s_('iso_639-1 en|English') ],
    ['es', 'Español', s_('iso_639-1 es|Spanish') ],
    ['fi', 'Suomi', s_('iso_639-1 fi|Finnish') ],
    ['fr', 'Français', s_('iso_639-1 fr|French') ],
    ['gu', 'ગુજરાતી', s_('iso_639-1 gu|Gujarati') ],
    ['he', 'עברית', s_('iso_639-1 he|Hebrew') ],
    ['hi', 'हिन्दी', s_('iso_639-1 hi|Hindi') ],
    ['it', 'Italiano', s_('iso_639-1 it|Italian') ],
    ['ja', '日本語', s_('iso_639-1 ja|Japanese') ],
    ['jv', 'basa Jawa', s_('iso_639-1 jv|Javanese') ],
    ['ko', '한국어', s_('iso_639-1 ko|Korean') ],
    ['mr', 'मराठी', s_('iso_639-1 mr|Marathi') ],
    ['ms', 'بهاس ملايو‎', s_('iso_639-1 ms|Malay') ],
    ['nl', 'Nederlands', s_('iso_639-1 nl|Dutch') ],
    ['pa_PK', 'پنجابی', s_('iso_639-1 pa_PK|Punjabi (Pakistan)') ],
    ['pa_IN', 'ਪੰਜਾਬੀ', s_('iso_639-1 pa_IN|Punjabi (India)') ],
    ['pl', 'Polski', s_('iso_639-1 pl|Polish') ],
    ['pt', 'Português', s_('iso_639-1 pt|Portuguese') ],
    ['pt_BR', 'Português (Brasil)', s_('iso_639-1 pt_BR|Portuguese (Brazil)') ],
    ['ru', 'Русский', s_('iso_639-1 ru|Russian') ],
    ['sd', 'सिन्धी; سنڌي، سندھی‎', s_('iso_639-1 sd|Sindhi') ],
    ['sv', 'Svenska', s_('iso_639-1 sv|Swedish') ],
    ['ta', 'தமிழ்', s_('iso_639-1 ta|Tamil') ],
    ['te', 'తెలుగు', s_('iso_639-1 te|Telugu') ],
    ['tr', 'Türk', s_('iso_639-1 tr|Turkish') ],
    ['ur', 'اردو', s_('iso_639-1 ur|Urdu') ],
    ['zh_CN', '中文', s_('iso_639-1 zh_CN|Chinese (China)') ],
    ['zh_HK', '粵語 香港', s_('iso_639-1 zh_HK|Chinese (Hong Kong)') ],
    ['zh_TW', '國語 台灣', s_('iso_639-1 zh_TW|Chinese (Taiwan)') ] ]
  end


  # return the supported languages as defined in application.yml
  # which is where a specific language should be enabled
  # Warning - this is bypassed in lib/localizer.rb
  def available_languages
    AppConfig.available_languages
  end

  # Warning - this is bypassed in lib/localizer.rb
  def default_locale
    AppConfig.default_locale
  end

  def default_language
    AppConfig.default_language
  end

  def humanize_language( iso639 )
    begin
      known_languages.find{ |x,y,z| x == iso639 }[1]
    rescue Exception => e
      _('Unknown language')
    end
  end
  
  def human_language_link( iso639 )
    link_to humanize_language( iso639 ), :controller => 'languages', :action => 'show', :id => iso639
  end
  
  # find the localized name of the language represented by the 2-letter 
  # iso-639 code ("en" yields "English" or its equivalent in the active language)
  # also works with locales such as zh_CN
  def localize_language( iso639 )
    begin
      known_languages.find{ |x,y,z| x == iso639 }[2]
    rescue Exception => e
      _('Unknown language')
    end
  end
  
  # appropriate for selecting a language for someone else from a list
  # sorted alphabetically by local language
  def select_languages_localized
    available_languages.map{ |x| known_languages.assoc(x)}.map{ |y| [y[2],y[0]]}.sort!
  end

  # appropriate for letting a user find her own language in a list
  # ordered by iso 639-1 code
  def select_languages_native
    available_languages.map{ |x| known_languages.assoc(x)}.map{ |y| [y[1],y[0]]}.sort!
  end
  
  def localized_country(country_code)
    full_country_name = ""
    ActionView::Helpers::FormOptionsHelper::COUNTRIES.map {|c| c.include?(country_code) ? full_country_name = c.first : false}
    return full_country_name
  end
  
  def tz(time_at)
    TzTime.zone.utc_to_local(time_at.utc)
  end
  
  def customer_language(customer)
    if !customer.language.blank?
      customer.language
    elsif !cookies["lang"].nil?
      cookies["lang"] # shouldn't we be using locale.language ?
    else
      default_language
    end
  end
  
  def default_locale?
    return  !GettextLocalize.locale || (GettextLocalize.locale.to_s == ::AppConfig.default_locale)
  end

  # return the filename for an image file, localized or for a language if possible.
  def localized_image_filename (source)
    localized_filename = get_language_filename( source, true )
    language_filename = get_language_filename( source, false )
    if language_image_exists?(localized_filename)
      return localized_filename
    elsif language_image_exists?(language_filename)
      return language_filename
    else
      return source
    end
  end

  # append the language or locale code to the filename (before the extension)
  # in the format filename-pt.gif or filename-pt_BR.gif as specified by "locale"
  def get_language_filename( source, use_locale = false )
    before_substring = source.slice(0,(source.rindex(".") ))
    after_substring = source.slice(source.rindex("."), (source.size - before_substring.size) )
    if use_locale
      return "#{before_substring}-#{GettextLocalize.locale.to_s}#{after_substring}"
    else
      return "#{before_substring}-#{GettextLocalize.locale.to_s[0,2]}#{after_substring}"
    end
  end


  # Does the specified image file exist?
  def language_image_exists?( filename )
    return ((!filename.blank?) and FileTest.exists?("#{RAILS_ROOT}/public/#{filename}"))
  end

  #produce either an image_tag or an image_submit_tag with a localized image name
  def get_localized_image_tag( source, options = {}, submit = true )
    # two options: either the language (es) or locale (pt_BR) may have an image
    localized_filename = get_language_filename( source, true )
    language_filename = get_language_filename( source, false )

    # try locale override first, then use the default for language
    chosen_string = ""
    if language_image_exists?(localized_filename)
      chosen_string = localized_filename
    elsif language_image_exists?(language_filename)
      chosen_string = language_filename
    else
      return chosen_string
    end
    if submit
      return image_submit_tag( chosen_string, options)
    else
      return image_tag( chosen_string, options)
    end
  end

  #Return an image submit tag with the image name localized if applicable
  def localized_image_submit_tag(source, options = {})

    return image_submit_tag(source, options) if default_locale?
    image_tag = get_localized_image_tag( source, options, true )
    if !image_tag.blank?
      return image_tag
    else
      # fallback on text
      if options[:altclass]
        return tag(:input, { :type => 'image', :alt => options[:alt], :class => options[:altclass] })
      else
        return tag(:input, { :type => 'image', :alt => options[:alt] })
      end
    end
  end

  #Return an image tag with the image name localized if applicable
  def localized_image_tag(source, options = {})

    return image_tag(source, options) if default_locale?
    image_tag = get_localized_image_tag( source, options, false )
    if !image_tag.blank?
      return image_tag
    else
      # fallback on text
      if options[:altclass]
        return "<span class='#{options[:altclass]}'>" + options[:alt] + "</span>"
      else
        return options[:alt]
      end
    end
  end

  def locale_comment
    "<!-- Locale: #{GettextLocalize.locale.to_s} -->"
  end
end