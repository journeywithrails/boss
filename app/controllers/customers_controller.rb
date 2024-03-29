class CustomersController < ApplicationController
  include RespondsToParent
  # GET /customers
  # GET /customers.xml
  require 'ostruct'
  prepend_before_filter CASClient::Frameworks::Rails::Filter
  before_filter :biller_view  
  before_filter :set_up
  helper :contacts
  
  #used in test and development mode only  
  def index
    setup_search_filters(:customers, :page_size => ::AppConfig.pagination.customers.page_size)
    @customers = Customer.filtered_customers(current_user.customers, @filters)
    @all_customers = current_user.customers
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @customers.to_xml }
      format.csv  do
         stream_csv do |csv|
            csv << ["customer_name", "customer_address1", "customer_address2", "customer_city", "customer_province_state", "customer_postalcode_zip", "customer_country", "customer_website", "customer_phone", "customer_language", "customer_fax", "contact_first_name", "contact_last_name", "contact_email", "contact_phone"]
            @all_customers.each do |c|
              customer = [c.name, c.address1, c.address2, c.city, c.province_state, c.postalcode_zip, c.country, c.website, c.phone, c.fax]
                c.contacts.each do |contact|
                  csv << customer + [contact.first_name, contact.last_name, contact.email]
                end
            end
          end
      end
    end
  end




  # GET /customers/new
  def new
    @customer = Customer.new
    @primary_only = true
    set_default_country
    
    respond_to do |format|
      format.html do
        if request.xhr?
          render :partial => "new_customer_dialog", :layout => false
        end
        render_mobile(:mobile_layout => "mobile")
      end
      format.xml  { render :xml => @customer.to_xml }      
    end
  end

  # GET /customers/1;edit
  def edit
    find_customer
    respond_to do |format|
      format.html do
        if request.xhr?
          render :partial => "edit_customer_dialog", :layout => false
        end
        render_mobile(:mobile_layout => "mobile")
      end
      format.xml  { render :xml => @customer.to_xml }      
    end
  end

  # POST /customers
  # POST /customers.xml
  def create
    @customer = current_user.customers.build  
    @customer.attributes = params[:customer]

    begin
      Customer.transaction do
        contact_params = params[:default]
        unless (contact_params.blank? or
                (contact_params[:first_name].blank? && 
                contact_params[:last_name].blank? && 
                contact_params[:email].blank? && 
                contact_params[:phone].blank?))
          @contact = @customer.contacts.build(contact_params)
          @contact.save!
          @customer.default_contact = @contact 
        end    
        
        @customer.save!
        @customer.prune_empty_contacts(true) #remove empty contacts
        flash[:notice] = _("Customer was successfully created.")
        respond_to do |format|            
          format.html do
            if request.xhr?
              @close_window = true
              render :partial => "new_customer_dialog", :layout => false
            else
              if session[:mobile_browser]
                redirect_to :action => "details", :id => @customer.id    
              else
                redirect_to :action => "edit", :id => @customer.id      
              end
            end
          end 
          format.xml  { head :created, :location => customer_url(@customer) }
        end # format
      end # Customer.transaction
    rescue
      respond_to do |format|    
        format.html do
          if request.xhr?
            render :partial => "new_customer_dialog", :layout => false, :status => :unprocessable_entity
          else
            @primary_only = true          
            render_with_mobile_support(:mobile_layout => 'mobile', :action => "new")  
          end
        end
        format.xml  { render :xml => @customer.errors.to_xml }
      end
    end
  end

  #details only used in mobile version
  def details
    find_customer
    render_mobile(:mobile_layout => "mobile")
  end

  def update
    find_customer    
    
    # RADAR ugly. The way this works is, there is a radio button for default contact
    # when we click add new contact, the radio button gets the row_id (from the multi-model
    # forms mechanism) as value. Real existing contacts get their id as the value of the 
    # their default_contact radio button. If it was a new contact passed in as default_contact,
    # we have to look up the corresponding contact_attributes in the array of contact_attributes
    # in params, and add a pseudo_attribute to it that will trigger the customer to set it as default_contact
    new_contact_row_id = false
    if params[:customer][:default_contact_id]
      if params[:customer][:default_contact_id] =~ /contact_new/
  
        new_contact_row_id = params[:customer].delete(:default_contact_id)
        attrs = params[:customer][:contacts_attributes].detect{|dict| dict[:row_id] == new_contact_row_id }
        attrs[:set_as_default_contact] = true #dummy attribute, checked for on Contact#after_create
      end
    end

    params[:customer][:default_contact] ||= params[:default] unless params[:default].nil?
    # need this because we want to show default contact by itself, without potential
    # for it to be added twice
    if params[:customer][:default_contact]
      unless @customer.default_contact.nil? or @customer.default_contact.new_record?
        @customer.default_contact.update_attributes( params[:customer].delete(:default_contact) )
      end
    end
    
    respond_to do |format|

      # RADAR  this is a little tricky. We assign the attributes to customer. If the default_contact has been
      # set to be a brand new contact, it will have a set_as_default_contact attr set (from above). After
      # setting customer attributes, we look through its contacts array to find such a contact. If we find
      # it, we save it (so that it has an id) and set customer.default_contact to it. THEN we can save
      # customer, which will cascade and save all the contacts updated via contacts_attributes by 
      # multimodel_forms magic
      
      @customer.attributes = params[:customer]

      if new_contact_row_id
        # we have to save again if default_contact was set to be a newly added contact
        new_default_contact = @customer.contacts.detect { |contact| contact.set_as_default_contact }
        new_default_contact.save
        @customer.default_contact = new_default_contact
      end
      
      if @customer.save
        @customer.prune_empty_contacts(true) #remove empty contacts
        flash[:notice] = _("Customer was successfully updated.")
        format.html do
          if request.xhr?
            @close_window = true
            render :partial => "edit_customer_dialog", :layout => false
          else
            if session[:mobile_browser]
              redirect_to :action => "details", :id => @customer.id    
            else
              redirect_to :action => "edit", :id => @customer.id      
            end
          end
        end
        format.xml  { head :ok }
      else
        # error condition
        @customer.prune_empty_contacts(false) #remove empty contacts but don't reload from database
        format.html do
          if request.xhr?
            render :partial => "edit_customer_dialog", :layout => false, :status => :unprocessable_entity
          else
            render_with_mobile_support(:mobile_layout => 'mobile', :action => "edit") 
          end
        end
        format.xml  { render :xml => @customer.errors.to_xml }
      end
    end
  end

  # DELETE /customers/1
  # DELETE /customers/1.xml
  def destroy
    find_customer
    @customer.destroy

    respond_to do |format|
      format.html { redirect_to('/customers/overview') }
      format.xml  { head :ok }
    end
  end
  
  def switch_country
    find_customer
    if @customer.nil? 
      @customer = current_user.customers.build( params[:customer] )
    else
      @customer.attributes = params[:customer]
    end
    
    respond_to do |format|
      format.js { render( :layout => false ) }
    end
  end

  def overview
    respond_to do |format|
      format.html do 
        split_multi_params(params[:filters])
        setup_search_filters(:customers_overview, :page_size => ::AppConfig.pagination.customers.page_size)
        if session[:mobile_browser]
          @customers = current_user.customers.sort{|x, y| x.name <=> y.name }
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
  
  def change_language
    @customer = Customer.find(params[:id])
    @customer.update_attribute(:language, params[:selected])
   respond_to do |format|
      format.js { render( :layout => false ) }
    end
  end
  
  include ActionView::Helpers::TextHelper # pluralize
  def import
    # todo : move out the controller
    file = params[:csv_import][:file]   
    new_customer = ""
    new_contact = ""
    before_count = current_user.customers.count
    Customer.transaction do
      FasterCSV.parse(file, :headers => true) do |row|
        row_hash = row.to_hash
        
        customer_attrib = {}
        contact_attrib = {}
        # removed contacts or customer from hash, then removed contact_ or customer_ from key name
        row_hash.dup.delete_if {|k,v| k =~ /^contact_/ }.map {|k,v| customer_attrib[k.gsub(/customer_/,'')] = v}
        row_hash.dup.delete_if {|k,v| k =~ /^customer_/ }.map {|k,v| contact_attrib[k.gsub(/contact_/,'')] = v}
        
        customer_name = customer_attrib["name"]
        found_customer = nil
        
        if new_customer.blank?
          found_customer = current_user.customers.find_by_name(customer_name)
        elsif new_customer.name == customer_name
          found_customer = new_customer
        else
          found_customer = current_user.customers.find_by_name(customer_name)
        end
        
        if found_customer
          if found_customer.new_record?
            if found_customer == new_customer
              new_customer.contacts.build(contact_attrib)
            else
              save_and_reset!(new_customer)
            end
          else
            unless found_customer.contacts.find(:first, :conditions => contact_attrib)
              found_customer.contacts.build(contact_attrib)
              found_customer.save!
              new_contact = "true"
            end
          end
        else
          if new_customer
            save_and_reset!(new_customer)
          end
          new_customer = current_user.customers.new(customer_attrib)
          new_customer.contacts.build(contact_attrib)
        end
        
      end
      save_and_reset!(new_customer)
    end
    after_count = current_user.customers.count
    total = after_count-before_count
    if new_contact == "true"
      flash[:notice] = _("Customer list was updated.")
    elsif total==0
      flash[:warning] = _("No new customers were imported.")
    else
      flash[:notice] = _("#{pluralize(total, 'customer')} imported.")
    end
      responds_to_parent do
        redirect_to overview_customers_path
      end
    rescue Exception
          responds_to_parent do
            render :update do |page|
              page.alert("There was an error importing your list. \n Please make sure the file is in the correct format.")
            end
          end
  end
     
  protected
  
  def overview_data
    sort_col = (params[:sort] || 'id')
    sort_dir = (params[:dir] || 'ASC')
    sort_col = case sort_col
               when 'contact_name' then 'contacts.name'
               else "customers.#{sort_col}"
               end
               
    start = params[:start].to_i
    size = params[:limit].to_i
    size = 20 unless size > 0
    
    page = ((start/size).to_i)+1
    
    split_multi_params(params[:filters], :customers, :fromdate, :todate)

    setup_search_filters(:customers, :page_size => size, :current => page)

    @filters.options = {:order=>sort_col+' '+sort_dir,
                        :include => [:contacts]}
                        
    @customers = Customer.filtered_customers(current_user.customers, @filters)

    return_data = Hash.new()
    return_data[:total] = @customers.size
    return_data[:customers] = @customers
    json = return_data.to_json(Customer.list_json_params)
    json = globalize_for_ext(json)
    render :text=>json, :layout=>false
  end
  
  
  
  def find_customer
    @customer = current_user.customers.find(params[:id]) unless params[:id].blank?
  end


  # set default country based on hints
  def set_default_country
	  # get the country from the user profile -- that's the most logical match
	  @profile = current_user.profile
	  
	  if @profile.country != "" then	    
		  @customer.country = @profile.country
	  else
		  # if that's not available (country unknown) get it from browser variables
		  set_country_from_http_accept_language
	  end
	  
  end

  # this just sets Canada, United States and United Kingdom from the request variable
  def set_country_from_http_accept_language

    #"HTTP_ACCEPT_LANGUAGE\"=>\"en-us,en;q=0.5\"
    accept_language = request.env['HTTP_ACCEPT_LANGUAGE']
    
    language = 'en'
    locale = 'us'
    
    unless accept_language.nil?
      language = accept_language[0,2] unless accept_language.length < 2
      locale = accept_language[3,2] unless accept_language.length < 5
    end
    
    case locale
      when 'us' then
        @customer.country = 'US'
      when 'ca' then
        @customer.country = 'CA'
      when 'gb' then 
        @customer.country = 'GB'
    end   
  end
  
  def set_up
    @page_id = 'Customers'
  end  

  def save_and_reset!(new_customer)
    unless new_customer.blank?
      new_customer.save!
      new_customer = ""
    end
  end
  
end
