require 'last_obelus/concurrency/checkpoints'

class Payment < ActiveRecord::Base
  
  cattr_accessor :log_events
  
  include Sage::BusinessLogic::Exception
  include LastObelus::Concurrency::Checkpoints
  set_test_checkpoint_source(OnlinePaymentsController) if RAILS_ENV == 'test'

  has_many :pay_applications, :dependent => :delete_all
  has_many :invoices, :through => :pay_applications
  belongs_to :created_by, :class_name => 'User', :foreign_key => :created_by_id
  belongs_to :customer

  validates_date :date, :allow_nil => true
  validates_presence_of :amount, :created_by_id, :customer_id
  validates_numericality_of :amount, :greater_than => 0, :message => N_("must be positive")

#paypal is not paypal express which is a valid gateway

  PayByNonGateway = ['cheque', 'cash', 'credit card', 'external', 'simply', 'paypal']
  #payment types
  # simply pay_type is used when the payment is created by simply calling mark_paid on the invoice
  PayBy = PayByNonGateway + TornadoGateway.active_gateways.map { |g| g.gateway_name }
  #paybymanual shows all payment types which can be manually recorded on the record payment form
  #controller will reject payment types not in paybymanual, but model will accept everything in payby
  PayByManual = [ 'cheque', 'cash', 'credit card', 'paypal']
  validates_inclusion_of :pay_type, :in => PayBy

  #RADAR: the first event called on a new record will fire the transition but won't save the state. 
  # Behind the scenes, the record will have been written to the database! The fix is to
  # only fire events on records that have already been saved to the database.
  acts_as_state_machine :initial => :created, :column => 'status' 
    state :created
    state :waiting_for_gateway, :enter => :set_gateway_token_date
    state :retrieving_details
    state :authorizing
    state :authorized
    state :confirming
    state :confirmed
    state :clearing
    state :cleared, :enter => :apply_to_invoice!
    state :chargeback
    state :cancelled_no_redo
    state :cancelled
    state :error
    state :recorded

    # NOTE: events that have _event appended to their name are being overridden
    #       to throw a CantPerformEventException if they fail. 
    #       It seems to me that ALL events should raise exceptions if they fail.
    #       (dw 2008-5-3)
    #
    #       You are probably right! but only if the class that wants acts_as_state_machine
    #       can optionally turn this behaviour off. If someone opens a ticket I will do
    #       this extension to acts_as_state_machine someday. (mj 2008-6-20)
    
    event :change do
      transitions :from => :created, :to => :created  
      transitions :from => :recorded, :to => :created  
    end

    # use this for the express checkouts
    event :pay do
      transitions :from => :created, :to => :created
      transitions :from => :confirming, :to => :confirming
      transitions :from => :clearing, :to => :clearing
    end
    
    
    event :redirect_to_gateway_event do
      transitions :from => :created, :to => :waiting_for_gateway
      transitions :from => :waiting_for_gateway, :to => :waiting_for_gateway # don't care about multiple clicks here
    end
    
    event :retrieve_details_event do
      transitions :from => :created, :to => :retrieving_details
      transitions :from => :waiting_for_gateway, :to => :retrieving_details
    end
    
    event :authorize do  
      transitions :from => :created, :to => :authorizing
      transitions :from => :authorizing, :to => :authorizing
    end
  
    event :authorized do  
      transitions :from => :authorizing, :to => :authorized  
    end  
    
    event :confirm do
      transitions :from => :authorized, :to => :confirming # in app checkout
                                            #TODO -- add guard to ensure there a payment occurred
      transitions :from => :retrieving_details, :to => :confirming, :guard => :has_live_token? # express checkout #RADAR potential fake payment? 
      transitions :from => :confirming, :to => :confirming # don't care about multiple clicks here
    end
      
    event :confirmed_event do
      transitions :from => :confirming, :to => :confirmed
    end
    
    event :clear_payment_event do
      transitions :from => :confirmed, :to => :clearing
      transitions :from => :created, :to => :clearing, :guard => :single_call_gateway?
    end
    
    event :cleared_event do
      transitions :from => :clearing, :to => :cleared
    end
    
    event :record_payment_event do
      transitions :from => :created, :to => :recorded
      transitions :from => :cancelled, :to => :recorded
    end
    
    event :chargeback do
      transitions :from => :cleared, :to => :chargeback
    end
    
    event :cancel do
      transitions :from => :created, :to => :cancelled_no_redo
      transitions :from => :waiting_for_gateway, :to => :cancelled_no_redo
      transitions :from => :authorizing, :to => :cancelled_no_redo
      transitions :from => :authorized, :to => :cancelled
      transitions :from => :confirming, :to => :cancelled
      transitions :from => :retrieving_details, :to => :cancelled
      transitions :from => :error, :to => :cancelled
    end
    
    event :uncancel_event do
      transitions :from => :cancelled, :to => :confirming
    end
    
    event :fail_event do
      transitions :from => :created, :to => :error
      transitions :from => :recording, :to => :error
      transitions :from => :waiting_for_gateway, :to => :error
      transitions :from => :retrieving_details, :to => :error
      transitions :from => :authorizing, :to => :error
      transitions :from => :authorized, :to => :error
      transitions :from => :confirming, :to => :error
      transitions :from => :confirmed, :to => :error
      transitions :from => :clearing, :to => :error
      transitions :from => :cleared, :to => :error
      transitions :from => :chargeback, :to => :error
    end
      
    event :retry do
      transitions :from => :created, :to => :created
      transitions :from => :waiting_for_gateway, :to => :created
      transitions :from => :error, :to => :created
      transitions :from => :confirming, :to => :created, :guard => :cancelable?
      transitions :from => :confirmed, :to => :created, :guard => :cancelable?
      transitions :from => :clearing, :to => :created, :guard => :cancelable?
