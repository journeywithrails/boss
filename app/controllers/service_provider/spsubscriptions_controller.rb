
class ServiceProvider::SpsubscriptionsController < ServiceProviderController

  before_filter :default_xml_format
  before_filter :authenticate #, :except => [ :index ]
  
  before_filter :find_parent
  before_filter :find_spsubscription, :only => [:show, :edit, :update, :destroy]
  before_filter :get_data_params, :only => [:create, :update]
  helper ServiceProvider::SpaccountsHelper
  helper ServiceProvider::SpsubscriptionsHelper
  
  # GET /spsubscriptions
  # GET /spsubscriptions.xml
  def index
    @spsubscriptions = @spaccount.spsubscriptions.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @spsubscriptions }
    end
  end

  # GET /spsubscriptions/1
  # GET /spsubscriptions/1.xml
  def show

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @spsubscription }
    end
  end

  # GET /spsubscriptions/new
  # GET /spsubscriptions/new.xml
  def new
    @spsubscription = Spsubscription.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @spsubscription }
    end
  end

  # GET /spsubscriptions/1/edit
  def edit

  end

  # POST /spsubscriptions
  # POST /spsubscriptions.xml
  def create
    qty = @data_params.delete(:newqty) 
    @data_params[:qty] = qty unless qty.nil?
    @data_params.delete(:oldqty)
    @spsubscription = @spaccount.spsubscriptions.new(@data_params)

    respond_to do |format|
      if @spsubscription.save
        flash[:notice] = 'Subscription was successfully created.'
        format.html { redirect_to(service_provider_spaccount_spsubscriptions_path(@spaccount)) }
        format.xml  { render :xml => @spsubscription, :status => :created, :location => service_provider_spsubscription_url(@spsubscription) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @spsubscription.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /spsubscriptions/1
  # PUT /spsubscriptions/1.xml
  def update
    qty = @data_params.delete(:newqty) 
    @data_params[:qty] = qty unless qty.nil?
    @data_params.delete(:oldqty)

    respond_to do |format|
      if @spsubscription.update_attributes(@data_params.merge(
        {:spaccount_id => @spaccount.id}))
        flash[:notice] = 'Subscription was successfully updated.'
        format.html { redirect_to(service_provider_spaccount_spsubscriptions_path(@spaccount)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @spsubscription.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /spsubscriptions/1
  # DELETE /spsubscriptions/1.xml
  def destroy

    @spsubscription.destroy

    respond_to do |format|
      format.html { redirect_to(service_provider_spaccount_spsubscriptions_path(@spaccount)) }
      format.xml  { head :ok }
    end
  end
  
private

  def find_parent
    @spaccount = Spaccount.find(params[:spaccount_id]) unless params[:spaccount_id].nil?
    #RAILS_DEFAULT_LOGGER.debug("@spaccount: #{@spaccount.inspect}")
  end
  
  def find_spsubscription
    begin
      @spsubscription = @spaccount.spsubscriptions.find(params[:id]) unless @spaccount.nil?
      true
    rescue
      render :nothing => true, :status => 404
      false
    end
    #RAILS_DEFAULT_LOGGER.debug("@spsubscription: #{@spsubscription.inspect}")    
  end  
  
end
