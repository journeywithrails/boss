class ProfilesController < ApplicationController
  helper :user_gateways
  prepend_before_filter CASClient::Frameworks::Rails::Filter
  before_filter :set_up  
  before_filter :biller_view  
  # GET /profiles/edit



  def edit
    get_profile #NOTE: if you make this a filter, cas logout requests will raise exception
    @logo = current_user.logo
    @designated_tab = get_current_section(params[:setting])
    @user_gateways = current_user.user_gateways
    flash.now[:warning] = _('The fields marked with an asterisk (*) are required to send an invoice.  %{line_break}Please complete the required fields before continuing.') % {:line_break => "<br/> "} unless @profile.is_complete?
    render_with_mobile_support(:mobile_layout => 'mobile', :action => 'edit')
  end

  # this action is called by the first_profile_edit route
  def new_edit
    edit
  end
  
  # PUT /profiles/1
  # PUT /profiles/1.xml
  def update
    get_profile 
    @designated_tab = get_current_section(params[:profile_tab])
    ok = true

    if params[:logo]
      if params[:logo][:delete] and params[:logo][:logo].blank?
        current_user.logo.destroy
        current_user.reload
      end
      unless params[:logo][:uploaded_data].blank?
        params[:logo].delete(:delete)
        current_user.logo ||= Logo.new()
        current_user.logo.attributes = params[:logo]
        sleep 5 if RUBY_PLATFORM =~ /(:?mswin|mingw)/
        ok = ok && current_user.logo.save
      end
    end
    @logo = current_user.logo
    @user_gateways = UserGateway.set(current_user, params[:user_gateways])
    @designated_tab = get_current_section(params[:profile_tab])
    begin

      respond_to do |format|    
        #use transaction here because acts_as_configurable save each attribute
        #individual so attributes= will trigger save of all attributes. 
        #When one attribute does not pass the validation, want to roll back all previous changes
        Profile.transaction do

          ok = ok && (@profile.attributes = params[:profile]) unless !params[:profile]
          ok &&= @profile.save
          if(ok)
            @tab_error = true if (@profile.logo && @profile.logo.errors.size > 0)
            @tab_error = true if @user_gateways && @user_gateways.any? { |ug| !ug.valid? }
            @designated_tab = get_next_section

            @profile.dirty_cache
            if @profile.is_complete? 
              if (current_user.invoices.count == 0)
                flash.now[:notice] = _("Your settings were successfully updated. You can now set up optional settings by following the below links, or go straight to <a href='/invoices/new'>creating</a> your first invoice.")              
              else
                flash.now[:notice] = _('Your settings were successfully updated.')
              end            
            else
		          @designated_tab = @profile.sections[0]
              flash.now[:warning] = _('The fields marked with an asterisk (*) are required to send an invoice.  %{line_break}Please complete the required fields before continuing.') % {:line_break => "<br/>"}
            end
            format.html {
              if (((@designated_tab == "done") || (session[:mobile_browser])) && (@profile.is_complete?))
                if ((session[:mobile_browser]) && current_user.customers.count == 0)
                  flash[:notice] = _('Please enter the information for your first customer.')
                  redirect_to("/customers/new")
                else
                  flash[:notice] = _('Your settings were successfully updated.')
                  redirect_to("/invoices/overview")
                end
              else
		        render_with_mobile_support(:mobile_layout => "mobile", :action => "edit", :setting => @designated_tab)
              end
            } #fixme should be redirect, but flash doesnt work then, even when removing the .now part
          else

            raise ActiveRecord::RecordNotSaved
            # format.html { render :action => "edit" }
            # format.xml  { render :xml => @profile.errors, :status => :unprocessable_entity }
          end
        end
      end
    rescue ActiveRecord::RecordNotSaved
      respond_to do |format|

        @tab_error = true

        format.html { render_with_mobile_support(:mobile_layout => "mobile", :action => "edit",  :setting => @designated_tab) }
        format.xml  { render :xml => @profile.errors.to_xml }
      end
    rescue => e
      RAILS_DEFAULT_LOGGER.error("while updating profile for user #{current_user.id} an error was thrown: #{e.inspect}")
      raise e if ENV['RAILS_ENV'] != 'production' # hmmm, blanket catching and ignoring of all exceptions is not so cool  
      flash.now[:notice] = _('An error occurred. Please check your settings and try again.')
      respond_to do |format|
        format.html { render_with_mobile_support(:mobile_layout => "mobile", :action => "edit") }
        format.xml  { render :xml => @profile.errors.to_xml }
      end
    end
  end 
  
  def switch_country
    get_profile
    @profile.company_country = params[:profile][:country]
    @profile.company_state = params[:profile][:province_state]
    
    respond_to do |format|
      format.js { render( :layout => false ) }
    end
  end
  
  def toggle_theme
    respond_to do |format|
      format.js { render( :layout => false ) }
    end
  end
  
  def toggle_specify_heard_from
    @heard_from = params[:heard_from]
    respond_to do |format|
      format.js { render( :layout => false ) }
    end
  end
  
  protected

  # currently we are allowing any service url, and just checking that attrs[:source] =~ /^billingboss
  # def auto_create_user?(attrs)
  #   # allow Billing Boss user to be automatically created from cas user (sage_username) on this action only,
  #   # which is used as service url for signup for users who are NOT authenticated by cas (no sage_username).
  #   # RADAR: If the chain of redirects back to BB from SAM to this service url is redirected, the user will
  #   # NOT be able to login to BB without provisioning BB from SS.
  #   RAILS_DEFAULT_LOGGER.debug("profiles_controller:auto_create_user? action_name: #{action_name.inspect}  attrs[:source]: #{attrs[:source].inspect} (attrs[:source =~ /^billingboss/]): #{(attrs[:source] =~ /^billingboss/).inspect}")
  #   
  #   (action_name == 'new_edit') && (attrs[:source] =~ /^billingboss/) || super
  # end

  def get_profile
    @profile = current_user.profile
  end
  
  def set_up
    @page_id = 'Settings'
  end
  
  def get_next_section
    links = []
    @profile.sections.each do |section|
	    links << section
    end

    return nil unless !params[:profile_tab].blank?
    return nil unless links.include?(params[:profile_tab]) 

    if ((links.index(params[:profile_tab]) + 1) != links.size)
      #element was not last one in array, so we get next one
      return links.at(links.index(params[:profile_tab]) + 1)
    else
      #element was last one, return itself
      return "done"
    end
  end

  def get_current_section(tab)
    if tab && @profile.sections.include?(tab)
	    @designated_tab = tab
    else 
	    @designated_tab = @profile.sections[0]
    end
  end

end
