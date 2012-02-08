require 'builder'

class InvoicesController < ApplicationController

  # This gets included in the Deliveries controller so that the invoice pdf can be rendered from
  # within the mailer to be attached. I've included it here so we don't forget to update it if
  # the invoices/show action changes!
  module RenderPdf
    def render_invoice_pdf(invoice)
      print_on!
      @invoice = invoice
      @controller_name_for_theme = 'invoices'
      @print = true
      @show_lnav = false
      @printable = true
      @profile = invoice.created_by.profile
      # NOTE: for some reason the instance variables are not being put in the assigns hash
      # in the as part of the render for princely. Workaround:
      add_instance_variables_to_assigns
      #render_to_string :template => 'invoices/show'
       render_to_string :pdf => invoice.pdf_name + '.pdf',
         :prince_options => {:network => true},
         :use_pdf_cache => false,
         :layout => 'main',
         :template => 'invoices/show'
    ensure
      print_off!
    end
  end

  # NOTE: ApiTokenSupport may not be needed if send_invoice_preview and
  #       send_invoice are not actually used. (dw 2009-01-31)
  include ApiTokenSupport 
  include FilterWithInvoice
  require 'ostruct'
  prepend_before_filter CASClient::Frameworks::Rails::Filter, :except => [:display_invoice, :create_through_simply]
  prepend_before_filter CASClient::Frameworks::Rails::GatewayFilter, :only => [:display_invoice, :create_through_simply]

  before_filter :find_parent
  before_filter :set_up
  before_filter :biller_view, :except => [:display_invoice] 
  before_filter :filter_with_invoice, :only => [:display_invoice] 
  skip_before_filter :init_gettext, :only => [:display_invoice]

  helper_method :access_key


  def recurring
    @invoices = current_user.invoices.find_all_by_status "recurring"
  end

  def generated
    find_invoice
    @invoices = @invoice.generated_invoices
  end
  
  #used in test and development mode only
  def index
    split_multi_params(params[:filters], :customers, :statuses)
    respond_to do |format|
      format.html do
        if %w{test development}.include?(ENV['RAILS_ENV'])
          setup_search_filters(@filter_name, :page_size => ::AppConfig.pagination.invoices.page_size)
          @invoices = Invoice.filtered_invoices(@parent.invoices, @filters)
        else
          split_multi_params(params[:filters], :customers, :statuses, :fromdate, :todate)
          setup_search_filters(@filter_name, :page_size => ::AppConfig.pagination.invoices.page_size)
          render :template => "invoices/overview"
        end
        
      end
      format.csv do
       
        setup_search_filters(:invoices, :page_size => nil)
        @invoices, @summary = Invoice.filtered_invoices(@parent.invoices, @filters, true)
        stream_csv do |csv|
          csv << [_("Invoice #"), _("Customer"), _("Date"), _("Total"), _("Amount Owing")]
          acc_total = 0;
          acc_owing = 0;
          @invoices.each do |i|
            csv << [i.unique, i.customer_name, i.date, i.total_amount, i.amount_owing]
            acc_total += i.total_amount;
            acc_owing += i.amount_owing;            
          end
          csv << [_("Grand totals:"), "", "", "", @summary['total_amount'], @summary['amount_owing']]
        end
      end
      format.xml  { render :xml => @invoices.to_xml }
    end
  end

  # GET /invoices/1
  # GET /invoices/1.xml
  def show
    @show_simply_back_button = true
    @printable = true
    @selected_template = params[:template]
    find_invoice
    @profile = current_user.profile
    @secondary_header = _("Recorded payments for this invoice:")
    @access_key = @invoice.get_or_create_access_key 
    @history_header = _("History:")
    @access_header = _("People who have access to this invoice:")
    @activities = @invoice.activities
    @all_payment_types = @invoice.all_payment_types
    
    respond_to do |format|
      format.html do# show.rhtml
        if (@invoice.is_a?(SimplyAccountingInvoice))
          render :action => "simply/show"
        else
          if (@selected_template != @invoice.template_name && !@selected_template.nil?)
            @invoice.template_name = @selected_template
            @invoice.save!
            #remember this template for use next time when a new invoice is created
            current_user.profile.last_invoice_template = @selected_template
            current_user.profile.save!
          end
          
          render_with_mobile_support(:mobile_layout => 'mobile', :action => "show")
        end
      end
      format.pdf do
        @invoice.print!
        print_on!
        RAILS_DEFAULT_LOGGER.debug("@invoice.pdf_cache_path: #{@invoice.pdf_cache_path.inspect}")
        
        render :pdf => @invoice.pdf_name, :layout => 'main',
               :pdf_data => @invoice.cached_pdf,
               :prince_options => {:network => true},
               :cache_path => @invoice.pdf_cache_path # , :cache_stale_date => Time.now
      end
      format.xml  { render :xml => @invoice.to_xml }
    end
  end

  # NOTE: I'm not sure if the simply_users actually hit this action, I think
  #       it's just rendered from the deliveries controller (dw 2009-01-31)
  def send_invoice_preview
    find_invoice
    if api_token? and @invoice and @invoice.is_a? SimplyAccountingInvoice
      render :action => 'simply/send_invoice_preview'
    else
       raise Exception, _("Missing or incompatible invoice for this action")
    end
  end

  # NOTE: I'm not sure if the simply_users actually hit this action, I think
  #       it's just rendered from the deliveries controller (dw 2009-01-31)
  def send_invoice
    find_invoice
    #TODO: Get correct e-mail address from browsal, or default contact?
    @delivery = @parent.deliveries.build({"mail_options"=>{:attach_pdf=>"on"}, "recipients"=> 'info@billingboss.com', "mail_name"=>"send", "deliverable_type"=>"Invoice", "deliverable_id"=>@invoice.id})
    @delivery.setup_mail_options
    ok = @delivery.deliver!(self)
    if api_token?
      render :action => 'simply/invoice_sent'
    end
  end
  
  def display_invoice
    layout_for_invoice_recipient
    #load the company's profile for displaying company address, logo etc...
    @profile = @invoice.profile
    respond_to do |format|
      @custom_title  = _("Invoice %{num}") % { :num => @invoice.unique_number.to_s }
      format.html do
        if (@invoice.type.to_s == "SimplyAccountingInvoice")
          render :action => "display_invoice_simply"
        else
          ak = AccessKey.find_by_key @key
          Activity.log_view!(@invoice.id, request.remote_ip) unless (@invoice.created_by == current_user) || ak.not_tracked
          render_with_mobile_support(:mobile_layout => 'mobile', :action => "display_invoice")
        end
      end
      format.xml  { render :xml => @invoice.to_xml }
      format.pdf do
        render  :pdf => @invoice.pdf_name, :layout => internal_layout,
                :prince_options => {:network => true},
                :cache_path => @invoice.pdf_cache_path # , :cache_stale_date => Time.now
      end
    end
  end

  # GET /invoices/new
  # Create anonymous object and redirect to edit method
  def new  
    @invoice = @parent.invoices.build
    if params[:customer]
      @the_customer ||= current_user.customers.find(:first, :conditions => {:id => params[:customer]})
    end    
    @the_customer ||= @invoice.customer
    @invoice.status = "quote_draft" if params[:is_quote] == "1"
    @invoice.prepare_default_fields
    @invoice.date =  Date::new(TzTime.now.year, TzTime.now.month, TzTime.now.day)
    @invoice.setup_taxes
    @profile = current_user.profile		
    
    if @profile
      @invoice.description = @invoice.quote? ?
        @profile.default_comment_for_quote : @profile.default_comment_for_invoice
    end

    render_mobile(:mobile_layout => "mobile")
  end

  # GET /invoices/1;edit
  def edit
    find_invoice
    @the_customer ||= @invoice.customer
    if @invoice[:type] == "SimplyAccountingInvoice"
      redirect_to "/"
      return
    end
    @invoice.setup_taxes
    @invoice.calculate_discounted_total
    render_mobile(:mobile_layout => "mobile")
  end

  # POST /invoices
  # POST /invoices.xml
  def create

    # we must use two steps so that the current_user is propagated to any on-the-fly customer.created_by
    sanitize_params
    
    is_quote = params[:is_quote] == "1"
    @invoice = Invoice.build_from_parent_and_params(@parent, params[:invoice], is_quote)
    if (!current_user.profile.last_invoice_template.nil?)
      @invoice.template_name = current_user.profile.last_invoice_template
    end
    @the_customer ||= @invoice.customer
    @profile = current_user.profile
    available = confirm_unique_availability
    if available == true
      begin
        respond_to do |format|
          @invoice.save!
          @invoice.created_by.save! #RADAR necessary to save user through invoice so that the profile attributes get saved
          @invoice.prune_empty_ending_line_items(true) # sending true to reload line_items after pruning, or save will fail
          if params[:is_quote] == "1" then @invoice.save_quote! else @invoice.save_draft! end
          Activity.log_create!(@invoice, current_user)
          flash[:notice] = InvoicesHelper.i_(@invoice,'Invoice was successfully created.')
  
          format.html { redirect_to invoice_url(@invoice) }
          format.xml  { head :created, :location => invoice_url(@invoice) }
        end
      rescue => e
        RAILS_DEFAULT_LOGGER.warn("invoices_controller.rb - 88: #{e.message}")
      
        RAILS_DEFAULT_LOGGER.warn("invoices_controller.rb - 89: \n\n TRACE \n\n#{e.backtrace.join("\n")}\n\n")
        respond_to do |format|      		
          format.html { render_with_mobile_support(:mobile_layout => 'mobile', :action => "new")  }
          format.xml  { render :xml => @invoice.errors.to_xml }
          end
      end
    else
        respond_to do |format|
          #can't use invoice.save_quote, so we need to set stateus manually
          @invoice.status = "quote_draft" if params[:id] == "quote"
          @invoice.wanted_auto = @invoice.unique.to_i
          @invoice.available_auto = available.to_i          
          
          format.html { render_with_mobile_support(:mobile_layout => 'mobile', :action => "new") }
          format.xml  { render :xml => @invoice.errors.to_xml }
          end      
    end
  end

  def update_payment_methods
    # The data doesn't really need to be checked because before it is used it
    # always needs to be validated against the current gateway availability and
    # bad entries are just ignored.
    find_invoice
    param = params['invoice'] || {}
    @invoice.payment_types = param['payment_types']
    @invoice.save
    redirect_to invoice_url(@invoice)
  end

  # PUT /invoices/1
  # PUT /invoices/1.xml
  def update
    sanitize_params
    find_invoice

    raise ActionController::NotImplemented, "Can't edit recurring invoices" if @invoice.recurring?

    #TODO: make this controller shorter
