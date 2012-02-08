require 'digest/sha1'
require 'csv'
class User < ActiveRecord::Base
  include Princely::Storage::CacheableRootEntity
  
  attr_accessor :signup_key
  
  #indicate if this is a newly created user
  attr_accessor :new_user
  delegate :current_view, :to => :profile
  delegate :current_view=, :to => :profile
  
  has_many :customers, :foreign_key => 'created_by_id', :dependent => :delete_all, :order => 'name ASC'
  has_many :invoices,  :foreign_key => 'created_by_id', :dependent => :delete_all
  has_many :payments,  :foreign_key => 'created_by_id', :dependent => :delete_all
  has_one  :logo, :foreign_key => 'created_by_id', :dependent => :delete
  has_many :deliveries, :foreign_key => 'created_by_id', :dependent => :delete_all
  belongs_to :bookkeeper, :dependent => :delete
  belongs_to :biller, :dependent => :delete
  has_many :invitations, :foreign_key => 'created_by_id', :dependent => :delete_all
  has_many :received_invitations, :class_name => 'Invitation', :foreign_key => 'invitee_id'
  has_many :taxes, :as => :taxable, :class_name => 'Tax', :dependent => :delete_all
  has_many :browsals, :foreign_key => 'created_by_id', :dependent => :delete_all
  has_many :user_gateways, :dependent => :delete_all
  has_many :bounces
  has_one  :spaccount, :dependent => :delete
  
  include ::Tax::TaxesVersionOne
  
  serialize :searches
  
  acts_as_keyed
  acts_as_configurable

  validates_presence_of :sage_username, :allow_nil => false
  validates_acceptance_of :terms_of_service, :allow_nil => false, :message => N_("must be accepted."), :on => :create, :unless => Proc.new{|u| u.signup_type=='pe'}

  validates_inclusion_of    :heard_from, :in => ["accounting_technology_tour", "simply_partnership_2008", "friend_or_acquaintance", "search_engine_or_website", "other", "fr_canada_post"], :allow_nil => true
  validates_email_format_of :email, :message    => N_('must be a valid email address.')  
   
  def validate

    if new_record? and ::AppConfig.controlled_signup and not is_signup_key(self.signup_key)
      errors.add(_("You must enter the signup key from the person who invited you."), "")
    end
  end

  def is_signup_key(a)
      candidate = a.to_i
      keys = [
      100524, 100854, 102143, 102994, 105871, 107371, 108521, 108722, 110627, 111094,
      111863, 112411, 113336, 115640, 115722, 121549, 127798, 128568, 131402, 136128,
      144583, 148982, 154282, 154458, 157438, 159304, 159650, 162348, 164467, 165299,
      165855, 169026, 170022, 170280, 174403, 175083, 187968, 189813, 207651, 208526,
      208770, 214915, 222298, 222614, 223707, 224447, 227645, 230133, 233728, 237214,
      238524, 248303, 249904, 250508, 254232, 260694, 260802, 261766, 265159, 266693,
      266888, 273470, 275267, 279515, 280344, 289655, 293685, 299269, 304650, 305440,
      306662, 314627, 315261, 317246, 317450, 321633, 322995, 323478, 325207, 333955,
      335809, 343092, 345887, 347526, 350598, 352858, 354178, 354751, 360237, 360935,
      364986, 366768, 368076, 372725, 379558, 386373, 388820, 389207, 392710, 392733,
      393865, 394810, 395426, 404571, 406596, 406736, 410808, 411545, 411550, 412652,
      412934, 417526, 420371, 423257, 424596, 439413, 440937, 441198, 446468, 450228,
      451011, 457723, 466115, 466664, 471987, 475391, 476874, 485619, 486011, 487016,
      490466, 494525, 498239, 511073, 517734, 521147, 531382, 536105, 539480, 542223,
      542536, 544053, 547537, 548094, 553557, 560833, 563323, 565773, 569105, 569128,
      570616, 575401, 579326, 581482, 584126, 588153, 592176, 598837, 599414, 602915,
      609713, 618072, 626574, 629303, 632088, 632885, 635098, 636183, 637317, 638191,
      640675, 642643, 643517, 650558, 651254, 657032, 672629, 678502, 679763, 680377,
      682592, 685516, 686584, 691925, 692071, 694089, 695308, 697971, 705538, 710034,
      710396, 712159, 712335, 716996, 722521, 725680, 726381, 727232, 729881, 731411,
      732974, 734465, 737554, 737920, 745710, 747921, 748188, 752067, 753595, 753853,
      755237, 756003, 760435, 761762, 765712, 767224, 771934, 772095, 772290, 775879,
      783447, 783994, 788273, 790553, 797038, 797086, 800565, 802459, 805315, 805705,
      807699, 817411, 819595, 819910, 821832, 822784, 822891, 832819, 835469, 836924,
      838037, 839637, 841895, 842582, 849146, 850428, 851856, 853363, 861474, 863828,
      865577, 872949, 879061, 880592, 885711, 894062, 901118, 904745, 905906, 906738,
      908431, 911230, 919283, 921921, 923677, 926766, 927585, 929450, 938751, 939199,
      941681, 942244, 943710, 943875, 947910, 950142, 950856, 952097, 957524, 960709,
      961635, 962400, 964628, 968587, 971190, 974122, 974420, 976251, 976598, 977183,
      978252, 978462, 982030, 982414, 984560, 984627, 989217, 990705, 991579, 992503]
      keys.detect{|k| k==candidate}
  end
  
  def self.SignupTypes
    ["soho", "ssan", "rac"]
  end

  def self.DefaultSignupType
    "soho"
  end
  
  def self.HeardFrom
    ["accounting_technology_tour", "simply_partnership_2008", "friend_or_acquaintance", "search_engine_or_website", "other", "fr_canada_post"]
  end
  
    
  before_create :make_activation_code
  after_create :set_defaults

  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  
  attr_accessible :email, :sage_username, :terms_of_service, :signup_key, :heard_from, :created_at # must appear before acts_as_authorized_user and/or acts_as_authorizable

  ## locale
  def update_language!(language)
    update_attribute(:language, language)
  end
  
  ##############   Authorization System  ###################
  acts_as_authorized_user # must appear after attr_accessible  
  acts_as_authorizable  # must appear after attr_accessible

  # Activates the user in the database.
  def activate
    @activated = true
    self.activated_at = Time.now.utc
    self.activation_code = nil
    save(false)
  end

  def activated?
     # the existence of an activation code means they have not activated yet
     # note: the DB datetime does not have an offset, so Ruby interprets the time in the local time zone.  So the Ruby activate_at object must be converted to UTC before being compared.  
   activation_code.nil? and !activated_at.nil? and (activated_at+Time.now.utc_offset) < Time.now.utc
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  
  #save search params in a serialized dictionary on user, organized by key which will generally be the name of entity being listed
  # to use: in controller, @filters = current_user.set_or_get_search!(:invoices, params[:filters])
  def set_or_get_search!(key, params)
    return unless key
    key = key.to_sym
    if params and not params.empty?
      if params[:clear]
        self.searches[key].clear unless self.searches.nil? or self.searches[key].nil?
        self.save! #RADAR -- careful
        {}
      else
        self.searches ||= {}
        self.searches[key] = params
        self.save!
        self.searches[key]
      end
    else
      return nil if self.searches.nil?
      self.searches[key]
    end
  end
  
  def user_gateway(name = nil, new_if_not_found = false)
    if name
      found = user_gateways.find_by_gateway_name(name)
      if found
        found
      elsif new_if_not_found
        UserGateway.new_polymorphic(:gateway_name => name)
      end
    else
      user_gateways.find(:first, :conditions=>{:active=>true})
    end
  end

  def payment_types(currency)
    user_gateways.map do |ug|
      ug.payment_types(currency)
    end.flatten.compact.uniq
  end

  def user_gateway_for(currency, payment_type)
    user_gateways.detect do |ug|
      ug.valid_for?(currency, payment_type)
    end
  end

  def user_gateways_for(currency, payment_types)
    user_gateways.select do |ug|
      if ug.supports_currency?(currency)
        payment_types.any? do |payment_type|
          ug.valid_for?(currency, payment_type)
        end
      end
    end
  end

  def gateway_class(currency, payment_type)
    ug = user_gateway_for(currency, payment_type)
    ug.gateway if ug
  end
  
  def profile
    @profile ||= Profile.new(self)
  end

  ###Invoice number generation scoped for the current user

  def generate_next_auto_number(start_number="none", field_name="unique_number", conds="status NOT IN ('quote_draft','quote_sent')")
    #starting point will be last saved autonum for the user
    if start_number == "none"
      start_query = "select #{field_name} from invoices where created_by_id = #{self.id} and #{conds} order by id desc limit 1";
      recordset = User.connection.select_one(start_query) 
      start_number = recordset[field_name] unless recordset.nil?
      if start_number.nil? or start_number.to_i < 0
        start_number = 0
      end
      start_number = start_number.to_i + 1
    end

    #number we need is free on first try
    im_feeling_lucky_query = "select #{field_name} from invoices where created_by_id = #{self.id} and #{field_name} = #{start_number}"
    result = User.connection.select_all(im_feeling_lucky_query)
    
    if result == []
      return start_number
    end

    #if num not available, get closest higher integer that is free
    #the query series are rather complex, but are much faster than using
    #nested ruby loops, and speed is important in this particular situation
    query = <<-EOQ
    select i1.#{field_name} - 1 as the_num from invoices i1
    where i1.#{field_name} > 1 and i1.#{field_name} > #{start_number}
    and i1.created_by_id = #{self.id}
    and not exists 
      (select * from invoices i2 where i2.#{field_name} = i1.#{field_name} - 1)
    order by the_num asc limit 1
    EOQ
    num = User.connection.select_one(query)
    if num.nil?
      query2 = <<-EOQ
      select max(i.#{field_name})+1 as the_num from invoices i where ((i.#{field_name} + 1) > #{start_number}) and i.created_by_id = #{self.id}
      EOQ
      num = User.connection.select_one(query2)
    end
    
    return (num.nil? or num['the_num'].nil?) ? start_number : num['the_num']
  end

  def has_role?(role_expr, authorizable_object=nil)
    case role_expr
    when "bookkeeping"
      return false unless self.bookkeeper
      return (super and ( authorizable_object.nil? or ! self.bookkeeper.bookkeeping_clients.find(authorizable_object.biller).nil? ))
    else
      super
    end
  end
  
  def has_role(role, authorizable_object=nil)
    case role
    when "bookkeeping"
      raise Sage::BusinessLogic::Exception::RolesException, _("cannot have bookkeeping role unless you are a bookkeeper") if bookkeeper.nil?
      raise Sage::BusinessLogic::Exception::RolesException, _("cannot have bookkeeping role for someone with no bookkeeping contract") unless bookkeeper.bookkeeping_clients.exists?(authorizable_object.biller)
      super
    else
      super
    end
  end
  
  def biller_with_lazy
    create_biller if biller_without_lazy.nil?
    biller_without_lazy
  end
  alias_method_chain :biller, :lazy

  def name
    return self.profile.company_name unless self.profile.nil? or self.profile.company_name.blank?
    return self.email
  end
  
  def set_defaults
    self.profile.theme = "Default"
    self.profile.currency = Currency.default_currency
    self.profile.tax_enabled = false
    self.profile.mail_opt_in = false
    self.profile.save
  end
  
  
  def inherit_taxes(taxable, inherit_enabled=true)
    ::Tax::TaxesVersionOne.each_tax_key {|tax_key| self.inherit_tax(tax_key, taxable, inherit_enabled)}
  end

  def inherit_tax(key, taxable, inherit_enabled=true)
    if self.profile.tax_enabled
      user_tax = self.tax_for_key(key)
      unless user_tax.nil?
        taxable.taxes << user_tax.new_copy(:enabled => (user_tax.enabled and inherit_enabled))
      end
    end
  end
  
	def find_or_build_simply_customer(params)
	  customer = self.customers.find(:first, :conditions => {:simply_guid => params[:simply_guid]})
	  customer ||= self.customers.build
	  good_params = customer.reject_unknown_attributes(params)
	  customer.attributes = good_params	 
	  customer 
	end
	

  # def find_or_build_invoice(params)
  #     existing_invoices = self.invoices.find(:all, :conditions => ["simply_guid = ? and status != 'superceded' and superceded_by_id is NULL", params[:simply_guid] ])
  #     existing_invoices.each do |existing_invoice|
  #       existing_invoice.supercede!
  #       existing_invoice.sup
  #     end
  #   invoice = self.customers.build(params)
  # end
  # 
  
  #TODO interface for the "sps detection" required by simply integration
  def has_sps?
    return (not self.user_gateways.find(:first, :conditions => "type = 'SageSbsUserGateway' or type = 'SageVcheckUserGateway'").nil?)
  end
  
  def has_multiple_invoice_types
    count = self.invoices.count(:group => 'type')
    count && (count.length > 1)
  end
  
  def invoice_types_for_select
    count = self.invoices.count(:group => 'type')
    count.collect{|tuple| [(tuple[0] || 'BillingBossInvoice').titleize, tuple[0] || 'Invoice']}
  end
  
  def register_sage_user_with_legacy_password!
    userlog = Logger.new(File.join(RAILS_ROOT, 'log', 'user_migration.log'))
    usercsvlog = File.open('log/user_migration.log.csv', 'a')    
    userlog.level = Logger::DEBUG
    userlog.formatter = Logger::Formatter.new
    
    # replace punctuation with '_', punctuation is not allowed in sagespark username
    username = barename = gsub_punctuation(self.email.split('@').first, '_')
    firstname = (self.profile && !self.profile.company_name.blank?) ? self.profile.company_name.split(' ').detect{|n| n.index(/[.,]/).nil? } : nil
    user_string = "User #{self.id} (#{self.email})"
    if self.bogus
      userlog.debug("skipped #{user_string} because it was bogus")
      usercsvlog.puts(CSV.generate_line(["d", "skipped", self.email]))
      
    elsif(sage_user = SageUser.find(:first, :conditions => {:email => self.email}))
      self.sage_username = sage_user.username
      self.save(false)
      sage_user.legacy_password = self.crypted_password
      sage_user.legacy_salt = self.salt
      sage_user.save(false)
      userlog.warn("#{user_string} had sage_username set to existing sage_user #{sage_user.id} (#{sage_user.username}) because they had the same email")
      usercsvlog.puts(CSV.generate_line(["w", "user name picked from Sage Spark", self.email, sage_user.username ]))
      if !self.valid?
        userlog.error("---- user_string was saved but was invalid: #{self.errors.inspect}")
        usercsvlog.puts(CSV.generate_line(["e", "invalid user record", self.email, self.errors.inspect ]))
      end
    else  
      if ['info','billing','sales','admin','accounts','contact','accounting'].include?(barename)
        # If barename is one of the common anonymous usernames,
        # use the domain name without the three letter extension.
        domain_name = email.split('@').last
        bare_domain_name = domain_name.split('.')
        bare_domain_name.pop
        # replace any remaining punctuation with '_' (eg billing.boss => billing_boss)
        username = barename = gsub_punctuation(bare_domain_name.join('_'), '_')
      end
      
      ix = 1
      while(existing_user = SageUser.find(:first, :conditions => {:username => username}))
        ix += 1
        username = barename + '_' + ix.to_s # ix.en.numwords
      end
      User.transaction do
        sage_user = ::SageUser.create( :legacy_password => self.crypted_password, 
                        :legacy_salt => self.salt, 
                        :username => username,
                        :email => email,
                        :source => 'billingboss',
                        :first_name => firstname
                        )
        self.sage_username = username
        self.save!
        if existing_user
          userlog.error("#{user_string} had sage_username set to new sage_user #{sage_user.id} (#{sage_user.username}) because a user with name #{barename} already existed, but with a different email: #{existing_user.id} (#{existing_user.email})")
          usercsvlog.puts(CSV.generate_line(["e", "bb user name is found at sage spark but owned by another user, new name picke", self.email, sage_user.username, barename, existing_user.email ]))
        else
          userlog.info("#{user_string} had sage_username set to new sage_user #{sage_user.id} (#{sage_user.username})")
          usercsvlog.puts(CSV.generate_line(["i", "user name generated for user", self.email, sage_user.username]))
        end
      end
      
    end
    usercsvlog.flush
    usercsvlog.close
    self.sage_username
  end

  def register_bogus_sage_user_with_legacy_password!
    userlog = Logger.new(File.join(RAILS_ROOT, 'log', 'user_migration.log'))
    userlog.level = Logger::DEBUG
    userlog.formatter = Logger::Formatter.new
    # replace punctuation with '_', punctuation is not allowed in sagespark username
    username = barename = gsub_punctuation(self.email.split('@').first, '_')
    firstname = (self.profile && !self.profile.company_name.blank?) ? self.profile.company_name.split(' ').detect{|n| n.index(/[.,]/).nil? } : nil
    user_string = "User #{self.id} (#{self.email})"
    if(sage_user = SageUser.find(:first, :conditions => {:email => self.email}))
      self.sage_username = sage_user.username
      self.save(false)
      sage_user.legacy_password = self.crypted_password
      sage_user.legacy_salt = self.salt
      sage_user.save(false)
      userlog.warn("#{user_string} had sage_username set to existing sage_user #{sage_user.id} (#{sage_user.username}) because they had the same email")
      if !self.valid?
        userlog.error("---- user_string was saved but was invalid: #{self.errors.inspect}")
      end
    else  
      if ['info','billing','sales','admin','accounts','contact','accounting'].include?(barename)
        # If barename is one of the common anonymous usernames,
        # use the domain name without the three letter extension.
        domain_name = email.split('@').last
        bare_domain_name = domain_name.split('.')
        bare_domain_name.pop
        # replace any remaining punctuation with '_' (eg billing.boss => billing_boss)
        username = barename = gsub_punctuation(bare_domain_name.join('_'), '_')
      end
      
      ix = 1
      while(existing_user = SageUser.find(:first, :conditions => {:username => username}))
        ix += 1
        username = barename + '_' + ix.to_s # ix.en.numwords
      end
      User.transaction do
        sage_user = ::SageUser.create( :legacy_password => self.crypted_password, 
                        :legacy_salt => self.salt, 
                        :username => username,
                        :email => email,
                        :source => 'billingboss',
                        :first_name => firstname
                        )
        self.sage_username = username
        self.save!
        if existing_user
          userlog.error("#{user_string} had sage_username set to new sage_user #{sage_user.id} (#{sage_user.username}) because a user with name #{barename} already existed, but with a different email: #{existing_user.id} (#{existing_user.email})")
        else
          userlog.info("#{user_string} had sage_username set to new sage_user #{sage_user.id} (#{sage_user.username})")
        end
      end
      
    end
    self.sage_username
  end

  def self.build_with_sage_username(attrs)
    user = User.new(    :sage_username => attrs['username'],
                        :terms_of_service => "1",
                        :email => attrs['email'],
                        :created_at => attrs['created_at'])
    user.build_biller
    user.new_user = true
    user
  end
  
  def credit_referral(referral_code)
    if !referral_code.blank?
      a = Referral.find(:first, :conditions => {:referral_code => referral_code })
      if a and a.accepted_at.blank?
        a.user = self
        a.accepted_at = Time.now
        a.save!
      end
    end
  end
  
  def self.valid_signup_type?(session_signup_type)
    User.SignupTypes.include?(session_signup_type)
  end
  
  def set_signup_type(session_signup_type, in_browsal)
    if User.valid_signup_type?(session_signup_type)
      self.signup_type = session_signup_type
    elsif in_browsal
      self.signup_type = "simply"
    else
      self.signup_type = "soho"
    end
  end

  def set_heard_from(heard_from)
    if self.profile.heard_from.blank? && !heard_from.blank?
      self.profile.heard_from = heard_from
      self.profile.venture_1_id = "" #need to save the configurable_settings record for venture_1_id even if its value is blank
    end
  end
  
  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end


  def populate_profile(params)
    profile.mail_opt_in = true if (%w{on true 1}.include?(params[:user_communications]))

    if signup_type == "rac" || signup_type == 'pe'
      profile.company_name = params[:profile_company_name] unless params[:profile_company_name].blank?
      profile.contact_name = params[:profile_contact_name] unless params[:profile_contact_name].blank?
      profile.company_address1 = params[:profile_company_address1] unless params[:profile_company_address1].blank?
      profile.company_city = params[:profile_company_city] unless params[:profile_company_city].blank?
      profile.company_state = params[:profile_company_state] unless params[:profile_company_state].blank?
      if signup_type == 'rac'
        profile.company_country = "CA"
      else
        profile.company_country = params[:profile_company_country] unless params[:profile_company_country].blank?
      end
      profile.company_postalcode = params[:profile_company_postalcode] unless params[:profile_company_postalcode].blank?
      profile.company_phone = params[:profile_company_phone] unless params[:profile_company_phone].blank?
      profile.user_record.heard_from = params[:user_heard_from] unless params[:user_heard_from].blank?
    end
    
    profile
  end

  def save_current_view(view)
    profile.update_attribute(:current_view, view)
  end
  
  protected
    
    def encrypt(str)
      self.class.encrypt(str, salt)
    end

    
    def make_activation_code
      self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    end 
    
    def gsub_punctuation(str, replacement)
      str.gsub(/[\.\!\@\#\$\%\^\&\*\(\)\-\+\=\{\}\[\]\:\;\<\,\>\?\\\/]/, replacement)
    end
    
        
end
