class ContactsController < ApplicationController
  prepend_before_filter CASClient::Frameworks::Rails::Filter  
  include RespondsToParent

  # GET /contacts
  # GET /contacts.xml
  before_filter :find_customer
  before_filter :biller_view  
  def index
    @contacts = @customer.contacts

    respond_to do |format|
      format.html # index.html.erb
      format.js                 
      format.xml  { render :xml => @contacts }
    end
  end

  # POST /contacts
  # POST /contacts.xml
  def create
    
    @contact = @customer.contacts.build(params[:contact])

    respond_to do |format|
      if @contact.save
        flash[:notice] = _('Contact was successfully created.')
        format.html { redirect_to(customer_contact_url(:customer_id => @customer.id, :id => @contact.id)) }
        format.js { render :text => "contact added", :layout => false }
        format.xml  { render :xml => @contact, :status => :created, :location => @contact }
      else
        format.html { render :action => "new", :layout => request.xhr? }
        format.xml  { render :xml => @contact.errors, :status => :unprocessable_entity }
      end
    end

  end

  # PUT /contacts/1
  # PUT /contacts/1.xml
  def update
    find_contact

    respond_to do |format|
      if @contact.update_attributes(params[:contact])
        flash[:notice] = _('Contact was successfully updated.')
          format.html { redirect_to(customer_contact_url(:customer_id => @customer.id, :id => @contact.id)) }
          format.js { render :text => "contact updated", :layout => false }
          format.xml  { render :xml => @contact, :status => :created, :location => @contact }
        else
          format.html { render :action => "edit", :layout => request.xhr? }
          format.xml  { render :xml => @contact.errors, :status => :unprocessable_entity }
        end
    end
  end
  
  protected
  def find_customer
    @customer = current_user.customers.find(params[:customer_id]) unless params[:customer_id].blank?
  end
   
  def find_contact
    @contact = @customer.contacts.find(params[:id])
  end
    
end
