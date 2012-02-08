# Methods added to this helper will be available to all templates in the application.

module ApplicationHelper
  def is_mobile?
    session[:mobile_browser] ? true : false
  end
 
  #wip
  def link_button(options = {})

    btn_str = ""
    btn_str << "<table style='width: 100%'><tr><td align='#{options[:wrap_align]}'>" unless options[:wrap_align].blank?
    btn_str << "<table"
    btn_str << " style='width: #{options[:width]}'" unless options[:width].blank?
    btn_str << ">"
    btn_str << "<tr>"
    btn_str << "<td>"
    btn_str << "<img src='/themes/#{user_theme}/images/buttons/#{options[:style]}/btn-left.gif'>"
    btn_str << "</td>"    
    btn_str << "<td style='text-align: center; background-image: url(/themes/#{user_theme}/images/buttons/#{options[:style]}/btn-center.gif)"
    btn_str << '; width: 100%' unless options[:width].blank?
    btn_str << "'>"
    btn_str << "<p"
    btn_str << " style='#{options[:text_style]}'" unless options[:text_style].blank?
    btn_str << ">"
    btn_str << "<input type='submit' name='commit' value='#{options[:text]}'/>" if (!options[:submit].blank? && (options[:submit] == true))
    btn_str << options[:text] unless (!options[:submit].blank? && (options[:submit] == true))
    btn_str << "</p>"
    btn_str << "</td>"    
    btn_str << "<td>"
    btn_str << "<img src='/themes/#{user_theme}/images/buttons/#{options[:style]}/btn-right.gif'>"    
    btn_str << "</td>"    
    btn_str << "</tr>"
    btn_str << "</table>"
    btn_str << "</td></tr></table>" unless options[:wrap_align].blank?
    btn_str
  end

  def logo_url
    str = ""
    #if !@at_home
    #  str += "style='cursor: pointer;' onclick=location.href='/'"
    #end
    str
  end

  def user_home_path(options={})
    return home_path unless logged_in?
    options[:action] ||= current_user.current_view
    tabs_path(options)
  end
  
  def user_home_url(options={})
    return home_url unless logged_in?
    options[:action] ||= user.current_view
    tabs_url(options)
  end
  
  def secure_login_url(options={})
    if(has_sage_user? && ! has_billingboss_user?)
      signup_for_sagespark_users_url(options)
    else
      options[:protocol] ||= ::AppConfig.use_ssl ? 'https' : 'http'
      login_url(options)
    end
  end

  def link_to_create_invoice title = nil
    css_button_link_to title || _("Create New Invoice"),  {:action=>"new"}, {:id=>"new_invoice", :class=>"button_green"}
  end

  def link_to_create_quote title = nil
    return "" if ::AppConfig.quotes_disabled
    css_button_link_to title || _("Create New Quote"),  {:action=>"new", :is_quote => "1"}, {:id=>"new_quote", :class=>"button_green"}
  end

  def link_to_login(content=nil, link_html_options={})
    content ||= _('Log In')
    link_html_options[:id] ||= 'login-link'
    link_to content, secure_login_url, link_html_options
  end  
  
  def link_to_login_by_user(content, user, link_html_options={})
    link_html_options[:id] ||= 'login-link'
    content = _('Log In') if content.blank?
    user = user.is_a?(User) ? user.sage_username : user
    link_to content, secure_login_url(:sage_username => user), link_html_options
  end
  
  def link_to_login_by_email(content, email, link_html_options={})
    link_html_options[:id] ||= 'login-link'
    content = _('Log In') if content.blank?
    link_to content, secure_login_url(:email => email), link_html_options
  end
  
  def link_to_logout(content=nil, link_html_options={})
    content ||= _('Log Out')
    link_html_options[:id] ||= 'logout-link'
    link_to content, logout_path, link_html_options
  end
  
  def link_to_return_to_my_data(content=nil, link_html_options={})
    content ||= _('Return to my data')
    link_html_options[:id] ||= 'return-to-data-link'
    link_to content, user_home_path, link_html_options
  end
  
  def signup_url_with_sagespark_intercept(url_options={})
    if(has_sage_user? and ! has_billingboss_user?)
      url_for_signup = signup_for_sagespark_users_url(url_options)
    else
      url_for_signup = signup_url(url_options)
    end
  end
  def link_to_signup(content=nil, link_html_options={}, url_options={})
    content ||= _('Sign up')
    link_html_options[:id] ||= 'signup-link'
    link_to content, signup_url_with_sagespark_intercept(url_options), link_html_options
  end
  
  def homepage_user_string
    RAILS_DEFAULT_LOGGER.debug("-----> homepage_user_string")    
    if logged_in?
      RAILS_DEFAULT_LOGGER.debug("   homepage_user_string -- drawing LOGOUT link")      
      link_to_return_to_my_data + content_tag(:span, "|", :class=>"divide") + link_to_logout
    else
      RAILS_DEFAULT_LOGGER.debug("   homepage_user_string -- drawing LOGIN link")
      link_to_login("<span>"+_("Log In")+"</span>")
    end
  end
  
  def user_string_external(home_page = false)
    RAILS_DEFAULT_LOGGER.debug("-----> user_string_external")        
    if logged_in?      
      RAILS_DEFAULT_LOGGER.debug("   user_string_external -- drawing LOGOUT link")      
      str = "<li>" + _("Logged in as %{user} (%{logout_link})") % { :user => current_user.sage_username, :logout_link => link_to_logout} + "</li><li>#{link_to_return_to_my_data}</li>"
    else
      RAILS_DEFAULT_LOGGER.debug("   user_string_external -- drawing LOGIN link")
      str = "<li>#{link_to_login}</li><li>#{link_to_signup}</li>" unless home_page
    end
    str
  end

  def user_string_internal
    RAILS_DEFAULT_LOGGER.debug("-----> user_string_internal")        
    log_out = _("Log out")
    log_out_link = link_to_logout("#{log_out} (#{current_user.sage_username})")
      "<li>#{log_out_link}</li>"
  end
  
  def the_current_user
    if logged_in?
      current_user.sage_username
    else
      ""
    end   
  end
  
  def page_title
    if !@custom_title 
      _("#{controller.controller_name.humanize}") + ': ' + _("#{controller.action_name}")
    else 
      @custom_title 
    end
  end
  
  def invoice_currency(invoice)
    if invoice.new_record?
      current_user.profile.currency
    else
      invoice.currency
    end
  end

  def db_agnostic_id(prefix, obj=nil)
    @db_agnostic_ids ||= Hash.new
    @db_agnostic_ids[prefix] ||= 1
    unless obj.nil?
      if(obj.new_record?)
        out = "#{prefix}_new_#{@db_agnostic_ids[prefix]}"
        @db_agnostic_ids[prefix] += 1
      else
        out = "#{prefix}_#{obj.to_param}"
      end
    end
    out
  end
  
  def db_agnostic_id_js(prefix)
    db_agnostic_id(prefix)
    out = <<EOS
