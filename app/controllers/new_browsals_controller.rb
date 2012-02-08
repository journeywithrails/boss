module HandleSignupBrowsal
  def create
    if browsal_type == 'SignupBrowsal'
      @api_token = ApiToken.create(:language => browsal_params['language'], :simply_username => browsal_username)
      set_start_status(browsal_params['start_status'])
      api_token.mode = "simply:#{ @start_status }"
      api_token.language = browsal_params['language']
      api_token.save!
      set_browsal_url
      respond_to do |f|
        f.xml do
          render :action => 'signup/create', :status => :created, :location => browsal_url(api_token, default_url_options(nil))
        end
      end
    else
      super
    end
  end

  def signup
    if browsal_type == 'SignupBrowsal'
      redirect_to signup_url(:service_url => api_thankyou_service_url, :theme => 'simply')
    else
      super
    end
  end

  def login
    if browsal_type == 'SignupBrowsal'
      redirect_to CASClient::Frameworks::Rails::Filter.redirect_url_with_cas_authentication(self, logged_on_api_session_url)
    else
      super
    end
  end
end


module HandleSendInvoiceBrowsal
  def create
    if browsal_type == 'SendInvoiceBrowsal'
      # check if
      #   request has already been initiated?
      #   invoice already exists -- reuse?
      #   invoice already paid / sent?
      #
      # questions
      #   if already logged in, redirect to sign in/up first?
      #     save data or discard?
      #     could keep ref to it in either the token or the session if needed
      @api_token = ApiToken.new(:language => browsal_params['language'], :simply_username => browsal_username)
      set_start_status('send_invoice')
      if create_invoice_data
        api_token.mode = 'simply:send_invoice'
        api_token.language = browsal_params['language']
        api_token.user_gateway = @user_gateway if @user_gateway
        api_token.set_current_user(current_user) if logged_in?
        RAILS_DEFAULT_LOGGER.debug("---------saving api_token")
        set_browsal_url
        api_token.save!
        respond_to do |f|
          f.xml do
            render :action => 'send_invoice/create', :status => :created, :location => browsal_url(@api_token, default_url_options(nil))
          end
        end
      else
        render_errors
      end
    else
      super
    end
  end

  def signup
    RAILS_DEFAULT_LOGGER.debug("send_invoice signup")
    
    if browsal_type == 'SendInvoiceBrowsal'
      session[:return_to] = send_invoice_browsal_url(api_token, default_url_options(nil))
      redirect_to signup_url(:service_url => api_thankyou_service_url, :theme => 'simply')
    else
      super
    end
  end

  def login
    if browsal_type == 'SendInvoiceBrowsal'
      # session[:return_to] = send_invoice_browsal_url(api_token)
      redirect_to CASClient::Frameworks::Rails::Filter.redirect_url_with_cas_authentication(self, send_invoice_api_browsal_url(api_token, default_url_options(nil)))
    else
      super
    end
  end

  def send_invoice
    if browsal_type == 'SendInvoiceBrowsal'
      raise "User mismatch: #{api_token.user.id} != #{current_user.id}" unless (api_token.user.nil? || (api_token.user == current_user))
      api_token.set_current_user(current_user)
      if api_token.new_gateway
        redirect_to switch_to_sps_user_gateways_path
      else
        redirect_to new_delivery_path
      end
    else
      super
    end
  end

  protected

  def validate_invoice_params
    okay = true
    if sr_params[:invoice].nil?
      error_messages[:incompatible_data] << "SendInvoiceBrowsal requires an invoice" 
      okay = false
    else
      if sr_params[:invoice][:customer].nil?
        error_messages[:incompatible_data] << "SendInvoiceBrowsal requires an customer" 
        okay = false
      end
      if sr_params[:invoice][:taxes].size > 2
        error_messages[:incompatible_data] << "Only 2 taxes are supported"
        okay = false
      end    
    end
    okay
  end

  def create_customer
    customer_params = sr_params[:invoice].delete(:customer)
    customer_params[:language] = customer_params[:preferred_language] unless customer_params[:preferred_language].nil?      
    if logged_in?
      @customer = current_user.find_or_build_simply_customer(customer_params)
      @customer.created_by = current_user
    else
      @customer = Customer.build_rejecting_unknown_attributes(customer_params)
    end
    @customer.save(logged_in?) # only validate if logged in
    if @customer.processable?
      yield(@customer)
    else
      error_messages[:customer] = @customer.errors.full_messages unless @customer.errors.empty?
      false
    end
  end

  def create_invoice(customer)
    invoice_type = (sr_params[:invoice].delete(:invoice_type) || "SimplyAccountingInvoice")
    if logged_in?
      @invoice = current_user.invoices.build(:invoice_type => invoice_type)
    else
      @invoice = Invoice.new(:invoice_type => invoice_type)
    end
    @invoice.attributes = @invoice.reject_unknown_attributes(sr_params[:invoice])
    @invoice.invoice_file.validate!
    @invoice.customer = customer
    if @invoice.processable? && customer.processable? && @invoice.save(logged_in?) # only validate if logged in
      api_token.invoice = @invoice
      yield(@invoice)
    else
      error_messages[:invoice] = @invoice.errors.full_messages unless @invoice.errors.empty?
      false
    end
  end

  def create_delivery(invoice)
    if logged_in?
      @delivery = current_user.deliveries.build
    else
      @delivery = Delivery.new
    end
    sr_params[:delivery][:mail_name] ||= 'simply_send'
    sr_params[:delivery][:deliverable] = invoice
    @delivery.attributes = @delivery.reject_unknown_attributes(sr_params[:delivery])    
    if @delivery.save(logged_in?) # only validate if logged in
      api_token.delivery = @delivery
    else
      error_messages[:delivery] = @delivery.errors.full_messages unless @delivery.errors.empty?
    end
    @delivery
  end

  def create_user_gateway
    param = sr_params[:user_gateway]
    if param and param.is_a?(Hash)
      # translate old sage sbs gateway structure to the new one
      if param[:gateway_name] == 'sage_sbs'
        param[:currency] ||= 'USD'
      elsif param[:gateway_name] == 'sage_sbs_cdn'
        param[:gateway_name] = 'sage_sbs'
        param[:currency] = 'CAD'
      end
      if @user_gateway = UserGateway.new_polymorphic(param)
        @user_gateway.user = current_user if logged_in?
        @user_gateway.active = false
        existing_copy = @user_gateway.existing_copy
        if logged_in? and existing_copy
          @user_gateway = existing_copy
        else
          api_token.new_gateway = true
          unless @user_gateway.save(logged_in?) # only validate if logged in
            error_messages[:user_gateway] = @user_gateway.errors.full_messages unless @user_gateway.errors.empty?
          end
          @user_gateway
        end
      end
    end
  end

  def create_invoice_data
    return false unless validate_invoice_params
    create_customer do |customer|
      create_invoice(customer) do |invoice|
        create_delivery(invoice)
        create_user_gateway
        true
      end
    end
  end

  def sr_params
    params[:simply_request]
  end