#      transitions :from => :cancelled, :to => :created
    end

    extend PaymentParts::PaymentFilters
    
    # fixme : should I be using :joins rather than :includes ?
    def self.currency_exists?(currency)
      find(:all, :include => :invoices).map(&:currency).flatten.include?(currency)
    end

    def self.first_fallback_currency
      find(:all, :include => :invoices).map(&:currency).flatten.uniq.first
    end
    
    def customer_name
      customer.nil? ? nil : self.customer.name
    end

    def invoice_to_pay
      @invoice_to_pay ||= invoices.detect { |i| !i.fully_paid? }
    end

    def invoice_no      
      if (invoices.nil?)
        nil
      else
        i = self.invoices.find(:first)
        i.nil? ? "" : i.unique
      end
    end

    def invoice_full_amount
       if (invoices.nil?)
        0
      else
        i = self.invoices.find(:first)
        i.nil? ? "" : i.total_amount
      end
    end

  class << self

    def inactive_states
      ['cleared', 'cancelled', 'cancelled_no_redo']
    end

    def find_active_with_access_key(access_key)
      invoice = AccessKey.find_keyable(access_key) rescue nil
      if invoice
        # FIXME: the problem here is that this table is keyed to the access key
        # inself (which is meaningless) rather than to the invoice that the
        # access key represents.  That would be ok I guess but more than one
        # access key can actually represent the same invoice! I'm working
        # around the problem by looking up all access keys for an invoice and
        # searching against all of them. (dw May 21, 2008)
        access_keys = AccessKey.find(:all, :conditions => ['keyable_type = ? and keyable_id = ?', invoice.class.base_class.name, invoice.id]).map { |ak| ak.key }
        find(:first, :conditions => ["payments.from in (?) and payments.status not in (?)", access_keys, inactive_states])
      end
    end

    def find_cancelled_with_gateway_token(gateway_token)
      find(:first, :conditions => {:status => 'cancelled', :gateway_token => gateway_token}, :order => 'created_at DESC')
    end

    def find_cancelled_no_redo_with_gateway_token(gateway_token)
      find(:first, :conditions => {:status => 'cancelled_no_redo', :gateway_token => gateway_token}, :order => 'created_at DESC')
    end

    def get_test_checkpoint_semaphor(key)
      OnlinePaymentsController.get_test_checkpoint_semaphor(key)
    end

    def direct_payment_for_access_key(access_key, payment_type)
      if payment = Payment.find_active_with_access_key(access_key)
        if payment.retry!
          payment.payment_type = payment_type
          payment
        else
          nil
        end
      else
        invoice = AccessKey.find_keyable(access_key) rescue nil
        if invoice
          begin
            create_for_invoice(invoice, access_key, payment_type)
          rescue Sage::BusinessLogic::Exception::PaymentInProgressException => e
            nil
          end
        else
          raise ActiveRecord::RecordNotFound
        end
      end
    end

    # used in payments controller and above
    def create_for_invoice(invoice, from, payment_type = nil, gateway_name = nil, locked = false, attrs={})
      transaction do
        payment = self.new
        payment.from = from
        payment.created_by = invoice.created_by
        payment.customer = invoice.customer
        payment.amount = invoice.amount_owing
        payment.set_payment_type(invoice, payment_type || invoice.selected_payment_types.first)
        if payment.pay_type.nil? or (gateway_name and payment.pay_type != gateway_name)
          raise Sage::BusinessLogic::Exception::MalformedPaymentException, 
              'The selected payment method is no longer valid, please restart the transaction.'
        end
        payment.processing_pid = ::ProcessId.pid if locked
        payment.attributes = attrs
        payment.save!
        payment.apply_to_invoice!(invoice, 0)
        payment
      end
    end
    
    # lock_name is either 'complete' or 'confirm'
    def with_process_lock(payment, lock_name)
      begin
        test_checkpoint_notify("payments_#{ lock_name }_will_poll_for_process_lock".to_sym)
        test_checkpoint_wait("payments_#{ lock_name }_will_poll_for_process_lock".to_sym)
        lock_timeout = ::AppConfig.payments.send(lock_name.to_sym).process_lock_timeout
        locked_payment = nil
        begin
          Timeout.timeout(lock_timeout) do
            loop do
              test_checkpoint_notify("payments_#{ lock_name }_will_poll_for_process_lock".to_sym)
              break if locked_payment = get_process_lock(payment) # intentional assignment
              sleep lock_timeout / 10.0
            end
          end
        rescue Timeout::Error
          logger.debug "failed to get lock"
        end
        if locked_payment
          yield locked_payment
        else
          test_checkpoint_notify("payments_#{ lock_name }_locked_out".to_sym)
          test_checkpoint_wait("payments_#{ lock_name }_locked_out".to_sym)
          yield nil
        end
      ensure
        if locked_payment
          locked_payment.release_process_lock 
        else
          test_checkpoint_notify("payments_#{ lock_name }_locked_out".to_sym)
        end
      end
    end

    def get_process_lock(payment)
      pid = ::ProcessId.pid
      if payment.is_a?(Payment) and payment.processing_pid == pid
        payment 
      else
        id = payment.to_param
        locked_payment = nil
        Payment.transaction do
          begin
            Payment.uncached do # bah
              locked_payment = Payment.find(id, :conditions => ["processing_pid is null or processing_pid = ?", pid], :lock => true)
              locked_payment.update_attribute(:processing_pid, pid)
            end
          rescue
            #failed to get lock
            nil #noop for rcov
          end
        end
        locked_payment
      end
    end
  end

  def with_gateway
    if ready_to_pay?
      if gateway
        yield(gateway)
      else
        raise BillingError, 'Payment does not have an associated gateway'
      end
    end
  end

  def cancelable?
    if gateway
      gateway.cancelable?(self)
    end
  end

  def pay!(controller, _payment_type, access_key)
    self.payment_type = _payment_type
    with_gateway do |gateway|
      gateway.payment_url(controller, access_key)
    end
  end

  def submit!(controller, access_key, payment_data)
    with_gateway do |gateway|
      gateway.complete_purchase(controller, access_key, payment_data)
    end
  end

  def initialize_payment_data(params = {})
    with_gateway do |gateway|
      gateway.initialize_payment_data(params)
    end
  end

  def process_payment_params(params)
    with_gateway do |gateway|
      gateway.process_payment_params(params)
    end
  end

  def active?
    if self.class.inactive_states.include?(status)
      false
    else
      true
    end
  end

  def can_change_gateway?
    current_state == :created
  end

  def ready_to_pay?
    unless (current_state == :created)
      raise BillingError, "Invalid state for making a payment: #{ current_state }"
    end
    unless amount and amount > BigDecimal.new('0')
      raise BillingError, "Payment must have an amount above 0 to be paid"
    end
    unless pay_applications.inject(BigDecimal.new('0')) { |t, pa| t + pa.amount } == 0
      raise BillingError, "Payment has already been applied to invoices"
    end
    true
  end

  def gateway_class
    # FIXME: should there really be an exception if the payment has no gateway? What's wrong with a nil?
    invoice_to_pay.gateway_class(payment_type) || raise(MalformedPaymentException, 'unknown payment processor for payment type' + payment_type)
  end

  def gateway
    return @gateway if @gateway
    @gateway = gateway_class.new
    # FIXME: pay_type should be renamed to gateway_name
    # NOTE: this field is not technically needed since pay_type is no longer
    # used to determine the gateway used but it may be useful to know which
    # gateway payments are actually processed with. (dw 2008-12-11)
    self['pay_type'] = gateway_class.gateway_name 
    @gateway.invoice = invoice_to_pay
    @gateway.payment = self
    @gateway
  end

  def max_invoice_amount
    1000000 # I think this is in cents. should really be per currency though
  end

  def single_call_gateway?
    # are we using a gateway that does the entire process in a single call?
    gateway_class.single_call?
  end

  def payment_type
    self['payment_type'].to_sym if self['payment_type']
  end

  def set_payment_type(invoice, pt = nil)
    if pt.is_a?(String) or pt.is_a?(Symbol)
      if invoice and invoice.selected_payment_type?(pt.to_sym)
        if gc = invoice.gateway_class(pt.to_sym)
          @gateway = nil
          self['pay_type'] = gc.gateway_name 
          self['payment_type'] = pt.to_s
        end
      end
    else
      self['pay_type'] = nil
      self['payment_type'] = nil
    end
  end

  def payment_type=(pt)
    set_payment_type(invoice_to_pay, pt)
  end

  def prepare_default_fields
    self.date = Date.today
  end
  
  #FIXME: stub for the view to work  
  def invoice_id=(value)
    @invoice_id = value
  end
  
  def invoice_id
    @invoice_id
  end
  
  def applied_amount
    self.pay_applications.inject(BigDecimal.new("0")) {|sum, pa| sum += pa.amount}
  end
  
  def unapplied_amount
    self.amount - self.applied_amount
  end

  def recipient
    invoices.find(:first).created_by
  end

  def is_stale?
  # check for created payment that was abandoned
    if (self.in_progress?)
      diff = Time.now - self.updated_at
      if (diff > 15.minutes)
        return true
      end
    end
    return false
  end
  
  #FIXME -- need to avoid applying uncleared payment to invoice. Valid
  # states for applying payment to invoice are recorded & cleared
  # -- this could also be handled by looking at the state of the payment
  #    which would allow handling payments that take a long time to clear
  #    without losing track of which invoice they are supposed to be applied to.
  #    (dw 2008-5-4)
  def apply_to_invoice!(invoice=nil, amt=false)
    raise ActiveRecord::RecordNotSaved, "Cannot apply unsaved payment to invoice" if self.new_record?
    force = !!amt # is this the "right" way to coerce to a boolean?
    amt ||= self.amount
    if invoice.nil?
      raise MalformedPaymentException.new, "invoice is nil and this payment has no pay applications" if self.pay_applications.empty?
      invoices = self.pay_applications.collect {|a| a.invoice}.uniq
      raise Error.new, "invoice is nil and this payment is applied to more than one invoice" if invoices.length > 1
      invoice = invoices.first
    end
    
    invoice.assert_payable_by(self)
    
    other = invoice.pay_applications.find(:all, :conditions => "payment_id <> #{self.id}")
    
    other.each do |pa|
      if pa.payment.in_progress?
        #cancel stale paymens so this payment can go through
        if pa.payment.is_stale?
          pa.payment.cancel!
        else
          # might want to add the amount of time payment has been in progress here
          raise PaymentInProgressException.new(), "Can't apply payment #{self.id} to invoice #{invoice.id} because it has a payment in progress."
        end
      end
    end

    
    pay_apps = self.pay_applications.find(:all, :conditions => {:invoice_id => invoice.id})
    
    if pay_apps.empty?
      amt = [amt, self.unapplied_amount, invoice.amount_owing].min
      return if amt <= BigDecimal.new("0") unless force
      
      pa_attr = {:invoice_id => invoice.id, :amount => amt, :created_by_id => self.created_by_id }
      pa = self.pay_applications.create(pa_attr)
      self.invoices.reload
      invoice.reload
      pa
    else
      pa_app = pay_apps.first
      amt = [amt, self.unapplied_amount + pa_app.amount, pa_app.amount + invoice.amount_owing].min
      return if amt <= BigDecimal.new("0") unless force

      pay_apps.first.update_attribute('amount', amt)
      invoice.reload #RADAR -- moderate overhead buys safety from tricky bugs
      pay_apps.first
    end
  end
  
  # Make sure the invoice states are set correctly
  def set_payment_states!(invoice)
    if (!invoice.nil?)
      invoice.acknowledge_payment(true)
    else
      raise BillingError, "set_payment_states!: invoice was nil"
    end
  end
  
  def save_and_apply(invoice=nil)
    transaction do
      if invoice.type == "SimplyAccountingInvoice" and amount != invoice.amount_owing
        errors.add(:amt, "must be the full invoice amount for Simply Accounting invoices.")
        return false
      else
        save!
      end
      record_payment! unless self.status == "recorded"
      unless invoice.nil?
        apply_to_invoice!(invoice)
        set_payment_states!(invoice) 
      end
    end
  end
  
  def uncancel!
    unless uncancel_event!
      raise CantPerformEventException.new(self, :uncancel)
    end      
  end

  def record_payment!
    unless record_payment_event!
      raise CantPerformEventException.new(self, :record_payment)
    end      
  end

  def retrieve_details!
    unless retrieve_details_event!
      raise CantPerformEventException.new(self, :retrieve_details)
    end
  end

  def fail!
    unless fail_event!
      raise CantPerformEventException.new(self, :fail)
    end
  end

  def cleared!
    unless cleared_event!
      raise CantPerformEventException.new(self, :cleared)
    end
  end

  def clear_payment!
    unless clear_payment_event!
      raise CantPerformEventException.new(self, :clear_payment)
    end
  end

  def confirmed!
    unless confirmed_event!
      raise CantPerformEventException.new(self, :confirmed)
    end
  end

  def redirect_to_gateway!
    unless redirect_to_gateway_event!
      raise CantPerformEventException.new(self, :redirect_to_gateway)
    end
  end

  # retrieves amount as cents, rounding to zero decimal places
  def amount_as_cents
    self.amount ||= BigDecimal.new("0")
    self.amount.mult(BigDecimal.new('100'), 0).round(0)
  end

  def currency
    if invoice = invoices.first
      invoice.currency
    else
      'USD'
    end
  end

  def release_process_lock
    Payment.transaction do
      self.lock!
      if self.processing_pid == ::ProcessId.pid
        self.update_attribute(:processing_pid, nil)
      end
    end
  end
  
  def in_progress?
    return true unless ["recorded", "cleared", "cancelled", "cancelled_no_redo"].include?(self.status)
  end

  def has_live_token?
    result = ! self.cancelable?
    result
  end
  
  def set_gateway_token_date
    #RADAR this relies on the fact that the state_machine events, by calling update_attribute, actually
    # update the whole record. If at some point state_machine is refactored to only update the state
    # column when firing an event, this must get it's own save.
    self.gateway_token_date = Time.now
  end
  
  def billing_process_response(*valid_states)
    if valid_states.include?(current_state)
      yield
      nil
    else
      case current_state
      when :confirming # we're already doing the thing, just return the page
        nil
      when :confirmed, :clearing 
        # another request is processing. we want to return a waiting for gateway, please reload
        [:unable_to_process_page, _("Your payment is being processed. Please check again in a few seconds."), :complete]
      when :cleared   
        # another request completed, so we want to return the complete page
        :complete_page
      when :error
        # we want to show unable, with a message to try clicking on the payment link again
        [:unable_to_process_page, _("Sorry, we are unable to complete your payment at this time. The payment service may be down or another error may have occurred. Please wait a moment and try again.")]
      when :created, :waiting_for_gateway, # these should only happen with a spoofed url. 
        :retrieving_details, # should never happen, as the process lock should cover user
        :authorizing, :authorized, # should never happen as we don't have a payflow that uses authorization yet
        :chargeback,  # this should never happen
        :recorded # should never happen as manually recorded payments never have a token
        raise BillingError, "unexpected status #{@payment.status} for billing process: #{self.inspect}"
      when :cancelled, :cancelled_no_redo # some other request managed to cancel on us!
        :cancel_page
      else
        raise BillingError, "unknown payment status for billing process: #{self.inspect}"
      end
    end
  end
  
  
  #return pay type that user would understand
  # for online payments, pay_type is set to the name of gateway which is not very understandable to users
  def pay_type_display
    if PayByManual.include?(pay_type)
      return pay_type
    else
      return _("Online Payments")
    end
  end
  
  def manual_payment?
    return PayByManual.include?(pay_type)    
  end

  protected

  # FIXME: pay_type should be renamed to gateway_name
  def pay_type=(pt)
    if pt.blank? or PayByNonGateway.include?(pt)
      @gateway = nil
      self['payment_type'] = nil
      self['pay_type'] = pt
    else
      raise 'The gateway should not be assigned directly anymore, it should be chosen based on payment_type (visa, amex, etc)'
    end
  end

end