<script type="text/javascript">
  Sage.db_agnostic_ids = Sage.db_agnostic_ids === undefined ? new Hash({}) : Sage.db_agnostic_ids;
  Sage.db_agnostic_ids['#{prefix}'] = #{@db_agnostic_ids[prefix]};
</script>
EOS
  end

  def increment_ajax_counter(need_script_tag=false)
    return "" unless RAILS_ENV == 'test'
    out = ""
    out << "<script type=\"text/javascript\">\n" if need_script_tag
    out << "Sage.increment_ajax_counter();\n"
    out << "</script>\n" if need_script_tag
    out
  end
  
  #FIXME workaround to get acceptance test running
  def toggle_customer
    return "" if RAILS_ENV == 'test'
    'Sage.toggle_customer();'
  end
  
  #FIXME for some reason this is not available in an rjs template ?????
  def increment_ajax_counter_rjs
    return unless RAILS_ENV == 'test'
    page.call 'Sage.increment_ajax_counter'
  end
  
  def send_object_by_mail_link(text, obj, mail_name='send', html_options={})
    delivery = Delivery.new(:deliverable => obj, :mail_name => mail_name)
    if text.nil?
      new_delivery_path(delivery.request_params)
    else
      link_to text, new_delivery_path(delivery.request_params), html_options
    end
  end
  
  # hoisted by my own premature abstracting petard
  def hardcoded_send_invoice_link_for_javascript
    "/deliveries/new?delivery%5Bdeliverable_id%5D={0}&delivery%5Bdeliverable_type%5D=Invoice&delivery%5Bmail_name%5D=send"
  end

  def hardcoded_convert_invoice_link_for_javascript
    "/invoices/{0}/convert_quote"
  end
  
  def send_invoice_path(invoice)
    send_object_by_mail_link(nil, invoice, 'send')
  end

  def deliverable_url(delivery, path_only=true)
    which = path_only ? 'path' : 'url'
    self.send("edit_#{delivery.deliverable.class.underscore}_#{which}", delivery.deliverable)
  end
  
  def field_if_not_blank(record, empty="", &block)
    return empty if record.nil? 
    field = yield
    return empty if field.blank?
    field
  end
  
  def label_if_field_not_blank(record, label="", &block)
    
    return "" if record.nil? 
     
    field = yield
    return "" if field.blank?
   
    return label
  end
  
  def format_amount(amount)
    number_to_currency(amount)
  end

  def protect_form(form_name)
    #the params[:protect] conditione is necessary for acceptance test, but protect_forms will
    #only ever be true in test environment, so this does not impact production at all
    if ::AppConfig.protect_forms || (params[:protect] == "1")
      <<-EOJS
      <script type="text/javascript">
      	Sage.protect_form('#{form_name}', "#{_('You have unsaved changes on this page.\n\n You will lose all unsaved changes if you leave the page!')}");
      </script>
      EOJS
    end
  end
  
  def testable_field(name, text)
    if RAILS_ENV == 'test'
      "<span name=\"#{name}\">#{text}</span>"
    else
      text
    end
  end
  
  def stylesheet_global
    stylesheet_link_tag "/themes/global.css", :media => 'screen, print'  
  end
  
  def stylesheet_ie6
    %|
      <!--[if IE 6]>
        <link href="/themes/#{user_style}/ie6.css" media="screen, print" rel="stylesheet" type="text/css" />
      <![endif]-->
    |
  end
  
  def stylesheet_theme
    stylesheet_link_tag "/themes/#{user_style}/shared.css", :media => 'screen, print'     
  end

  #return a css file name for the current controller
  #if custom is not supplied, use the controller name as the name of the css
  #if custom is present, use custom.css
  def stylesheet_theme_controller(custom=nil)
    if (custom != nil) or (!controller.blank?)
      stylesheet_link_tag "/themes/#{user_style}/#{(custom)||(controller_name_for_theme)}.css", :media => 'screen, print'        
    end
  end
  
  def stylesheet_theme_controller_printable(print = false, the_controller = nil)
    if ((the_controller != nil) or (!controller.blank?)) && @printable
      if print
        stylesheet_link_tag("/themes/#{user_style}/#{the_controller||controller_name_for_theme}_print.css", :media => 'screen, print')
      else
        stylesheet_link_tag("/themes/#{user_style}/#{the_controller||controller_name_for_theme}_print.css", :media => 'print')
      end
    end
  end
  
  def default_theme
    stylesheet_link_tag "/themes/default/shared.css", :media => 'screen, print'     
  end
  
  def default_theme_controller(custom=nil)
    if (custom != nil) or (!controller.blank?)
      stylesheet_link_tag "/themes/default/#{(custom)||(controller_name_for_theme)}.css", :media => 'screen, print'        
    end
  end
  
  def default_theme_controller_printable(print = false)
    if !controller.blank? && @printable
      if print
        stylesheet_link_tag "/themes/default/#{controller_name_for_theme}_print.css", :media => 'screen, print'
      else
        stylesheet_link_tag "/themes/default/#{controller_name_for_theme}_print.css", :media => 'print'
      end
    end
  end
  
  def user_theme
    if logged_in? && !current_user.profile.blank? && !current_user.profile.theme.blank?
      "#{current_user.profile.theme}"       
    else
      "Default"       
    end    
  end
  
  def user_style
    theme = Theme.load_theme(user_theme)
    return theme.style_path
  end
  
  def xpath_theme
    theme = Theme.load_theme(user_theme)
    stylesheet_link_tag "/ext/resources/css/xtheme-#{theme.ext_path}.css" unless theme.ext_path.blank?
  end

  def hidden_content_tag(name, options = {}, &block)
    unless options.delete(:show_if)
      options[:style] = "display: none; #{ options[:style] }"
    end
    content_tag_block(name, options, &block)
  end

  def content_tag_block(tag_name, options = {}, &block)
    concat(content_tag(tag_name, capture(&block), options), block.binding)
  end

  def hidden_div(options = {}, &block)
    hidden_content_tag(:div, options, &block)
  end
  
  def current_signup_type
    if !session[:signup_type].blank? and User.SignupTypes.include?(session[:signup_type])
      return session[:signup_type]
    else
      return "soho"
    end
  end
  
  def taf_header_text 
    sample_email_string = _("View sample e-mail")
    
    if current_signup_type == "rac" || current_signup_type == "ssan"
      text = ""
      text << "<span id='ssan_text'>"
      text << _("Send your clients an email to tell them about Billing Boss.")
      text << "  "
      text << "<a href='/themes/default/images/r_soho.gif' target='_new'>#{sample_email_string}</a>"
      text << "<br/><br/>"
      text << _("Don't worry, your customers' e-mail addresses will only be used to tell them about Billing Boss and not for any other purpose.")
      text << "</span>"
      return text
    else
      text = ""
      text << "<span id='soho_text'>"
      text << _("Send your friends an email to tell them about Billing Boss.")
      text << "  "
      text << "<a href='/themes/default/images/r_soho.gif' target='_new'>#{sample_email_string}</a>"
      text << "<br/><br/>"
      text << _("Don't worry, your friends' e-mail addresses will only be used to tell them about Billing Boss and not for any other purpose.")
      text << "</span>"
      return text
    end
  end

  def menu_builder(page_id)
    current_view = current_user.current_view  
    view_factory(current_view) << tab_factory(page_id, current_view) 
  end

  def tab_factory(page_id, current_view)
    case current_view  
    when :admin   
      # admin_tabs are the tabs shown for a admin user        
      tabs = [[_("Overview"), "admin/overview/"]]
      AdminManager.admin_roles_for(current_user, true).each do |a|  
        tabs << [a.humanize, "admin/#{a}/"]
      end
    when :bookkeeper  
      # bookkeeper_tabs are the tabs shown for a bookkeeper user        
      tabs = [ 
              [_("Reports"), "bookkeeping_clients"] #,
              #["Reports", "reports"]
            ]
    else # biller  
      # first element is the actual text used for the tab and second is the link to the page  
      # biller_tabs are the tabs shown for a normal user
      tabs = []
      tabs << [_("Invoices & Quotes"),"invoices/overview"]
      tabs << [_("Recurring invoices"),"invoices/recurring"]
      tabs << [_("Customers"),"customers/overview"]
      tabs << [_("Reports"), "reports"]
      tabs << [_("Share Data"),"bookkeepers"] if current_user.bookkeeper.nil?
      tabs << [_("Settings"),"profiles"]
    end           
  
  
    # one empty list item to provide a left margin
    content = ""
    tabs.each do |each_tab |
      css_a_class = ((page_id == each_tab[0]) ? 'menu-tab-selected' : 'inactive')
      css_class = ((page_id == each_tab[0]) ? 'menu-li-selected' : 'inactive')
      content <<  content_tag('li',
        content_tag('a',  each_tab[0], 
        :href => "/#{each_tab[1]}",
        :class => css_a_class), 
        :class => css_class) + " "
    end
    content_tag(:ul, content, :id => 'maintab')
  end

  def view_factory(current_view)

    hash_links = ActiveSupport::OrderedHash.new
    hash_links[:admin] = {
              "current" => _("My Admin View"),
              "inactive" => _("Switch to My Admin View"),
              "path" => "tabs/admin"
              } if current_user.is_admin?
    hash_links[:biller] = { 
              "current" => _("My Billing View"),
              "inactive" => _("Switch to My Billing View"),
              "path" => "tabs/biller"
              }
    hash_links[:bookkeeper] = { 
              "current" => _("My Clients View"),
              "inactive" => _("Switch to My Clients View"),
              "path" => "tabs/bookkeeper"
              } unless current_user.bookkeeper.nil?
  
    if hash_links.length == 1 
      return ""
    end
  
    content = "<ul>"
    hash_links.each do | key, value |
      if key == current_view
        content << content_tag('li', content_tag('span', value["current"] ), :class => 'current') + " "
      else
        content << content_tag('li', content_tag('a', "<span>" + value["inactive"] + "</span>", :href => "/#{value["path"]}" ), :class => 'inactive') + " "
      end
    end
    content += "</ul>"
    content_tag(:div, content, :id => 'view_links')

  end

  def formatted_flash_now(add_css=nil, always=false)
    formatted_flash(add_css, always)
    flash[:notice] = nil
    flash[:warning] = nil
  end

  def formatted_flash_always(add_css=nil)
    formatted_flash(add_css=nil, true)
  end

  def formatted_flash(add_css=nil, always=false)
    msg = ''
    if flash[:warning] 
      msg = flash[:warning]
      css_class = 'warning flash-warning'
    elsif flash[:notice]
      msg = flash[:notice]
      css_class = 'notice flash-notice'
    else
      unless always
        return "&nbsp;"
      else
        css_class="empty"
      end
    end
    css_class += (add_css.blank? ? "" : " #{add_css}")
    msg = (msg.blank? ? '&nbsp;' : "<div id=\"flash_message\">#{msg}</div>")
    final_string = "<div id=\"flash\" class=\"#{css_class}\">#{msg}</div>"

  end

  def secure_form_tag(url_for_options = {}, options = {}, *parameters_for_url, &block)
    if use_secure_forms?
      url_for_options[:protocol] = 'https'
      url_for_options[:only_path] = false
    end
    form_tag(url_for_options, options, *parameters_for_url, &block)
  end

  def secure_form_for(record_or_name_or_array, *args, &proc)
    if use_secure_forms?
      options = args.extract_options!
    
      raise "to use secure_form_for, :url must be specified as an url_for hash" unless options[:url] and options[:url].is_a?(Hash)

      options[:url][:protocol] = 'https'
      options[:url][:only_path] = false
      args << options
    end
    form_for(record_or_name_or_array, *args, &proc)
  end

  def use_secure_forms?
    # %w{production staging load_testing}.include?(ENV["RAILS_ENV"])
    ::AppConfig.use_ssl
  end

  def bottom_corners
    out = <<-EOQ    
  <!-- BOTTOM CORNERS -->
  <div class="corner_large_bl">
  	<div class="corner_large_br">
  		<div>
  			&nbsp;
  		</div>
  	</div>
  </div>
  EOQ
    out
  end

  def short_company_title
      return current_user.profile.company_name unless current_user.profile.company_name.blank?
      return current_user.profile.contact_name unless current_user.profile.contact_name.blank?
      return current_user.sage_username
  end

  def user_heard_from
    options = ""
    User.HeardFrom.each do |item|
      options += "<option value='#{item}'>#{item.titleize}</option>"
    end
    options
  end

  #a generic mechanism for highlighting a mandatory field
  #can be customized for a particular purpose, e.g. a mandatory invoiec field
  #can work and look differently than a mandatory profile field
  def mandatory(obj=nil, parameter=nil)
    if obj.nil?
      str = "<span class='mandatory'> *</span>"
      str = "" if !parameter.blank?
      return str
    elsif (obj.class.to_s == "Profile")
      str = "<span class='mandatory'> *</span>"
      str = "" if obj.is_complete? || !parameter.blank?
      return str
    end
  end

  def css_button_link_to( source, options = {} ,  html_options = nil)
    return link_to("<span>"+source+"</span>", options, html_options)
  end

  #Return an image submit tag 
  def css_button_image_submit_tag(source, options = {})
      return tag(:input, { :type => 'image', :alt => options[:alt] })
  end

  def error_message_to_xml(message)
    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
    xml.errors() do
      xml.error(message)
    end
  end

  def render_inner_layout(type='')
    type ="_#{type}" unless type.blank?
    active_layout_parts = active_layout.split('/')
    active_layout_parts.pop
    render active_layout_parts.push("inner#{type}").join('/')
  end

  def render_inner_mobile_layout(type='')
    type ="_#{type}" unless type.blank?
    active_layout_parts = active_layout.split('/')
    active_layout_parts.pop
    render active_layout_parts.push("inner_mobile#{type}").join('/')  
  end

  def format_date(format_string, &block)
    
    date = yield
    return "" if date.blank?
    
    return date.strftime(format_string)
  end

  def sagespark_ads
    # format is
    # ad name => ["image path", "href links"]
    {
      "regular" =>
      {
       "knownlocally" =>  ["/themes/default/images/kl-160x350.gif", "http://www.sagespark.com/tools-services/marketing-and-sales/build-a-business-website&WT.mc_id=BB_KL"],
       "merchant_services" => ["/themes/default/images/payment-solutions.gif", "http://www.sagespark.com/tools-services/merchant-services/receiving-payments&WT.mc_id=BB_MS"],
       "live_computer_support" => ["/themes/default/images/LCS.gif", "http://www.sagespark.com/tools_services/it_services/it_services/live_computer_support&WT.mc_id=BB_LCS"]
      },
      
      "simply" =>
        {
       "knownlocally" =>  ["/themes/default/images/kl-160x350.gif", "http://www.sagespark.com/tools-services/marketing-and-sales/build-a-business-website&WT.mc_id=BB_SIMPLY_KL"],
       "merchant_services" => ["/themes/default/images/payment-solutions.gif", "http://www.sagespark.com/tools-services/merchant-services/receiving-payments&WT.mc_id=BB_SIMPLY_MS"],
       "live_computer_support" => ["/themes/default/images/LCS.gif", "http://www.sagespark.com/tools_services/it_services/it_services/live_computer_support&WT.mc_id=BB_SIMPLYLCS"]
      }
    }
  end

  #group_name is the name of the ad group to display, see sagespark_ads
  #currently, either regular or simply
  def pick_sagespark_ad(group_name="regular")
    ad_group = sagespark_ads[group_name]
    ad_display = ad_group.values[rand(ad_group.values.size)]
    ad_display
  end