end

module BrowsalApiPrototype
  def create
    error_messages[:request] = 'Invalid browsal type or request format'
    render_errors
  end

  def update
    # NOTE(dw): I don't see why we need to set either complete or closed. I can't think of
    # what they would do other than log out the user...
    # Answer(mj): Clears the api token so that normal web use of BB will not land on simply themed pages.
    # Answer #2(mj): when the user logs in as a different user than was previously set in Simply, 
    # this is how Simply finds out about it. Though this is less than optimal because it is not
    # very specific, the intent was to save a request, and because changing things in Simply
    # is quite non-agile, must be lived with for the time being. 
    if ['received_complete', 'received_close'].include?(browsal_params[:fire_event])
      @layout_location = api_token.layout_location
      api_token.clear! browsal_params[:fire_event]
      logout_current_user if logged_in?
      set_browsal_url
    else
      error_messages[:request] = 'Invalid event type'
      return render_errors
    end
    respond_to do |f|
      f.xml do
        render :action => "#{ @layout_location }update", :status => :ok, :location => browsal_url(api_token, default_url_options(nil))
      end
    end
  end

  def destroy
    api_token.destroy
    logout_current_user if logged_in?
    render :status => :ok, :nothing => true, :location => browsal_url(api_token, default_url_options(nil))
  end

  def signup
    render :action => 'invalid'
  end

  def login
    render :action => 'invalid'
  end

  def send_invoice
    render :action => 'invalid'
  end

end