#    if params[:invoice][:schedule]
#      if params[:invoice][:schedule][:frequency] != ""
#        if @recurring = Invoice.create_recurring_from(@invoice, params[:invoice])
#          flash[:notice] = "Recurring invoice was created successfully"
#          redirect_to invoice_url(@recurring) and return
#        else
#          flash[:notice] = "Couldn't create a recurring invoice"
#          redirect_to invoice_url(@invoice) and return
#        end
#      end
#      redirect_to invoice_url(@invoice) and return
#    end
#    params[:invoice].delete(:schedule)

    if @invoice.type.to_s == "SimplyAccountingInvoice"
      redirect_to "/"
      return
    end

    if  !@invoice.meta_status == Invoice::META_STATUS_DRAFT or ! @invoice.status == "quote_draft"
      raise Exception, "Unique value cannot be edited for non-draft invoice" if (params[:invoice][:unique] and (params[:invoice][:unique] != @invoice.unique.to_s))
    end



    respond_to do |format|
      @invoice.will_edit_taxes(params[:invoice])
      if @invoice.update_attributes(params[:invoice]) #TODO: does this need to be wrapped in a transaction?

        @the_customer ||= @invoice.customer
        puts "update_attributes was successful" if $log_on
        @invoice.created_by.save! #RADAR necessary to save user through invoice so that the profile attributes get saved
        @invoice.prune_empty_ending_line_items(true)
        
        @invoice.save_change!
        
        flash[:notice] = InvoicesHelper.i_(@invoice,'Invoice was successfully updated.')
        format.html { redirect_to invoice_url(@invoice) }
        format.xml  { head :ok }
      else
        puts "update_attributes failed" if $log_on
        format.html { render_with_mobile_support(:mobile_layout => 'mobile', :action => "edit") }
        format.xml  { render :xml => @invoice.errors.to_xml }
      end
    end
  end

  # DELETE /invoices/1
  # DELETE /invoices/1.xml
  def destroy
    find_invoice
    @invoice.destroy

    respond_to do |format|
      format.html { redirect_to('/invoices/overview') }
      format.xml  { head :ok }
    end
  end
  
  def customer_attributes
    find_invoice
    @invoice ||= Invoice.new
    respond_to do |format|
      format.js {}
    end
  end
  
  
  def recalculate
    sanitize_params
    find_invoice
    @invoice ||= @parent.invoices.build
    @the_customer ||= @invoice.customer
    @invoice.setup_taxes
    @invoice.attributes = params[:invoice]
    @invoice.calculate_discounted_total
    respond_to do |format|
      format.js do
      end
      format.html {
      }
    end
  end
  
  def filter
    split_multi_params(params[:filters], :customers, :statuses, :fromdate, :todate)
    setup_search_filters(@filter_name, :page_size => ::AppConfig.pagination.invoices.page_size)
      
    respond_to do |format|
      format.html do
        render :action => "overview"
      end
      format.xml  { render :xml => @filters.to_xml }
    end
  end
  def overview_grid
    @invoices = Invoice.find(:all, :conditions=>["status = ?","draft"], :limit=>'10')

    render :template => "/invoices/generated"
  end
  
  
  def overview
    respond_to do |format|
      format.html do
        split_multi_params(params[:filters], :customers, :statuses, :fromdate, :todate)
        setup_search_filters(@filter_name, :page_size => ::AppConfig.pagination.invoices.page_size)
        if session[:mobile_browser]
          @past_due_invoices = []
          @outstanding_invoices = []
          @draft_invoices = []
          @paid_invoices = []
          @quote_invoices = []
          
          @invoices = current_user.invoices.sort{|x, y| x.updated_at <=> y.updated_at }
          if @invoices.size > 0
            @invoices.each do |invoice|
              @past_due_invoices << invoice if (invoice.meta_status == Invoice::META_STATUS_PAST_DUE)
              @outstanding_invoices << invoice if (invoice.meta_status == Invoice::META_STATUS_OUTSTANDING)
              @draft_invoices << invoice if (invoice.meta_status == Invoice::META_STATUS_DRAFT)
              @paid_invoices << invoice if (invoice.meta_status == Invoice::META_STATUS_PAID)
              @quote_invoices << invoice if (invoice.meta_status == Invoice::META_STATUS_QUOTE)
            end
          end
          render_mobile(:mobile_layout => "mobile")
        end
      end
      format.js do
        overview_data
      end
      format.json do
        overview_data
      end
    end
  end
  
  def invoice_status
    find_invoice
    @the_customer ||= @invoice.customer
    respond_to do |format|
      format.js { render( :layout => false ) }
    end
  end
  
  def toggle_customer
    respond_to do |format|
      format.js { render( :layout => false ) }
    end
  end
   
  def mark_printed
    find_invoice
    @the_customer ||= @invoice.customer
    @invoice.print! unless @invoice.nil?
    render :text => @invoice.meta_status_string
  end

  def mark_sent
    find_invoice
    @the_customer ||= @invoice.customer
    if @invoice.meta_status == Invoice::META_STATUS_DRAFT
      @success = @invoice.mark_sent_without_sending!
    else
      @already_sent = true
    end
    render :partial => "/invoices/mark_sent_notice" 
  end

  def create_recurring_form
    find_invoice
    render :layout => false
  end

  def create_recurring
    find_invoice

    @recurring = Invoice.create_recurring_from @invoice, params[:invoice]

    if @recurring.valid?
      render :partial => "create_recurring_notice", :layout=>false
    else
      render :action => "create_recurring_form", :layout=>false
    end
    
  end

  def mark_record_payment
    find_invoice
    if [Invoice::META_STATUS_QUOTE, Invoice::META_STATUS_OUTSTANDING, Invoice::META_STATUS_PAST_DUE].include?(@invoice.meta_status) && !@invoice.customer.nil?
      raise Exception, "Invalid request"
    elsif @invoice.meta_status == Invoice::META_STATUS_DRAFT
      @message = _("Can't record a payment on a draft invoice. %{line_break}Please send it or mark it as sent first.") % {:line_break => "<br/>"}
      render :partial => "/invoices/record_payment_notice"      
    elsif @invoice.meta_status == Invoice::META_STATUS_PAID
      @message = _("This invoice has already been fully paid." )
      render :partial => "/invoices/record_payment_notice" 
    elsif @invoice.customer.nil?
      @message = _("Can't record a payment without a customer.")
      render :partial => "/invoices/record_payment_notice"
    else
      raise Exception, "Unknown invoice meta status"
    end
  end
  
  def mark_paid
    find_invoice
    if @invoice.is_a?(SimplyAccountingInvoice)
      @invoice.mark_paid! # marking paid is logic that belongs on model
      render :action => "simply/show", :id => @invoice.id
    else # ignore, but log error
      RAILS_DEFAULT_LOGGER.error("asked to mark_paid #{invoice.inspect}")
      render :action => "show", :id => @invoice.id
    end  
  end
  
  def send_notice
    find_invoice
    render :partial => "/invoices/send_notice" 
  end

  def convert_quote
    find_invoice

    @invoice.convert_quote_to_invoice!
    respond_to do |format|
      format.html{ redirect_to invoice_path(@invoice)}
      format.js  { render :nothing => true}
    end    
  end

  protected
  
  # Todo: create a method where I can throw any nested hash/array combination at it and It'll search for the keys I specify and sanitize them. 
  def sanitize_params    
    remove_commas_and_spaces(params[:invoice][:discount_value])
     
    unless params[:invoice].blank? || params[:invoice][:line_items_attributes].blank?
      params[:invoice][:line_items_attributes].each do |i|
        remove_commas_and_spaces(i[:quantity])
        remove_commas_and_spaces(i[:price])
      end
    end
  end
  
  def confirm_unique_availability
    if @invoice.unique_auto?
      confirmation = @invoice.unique_available?
      return confirmation
    else
      return true #no pre-save checks of custom numbers, let validator take care of that
    end
  end
  
    def overview_data
      sort_col = (params[:sort] || 'id')
      sort_dir = (params[:dir] || 'ASC')
      sort_col = case sort_col
                 when 'customer_name' then 'customers.name'
                 when 'unique' then "invoices.unique_number #{sort_dir}, invoices.unique_name"
                 else "invoices.#{sort_col}"
                 end
                 
      start = params[:start].to_i
      size = params[:limit].to_i
      size = 20 unless size > 0
      
      page = ((start/size).to_i)+1
      
      split_multi_params(params[:filters], :customers, :statuses, :fromdate, :todate)

      setup_search_filters(@filter_name, :page_size => size, :current => page)

      # The meta_status will come in as a string, but it is actually one of META_STATUS_*
      @filters.conditions = Invoice.find_by_meta_status_conditions(meta_status_from_str(params[:meta_status]))
      @filters.options = {:order=>sort_col+' '+sort_dir,
                          :include => [:pay_applications, :customer, :line_items]}
      @invoices = Invoice.filtered_invoices(@parent.invoices, @filters)

      return_data = Hash.new()
      return_data[:total] = @invoices.size
      return_data[:invoices] = @invoices
      json = return_data.to_json({:pass_options => {:invoices => Invoice.overview_listing_json_params}})
      json = globalize_for_ext(json)
      render :text=>json, :layout=>false
    end

  def find_invoice
    @invoice = @parent.invoices.find(params[:id]) unless params[:id].blank?
  end
  
  def find_parent
    find_customer
    @nested = !@customer.nil?
    @parent = @customer || current_user
    @filter_name = @nested ? "customer_#{@customer.id}_invoices_overview" : "invoices_overview"
  end
  
  def set_up
    @page_id = ( params[:action] == "recurring" ? 'Recurring invoices' :  'Invoices')
  end

  def access_key
    @key = params[:id]
  end
 
end