end

module ActionView
  module Helpers
    module ActiveRecordHelper      
      def error_messages_for(*params)
        options = params.extract_options!.symbolize_keys
        if object = options.delete(:object)
          objects = [object].flatten
        else
          objects = params.collect {|object_name| instance_variable_get("@#{object_name}") }.compact
        end
        count   = objects.inject(0) {|sum, object| sum + object.errors.count }
        unless count.zero?
          if options[:partial] 
            render :partial => options[:partial], :locals => {:errors => error_messages} 
          else 
            html = {}
            [:id, :class].each do |key|
              if options.include?(key)
                value = options[key]
                html[key] = value unless value.blank?
              else
                html[key] = 'errorExplanation'
              end
            end
            if html[:class] == "errorExplanation" and request.xhr?
              html[:class] = "ExtError"
            end
            options[:object_name] ||= params.first
            unless options.include?(:header_message)
              if count > 1
                options[:header_message] = _("%{num} errors prohibited this %{rec_name} from being saved") % {:num => count, :rec_name => "#{options[:object_name].to_s.gsub('_', ' ')}"} 
              else
                options[:header_message] = _("%{num} error prohibited this %{rec_name} from being saved") % {:num => count, :rec_name => "#{options[:object_name].to_s.gsub('_', ' ')}"}
              end
            end
            error_messages = objects.sum {|object| object.errors.full_messages.map {|msg| content_tag(:li, msg) } }.join
            contents = ''
            contents << content_tag(options[:header_tag] || :h2, options[:header_message]) unless options[:header_message].blank?
            contents << content_tag(:ul, error_messages)

            content_tag(:div, contents, html)
          end
        else
          ''
        end
      end #def error_messages_for 
    end
  end
end
