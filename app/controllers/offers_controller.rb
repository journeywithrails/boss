class OffersController < ApplicationController
  prepend_before_filter CASClient::Frameworks::Rails::Filter
  before_filter :bookkeeper_view  
  # GET /offers
  # GET /offers.xml
  def index
    @offers = current_user.received_invitations

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @offers }
    end
  end

  # # GET /offers/1
  # # GET /offers/1.xml
  # def show
  #   @offers = Offers.find(params[:id])
  # 
  #   respond_to do |format|
  #     format.html # show.html.erb
  #     format.xml  { render :xml => @offers }
  #   end
  # end
  # 
end
