class BookkeepingClientsController < ApplicationController

  prepend_before_filter CASClient::Frameworks::Rails::Filter, :bookkeeper_required, :find_bookkeeper
  before_filter :set_up  
  before_filter :bookkeeper_view  
  # GET /bookkeeping_clients
  # GET /bookkeeping_clients.xml
  def index
    @bookkeeping_clients = @bookkeeper.bookkeeping_clients.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @bookkeeping_clients }
    end
  end

  # GET /bookkeeping_clients/1
  # GET /bookkeeping_clients/1.xml
  def show
    @client = @bookkeeper.bookkeeping_clients.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @client }
    end
  end
  
  def destroy
    @client = @bookkeeper.bookkeeping_clients.find(params[:id])
    bkc = @bookkeeper.bookkeeping_contracts.find(:first, :conditions => {:bookkeeping_client_id => @client.id })
    if bkc.invitation.terminate!
      flash[:notice] = _("Contract terminated for client #{@client.user.sage_username}")
    else
      flash[:warning] = _("Could not end contract for client #{@client.user.sage_username}")
    end
    redirect_to :action => "index"
  end
  
#  # GET /bookkeeping_clients/new
#  # GET /bookkeeping_clients/new.xml
#  def new
#    @bookkeeping_clients = BookkeepingClients.new
#
#    respond_to do |format|
#      format.html # new.html.erb
#      format.xml  { render :xml => @bookkeeping_clients }
#    end
#  end
#
#  # GET /bookkeeping_clients/1/edit
#  def edit
#    @bookkeeping_clients = BookkeepingClients.find(params[:id])
#  end
#
#  # POST /bookkeeping_clients
#  # POST /bookkeeping_clients.xml
#  def create
#    @bookkeeping_clients = BookkeepingClients.new(params[:bookkeeping_clients])
#
#    respond_to do |format|
#      if @bookkeeping_clients.save
#        flash[:notice] = 'BookkeepingClients was successfully created.'
#        format.html { redirect_to(@bookkeeping_clients) }
#        format.xml  { render :xml => @bookkeeping_clients, :status => :created, :location => @bookkeeping_clients }
#      else
#        format.html { render :action => "new" }
#        format.xml  { render :xml => @bookkeeping_clients.errors, :status => :unprocessable_entity }
#      end
#    end
#  end
#
#  # PUT /bookkeeping_clients/1
#  # PUT /bookkeeping_clients/1.xml
#  def update
#    @bookkeeping_clients = BookkeepingClients.find(params[:id])
#
#    respond_to do |format|
#      if @bookkeeping_clients.update_attributes(params[:bookkeeping_clients])
#        flash[:notice] = 'BookkeepingClients was successfully updated.'
#        format.html { redirect_to(@bookkeeping_clients) }
#        format.xml  { head :ok }
#      else
#        format.html { render :action => "edit" }
#        format.xml  { render :xml => @bookkeeping_clients.errors, :status => :unprocessable_entity }
#      end
#    end
#  end
#
#  # DELETE /bookkeeping_clients/1
#  # DELETE /bookkeeping_clients/1.xml
#  def destroy
#    @bookkeeping_clients = BookkeepingClients.find(params[:id])
#    @bookkeeping_clients.destroy
#
#    respond_to do |format|
#      format.html { redirect_to(bookkeeping_clients_url) }
#      format.xml  { head :ok }
#    end
#  end
  
  protected
  def find_bookkeeper
    @bookkeeper = current_user.bookkeeper
  end
  
  def set_up
    @page_id = 'Reports'
  end  
  
end
