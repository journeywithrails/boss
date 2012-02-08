class ApiToken < ActiveRecord::Base
  before_create :make_guid

  belongs_to :user_gateway
  belongs_to :invoice
  belongs_to :delivery
  belongs_to :user

  class << self
    def last
      find(:first, :order => 'id desc')
    end
  end

  def service_url_prefix
    # override if we have more than 1 api
    '/api/simply'
  end
  
  def guid
    self[:guid] ||= UUIDTools::UUID.random_create.hexdigest   
  end

  def to_param
    guid
  end

  def clear!(new_mode = nil)
    self.user_gateway = nil
    self.new_gateway = nil
    self.invoice = nil
    self.delivery = nil
    self.mode += ":#{ new_mode }" if new_mode
    save!
  end

  def set_current_user(user, password = nil)
    if user && (user != :false)
      self.user = user
      self.password = password unless password.blank?
      self.simply_username = user.sage_username
      save unless new_record?
      if send_invoice?
        set_created_by(invoice.customer, user) if invoice 
        set_created_by(invoice, user)
        set_created_by(delivery, user)
        if user_gateway and not user_gateway.user
          user_gateway.user = user
          user_gateway.save(false) unless user_gateway.new_record?
        end
      end
    end
  end

  def has_user_info?
    user
  end

  def send_invoice?
    browsal_type == 'SendInvoiceBrowsal'
  end

  def signup?
    browsal_type == 'SignupBrowsal'
  end

  def complete?
    mode =~ /received_complete/
  end

  def closed?
    mode =~ /received_close/
  end

  def user_gateway?
    user_gateway && user_gateway.active
  end

  def browsal_type
    case mode
    when /^simply:send_invoice/
      'SendInvoiceBrowsal'
    when /^simply:login/, /^simply:signup/
      'SignupBrowsal'
    else
      nil
    end
  end

  def layout_location
    if send_invoice?
      'send_invoice/'
    elsif signup?
      'signup/'
    else
      ''
    end
  end

  private

  def make_guid
    self.guid
  end

  def set_created_by(obj, user)
    if obj and not obj.created_by
      obj.created_by = user
      obj.save(false) unless obj.new_record?
    end
  end
end
