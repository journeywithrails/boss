
class ContestController < ApplicationController
  layout "contest"
  before_filter :check_contest

  def index

  end
  
  def rules
    
  end
  
  def winners
    @winners = Winner.find(:all, :conditions => { :signup_type => session[:signup_type]}, :order => "draw_date DESC" )

  end
  
  def tell_a_friend
    @came_from_contest = "1"
    #redirect_to :controller => :referral, :action => :new, :source => :contest
  end
  
  def tell_a_friend_accepted
    @contest_action = ""
  end
  
  def signup
  end

  def tour
  end

  protected
  def check_contest
    if !::AppConfig.contest.bybs
      redirect_to "/home"
    else
      @contest_action = action_name
    end
  end



end