class NewBrowsalsController < ApplicationController
  # the order of these filters has to be just right, and they have to run before the localization filters. maybe should combine into one filter to reduce chance of error?
  prepend_before_filter CASClient::Frameworks::Rails::Filter, :only => [:send_invoice]
  prepend_before_filter :require_api_token, :except => [:create] 
  protect_from_forgery :except => [:create]
  helper_method :error_messages
  
  include ApiTokenSupport

  # Calling super in searches up the module list from bottom to top. The search
  # may be continued by calling super inside the method in the module.  The
  # BrowsalApiPrototype is designed to always be at the top of the list so that
  # it can catch and handle calls to super that would result in an exception if
  # they were not handled.
  include BrowsalApiPrototype
  include HandleSignupBrowsal
  include HandleSendInvoiceBrowsal

  # the browsal becomes a sort of token that is passed from the initial api call
  # to the browser.  After that it can be handled by the session though.

  # index and show are now irrelevant

  protected

  # set the start_status. first using any browsal_param[:start_status] unless override is true, or using the requested start_status
  # if the user in the auth_params exists, otherwise starting with signup.
  # we no longer want to use login start_status on send_invoice, because we are using cas filter on send_invoice action,
  # so we ignore the browsal_param[:start_status] here
  def set_start_status(default)
    if user_exists? || (browsal_params['start_status'] == 'login')
      @start_status = default
    else
      @start_status = 'signup'
    end
  end

  def logout_current_user
    session[:sage_user] = nil
    RAILS_DEFAULT_LOGGER.debug("logout_current_user. setting session[:api_token_id] (was #{session[:api_token_id]}) to nil")    
    session[:api_token_id] = nil
    super
  end

  def require_api_token
    RAILS_DEFAULT_LOGGER.debug("require_api_token")    
    if @api_token = ApiToken.find_by_guid(params[:id])
      RAILS_DEFAULT_LOGGER.debug("require_api_token. setting session[:api_token_id] to #{@api_token.id}")
      session[:api_token_id] = @api_token.id
      RAILS_DEFAULT_LOGGER.debug("now session[:api_token]: #{session[:api_token_id].inspect}")      
      true
    else
      RAILS_DEFAULT_LOGGER.debug("found no token")      
      render :nothing => true, :status => :forbidden
      false
    end
  end

  def browsal_params
    if p = params['browsal']
      p
    elsif p = params['simply_request'] # intentional assignment
      p['browsal']
    else
      {}
    end
  end

  def browsal_type
    if @api_token
      @api_token.browsal_type
    else
      browsal_params['browsal_type']
    end
  end

  def browsal_username
    params.deep_value(:simply_request, :user, :login)
  end
  
  def error_messages
    @error_messages ||= Hash.new { |h,k| h[k] = [] }
  end

  def render_errors(status = :unprocessable_entity)
    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
    xml.errors() do
      error_messages.each do |category, errors|
        errors.each do |error|
          xml.error(error, :category => category)
        end
      end
    end
    render :text => xml.target!, :format => :xml, :status => status
  end
  
  def set_browsal_url
    # we need to pass default_url_options so that during testing across multiple machines we can set the host to something other than localhost
    # why the hell the named routes don't call default_url_options is beyond me; I hope that is fixed in a later version of rails.
    options = default_url_options(nil)
    case @start_status.to_s
    when 'signup'
      @url_for_browsal = signup_browsal_url(@api_token, options)
    when 'login'
      @url_for_browsal = login_browsal_url(@api_token, options)
    when 'send_invoice'
      @url_for_browsal = send_invoice_browsal_url(@api_token, options)
    else
      @url_for_browsal = login_browsal_url(@api_token, options)
    end
  end
  
  def user_exists?
    RAILS_DEFAULT_LOGGER.debug("user_exists?")    
    username, passwd = get_auth_data
    RAILS_DEFAULT_LOGGER.debug("got #{username.inspect} from auth_data")
    RAILS_DEFAULT_LOGGER.debug("returning #{username && User.exists?(['sage_username = :username OR email = :username',{:username => username}])}")
    
    username && User.exists?(['sage_username = :username OR email = :username',{:username => username}])
  end

  def get_auth_data
    auth_key  = @@http_auth_headers.detect { |h| request.env.has_key?(h) }
    auth_data = request.env[auth_key].to_s.split unless auth_key.blank?
    return auth_data && auth_data[0] == 'Basic' ? Base64.decode64(auth_data[1]).split(':')[0..1] : [nil, nil] 
  end
  
  def cas_user_prefill
    api_token? ? api_token.simply_username : nil
  end
  
end
