class BookkeepersController < ApplicationController
  # GET /bookkeepers
  # GET /bookkeepers.xml
  prepend_before_filter CASClient::Frameworks::Rails::Filter 
  before_filter :set_up
  before_filter :biller_view   
  permit "not bookkeeping"

  helper InvitationsHelper

  def index
    @bookkeepers = current_user.biller.bookkeepers
    @invitations = current_user.invitations.find_bookeeping_invitations
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @bookkeepers }
    end
  end

  # GET /bookkeepers/1
  # GET /bookkeepers/1.xml
  def show
    @bookkeeper = Bookkeeper.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @bookkeeper }
    end
  end

  # same code as bookkeeping_clients/destroy but is redirected back to bookkeepers index
  def delete_contract
    @bookkeeper = Bookkeeper.find(params[:id])
    @client = @bookkeeper.bookkeeping_clients.find(current_user.biller.id)

    bkc = @bookkeeper.bookkeeping_contracts.find(:first, :conditions => {:bookkeeping_client_id => @client.id })
    if bkc.invitation.terminate!
      flash[:notice] = _("Contract terminated for bookkeeper #{@bookkeeper.user.sage_username}")
    else
      flash[:warning] = _("Could not end contract for bookkeeper #{@bookkeeper.user.sage_username}")
    end
    redirect_to :action => "index"
  end  

  def withdraw_invitation
    invitation = BookkeepingInvitation.find_by_id( params[:id] )
    invitation.withdraw! unless invitation.nil?
    redirect_to :action => "index"
  end

  protected  
  
  def set_up
    @page_id = 'Share Data'
  end 

end
