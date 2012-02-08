# manages deliveries of entities by mail.
# mail_options: the mail_options attr is a serialized hash that the various entity mailers can use
# to configure/customize deliveries. The delivery controller will call setup_mail_options on the
# new action, which will allow the mailer class to setup the mail options for a particular mail
# When the delivery controller new action displayes the gui for a new delivery, it looks for
# a template in the mailer views with name "_[mail_name]_options.html.erb" and renders it as a
# partial. That partial can use delivery.mail_options hash to configure the mail.
class Delivery < ActiveRecord::Base  
  belongs_to :access_key
  belongs_to :deliverable, :polymorphic => true
  belongs_to :created_by, :class_name => 'User', :foreign_key => :created_by_id
  has_many :bounces
  serialize :mail_options

  validate :self_invitation
  validates_email_format_of :recipients, :list => true, :message => N_("must be a comma-separated list of email addresses")
  
  acts_as_state_machine :initial => :created, :column => 'status' 
  state :created
  state :sent
  state :error
  state :failure  
  state :temporary_failure  
  state :success
  state :acknowledged
  
  event :did_deliver do  
    transitions :from => :created, :to => :sent  
    transitions :from => :temporary_failure, :to => :sent  
  end

  event :fail do  
    transitions :from => :created, :to => :error
  end

  event :bounce do  
    transitions :from => :sent, :to => :failure
    transitions :from => :temporary_failure, :to => :failure
  end
  
  event :try_again do  
    transitions :from => :sent, :to => :temporary_failure
    transitions :from => :temporary_failure, :to => :temporary_failure
    transitions :from => :acknowledged, :to => :acknowledged
  end
    
  event :acknowledge do  
    transitions :from => :sent, :to => :acknowledged
    transitions :from => :temporary_failure, :to => :acknowledged
  end

  def initialize(attrs={})
    puts "delivery.initialize" if $log_on
    super
    self.mail_options ||= {}
    
    if self.recipients.nil? and self.deliverable and self.deliverable.respond_to?(:default_recipients)
      self.recipients = self.deliverable.default_recipients
    end
    puts "before test, self.subject: #{self.subject.inspect}\n self.deliverable and self.deliverable.respond_to?(:default_delivery_subject): #{self.deliverable and self.deliverable.respond_to?(:default_delivery_subject).inspect}" if $log_on
    if self.subject.nil? and self.deliverable and self.deliverable.respond_to?(:default_delivery_subject)
      self.subject = self.deliverable.default_delivery_subject
      puts "now subject is: #{self.subject}" if $log_on
    end
  end

  def store_errors(context_str, *objects)
    self.error_details ||= ""
    self.update_attribute('error_details', self.error_details + errors_xml(context_str, *objects))
  end
  
  def store_exception(context_str, e)
    self.error_details ||= ""
    self.update_attribute('error_details', self.error_details + exception_xml(context_str, e))
  end
  
  def errors_xml(context_str, *objects)
    objects.flatten!
    objects.unshift self
    ix = 0
    xml = Builder::XmlMarkup.new(:indent=>2)
    xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
    xml.context do
      xml.description(context_str)
      xml.objects do
        objects.each do |obj|
          xml.tag!(obj.class.name.underscore) do
            obj.errors.to_xml(:builder => xml, :skip_instruct => true)
          end
        end
      end
    end
  end

  def exception_xml(context_str, e)
    xml = Builder::XmlMarkup.new(:indent=>2)
    xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
    xml.context do
      xml.description(context_str)
      xml.exception do
        xml.name(e.class.name)
        xml.message(e.message)
        xml.backtrace(e.backtrace.join("\n"))
      end
    end
  end

  def deliver!(controller=nil)


    if %w{test development load_testing}.include?(RAILS_ENV) && self.recipients.include?('dontsend')
      if self.deliverable.respond_to?(:delivering)
        self.deliverable.delivering(self)
      end
      self.deliverable.deliver! 
      self.did_deliver!
    end

    ok = true;
    ok = self.save! if self.new_record?
    self.store_errors("deliver!: error after saving") unless ok
    begin      
      transaction do
        begin
          if deliverable.respond_to?(:delivering)
            deliverable.delivering(self)
          end
          if self.deliverable.deliver! or AppConfig.treat_failed_mail_as_delivered
            email = self.perform_delivery controller
            self.message_id = email.message_id
            deliver_email_copy(controller) if self.mail_options[:email_copy] == "on"
            ok = (self.did_deliver! && ok) || AppConfig.treat_failed_mail_as_delivered
            store_errors("deliver!: could not perform did_deliver!") if !ok
            
            
          else
            ok = false
            store_errors("deliver!: deliverable.deliver! failed", self.deliverable)
            self.fail!
          end
        rescue Exception => e
          if AppConfig.treat_failed_mail_as_delivered 
            puts "mail was not delivered: #{e.message}"
            # this block is intended for development only
            RAILS_DEFAULT_LOGGER.error(".mj. delivery.rb - 15: (attempting to continue) #{e.class.name} -- #{e.message}\n#{e.backtrace.join("\n")}")
            store_exception("deliver!", e)
            ok = true
          else
            raise
          end
        end
      end
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.error(".mj. delivery.rb - 15: #{e.class.name} -- #{e.message}\n#{e.backtrace.join("\n")}")
      store_exception("deliver!", e)
      ok = false
      self.fail!
    end
    ok
  end

  attr_accessor :email_copy
  def deliver_email_copy(controller)
    orig_recipients = self.recipients
    self.recipients = controller.current_user.email
    self.email_copy = true

    self.perform_delivery controller

    self.email_copy = nil
    self.recipients = orig_recipients
  end

  def mailer_klass
    begin
      "#{self.deliverable.class.name}Mailer".constantize
    rescue
      # if we couldn't find a mailer assume STI and try baseclass mailer
      "#{self.deliverable.class.base_class.name}Mailer".constantize
    end
  end
  
  def deliver_mail_method
    "deliver_#{self.mail_name}".to_sym
  end
  
  def mail_options_method
    "options_for_#{self.mail_name}".to_sym
  end
  
  def request_params
    {:delivery =>
      {:mail_name => self.mail_name,
       :deliverable_type => self.deliverable_type,
       :deliverable_id => self.deliverable_id
      }
    }
  end
  
  def deliverable_description
    return "" if self.deliverable.nil?
    return self.deliverable.description if self.deliverable.respond_to?(:description)
    "#{self.deliverable_type}: #{self.deliverable_id}"
  end
  
  def setup_mail_options
    return {} if self.deliverable.nil?
    return {} if self.mail_name.blank?
    if self.mailer_klass.respond_to?(self.mail_options_method)
      self.mail_options.merge!(self.mailer_klass.send(self.mail_options_method, self))
      self.mail_options
    else
      {}
    end
  end
  
  def self_invitation
    if 'Invitation' == self.deliverable_type
      errors.add_to_base(_("You cannot invite yourself as a bookkeeper.")) if self.deliverable.invitor.email == self.recipients
    end
  end

  def reply_to
    if self.created_by.profile.company_name.blank?
      self.created_by.email
    else
      "#{self.created_by.profile.company_name.gsub(/[,<>]/,' ')} <#{self.created_by.email}>"
    end
  end

	def company_name
    if self.created_by.profile.company_name.blank?
      self.created_by.email
    else
      self.created_by.profile.company_name
    end
  end

	def company_logo_url
		if self.created_by.profile.logo && self.created_by.profile.logo.image?
       self.created_by.profile.logo.public_filename
	  else
				''
		end
  end
  
  def associate_with_access_key(keystring)
    key = AccessKey.find_by_key(keystring)
    key.update_attribute(:not_tracked, true) if self.email_copy
    self.access_key = key
  end

  protected
  def perform_delivery(controller)
    self.mailer_klass.send(self.deliver_mail_method, self, controller)
  end

end
