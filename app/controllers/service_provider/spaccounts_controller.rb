class ServiceProvider::SpaccountsController < ServiceProviderController

  before_filter :default_xml_format
  before_filter :authenticate #, :except => [ :index ]
  before_filter :get_data_params, :only => [:create, :update]
  helper ServiceProvider::SpaccountsHelper
  helper ServiceProvider::SpsubscriptionsHelper
  
  # GET /spaccounts
  # GET /spaccounts.xml
  def index
    @spaccounts = Spaccount.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @spaccounts }
    end
  end

  # GET /spaccounts/1
  # GET /spaccounts/1.xml
  def show
    begin
      @spaccount = Spaccount.find(params[:id])
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @spaccount }
      end
    rescue
      render :nothing => true, :status => 404
    end

  end

  # GET /spaccounts/new
  # GET /spaccounts/new.xml
  def new
    @spaccount = Spaccount.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @spaccount }
    end
  end

  # GET /spaccounts/1/edit
  def edit
    @spaccount = Spaccount.find(params[:id])
  end

  # POST /spaccounts
  # POST /spaccounts.xml
  def create
    puts "SpaccountsController.create  @data_params: #{@data_params.inspect}" if $log_on
    password = @data_params.delete(:password)
    puts "create spaccount" if $log_on
    @spaccount = Spaccount.new(@data_params)
    puts "create user from spaccount" if $log_on
    user = User.new(Spaccount.new_user_params(@data_params))
    user.crypted_password = '*'
    user.signup_type = 'pe'
    user.active = false
    if not user.save
      puts "couldn't save user. user.errors: #{user.errors.inspect}" if $log_on
      @spaccount.errors.add_to_base('User could not be added.')
      respond_to do |format|
        format.html { render :action => "new" }
        format.xml  { render :xml => @spaccount.errors, :status => :unprocessable_entity }
      end
      return
    end
    
    @spaccount.user = user;
    puts "populate_profile" if $log_on
    user.populate_profile(@spaccount.new_profile_params)

    respond_to do |format|
      if @spaccount.save
        flash[:notice] = 'Spaccount was successfully created.'
        format.html { redirect_to(@spaccount) }
        format.xml  { render :xml => @spaccount, :status => :created, :location => service_provider_spaccount_url(@spaccount) }
      else
        puts "couldn't save spaccount. @spaccount.errors: #{@spaccount.errors.inspect}" if $log_on
        format.html { render :action => "new" }
        format.xml  { render :xml => @spaccount.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /spaccounts/1
  # PUT /spaccounts/1.xml
  def update
    @spaccount = Spaccount.find(params[:id])
    password = @data_params.delete(:password)

    respond_to do |format|
      if @spaccount.update_attributes(@data_params)
        flash[:notice] = 'Spaccount was successfully updated.'
        format.html { redirect_to(@spaccount) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @spaccount.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /spaccounts/1
  # DELETE /spaccounts/1.xml
  def destroy
    @spaccount = Spaccount.find(params[:id])
    @spaccount.destroy

    respond_to do |format|
      format.html { redirect_to(spaccounts_url) }
      format.xml  { head :ok }
    end
  end
end
