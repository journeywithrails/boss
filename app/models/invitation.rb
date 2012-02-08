class Invitation < ActiveRecord::Base
  has_many :deliveries, :as => :deliverable

  belongs_to :invitee, :class_name => 'User', :foreign_key => 'invitee_id'
  belongs_to :invitor, :class_name => 'User', :foreign_key => 'created_by_id'
  # alias_method :created_by, :invitor

  acts_as_keyed
  
  acts_as_state_machine :initial => :created, :column => 'status' 
    state :created                                #A didn't send
    state :sent                                   #A sent
    state :withdrawn                              #A sent, A withdrew; OR
                                                  #A sent, B accepted, A declined
    state :declined                               #A sent, B declined
                                                  #A sent, B accepted, B declined
    state :accepted, :enter => :record_acceptance #A sent, B accepted
    state :confirmed, :enter => :setup            #A sent, B accepted, A confirmed
    state :rescinded, :enter => :teardown         #A sent, B accepted, A confirmed, A terminated
    state :terminated, :enter => :teardown        #A sent, B accepted, A confirmed, B terminated
    
    event :accept do
      transitions :from => :sent, :to => :accepted
      transitions :from => :declined, :to => :declined
    end
    
    event :confirm do  
      transitions :from => :accepted, :to => :confirmed
    end
    
    event :decline do  
      transitions :from => :sent, :to => :declined
      transitions :from => :accepted, :to => :declined
    end
    
    event :withdraw do
      transitions :from => :sent, :to => :withdrawn
      transitions :from => :accepted, :to => :withdrawn
    end
    
    event :rescind do  
      transitions :from => :confirmed, :to => :rescinded
    end
    
    event :terminate do
      transitions :from => :confirmed, :to => :terminated
    end
  
    event :deliver do
      transitions :from => :created, :to => :sent
      transitions :from => :sent, :to => :sent
      transitions :from => :accepted, :to => :accepted
      transitions :from => :confirmed, :to => :confirmed
      transitions :from => :rescinded, :to => :sent #TODO correct?
      transitions :from => :withdrawn, :to => :sent
      transitions :from => :declined, :to => :declined #TODO perhaps this should change?
    end
    
  def self.find_bookeeping_invitations
    find(:all, :conditions => ['type = ? AND status != ?', "BookkeepingInvitation", "created"])
  end
      
  # hook fired when entering confirmed state, to allow subtype to 
  # do its thing
  def setup
    #implement in subclass;
  end


  # hook fired when entering rescinded state, to allow subtype to 
  # do its thing
  def teardown
    #implement in subclass;
  end
  
  # ensure the invitee is the user.
  def ensure_invitee(user)
    if self.invitee.nil?
      self.invitee = user
      save
    else
      self.invitee == user
    end
  end

  def status_explanation(status_string=nil)
    status_string ||= self.status
    case status_string
    when "accepted","confirmed"
      _('Invitation has been accepted.')
    when "declined"
      _('Invitation has been declined.')
    when "withdrawn"
      _("The invitation expired or was withdrawn by the sender.")
    when "terminated"
      _("This invitation has been terminated and is no longer valid.")
    when "rescinded"
      _("This invitation has been rescinded and is no longer valid.")
    end
  end
  
  def accept_invitation_for(user)
    
    # return error if the current user accepting the invitation is the user who created the invitation 
    if user.id == self.created_by_id 
        errors.add_to_base(_('Invitation was created by the same user who is accepting the invitation.'))
        return false
    end
       
    if ensure_invitee(user)
      if confirmed?
        errors.add_to_base(_('Invitation has already been accepted.'))
        return false
      end
      
      if withdrawn?
        errors.add_to_base(status_explanation)
        return false
      end
      
      #RAILS_DEFAULT_LOGGER.debug(".bb. accept! && confirm! 91:")            
      if accept! && confirm!
        return true
      else
        errors.add_to_base(_('Failed to accept invitation.'))
      end
    else
      # incorrect user on invitation 
      errors.add_to_base(_('You are not the user that was invited.'))
    end
    false
  end
  
  def decline_invitation_for(user)
    if declined?
      errors.add_to_base(_('Invitation has already been declined.'))
      return false
    end
    if not decline!
      errors.add_to_base(_('Invitation cannot currently be declined.'))
      return false
    end
    
    true
  end
  
  def record_acceptance
  end

  def sendable?(msgs={})
    self.valid?
  end
  
#  def short_description
#    raise "short_description unimplemented"
#  end
#
#  def long_description
#    raise "long_description unimplemented"
#  end
  
  def recipient
    return self.unless_nil?('invitee.email', deliveries.unless_nil?('first.recipients', '') )
  end
  
end
require_association 'bookkeeper_invitation'