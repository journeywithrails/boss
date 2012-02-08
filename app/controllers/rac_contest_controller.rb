class RacContestController < ApplicationController
  layout "contest"
  before_filter :check_contest

  def index
    
  end
  
  def rules
    
  end
  
  def winners
    @winners = Winner.find(:all, :conditions => { :contest_type => "RAC"}, :order => "draw_date DESC" )

  end
  
  def tell_a_client
    @came_from_rac_contest = "1"
    #redirect_to :controller => :referral, :action => :new, :source => :contest
  end
  
  def tell_a_client_accepted
    @contest_action = ""
  end
  
  def enter
    session[:login_from] = "rac"
    p session[:login_from]
  end
  
  def login
    session[:login_from] = "rac"
  end

  def tour
  end

  protected

  protected
  def check_contest
    session[:signup_type] = "rac"
    session[:login_from] = nil
    if !::AppConfig.contest.rac
      redirect_to "/"
    else
      @contest_action = action_name
    end
  end

end