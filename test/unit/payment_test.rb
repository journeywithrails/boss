require File.dirname(__FILE__) + '/../test_helper'

class PaymentTest < ActiveSupport::TestCase
  fixtures :users, :invoices, :payments, :line_items, :pay_applications
  include Sage::BusinessLogic::Exception

  def valid_blank_payment(gateway = nil)
    i = invoices(:unpaid_invoice_1)
    assert i.pay_applications.empty?
    
    u = i.created_by
    p = u.payments.build(
        :pay_type => "cash",
        :amount => i.amount_owing,
        :customer_id => i.customer
    )
    gateway ||= PaypalGateway.new
    p.stubs(:gateway).returns(gateway)
    assert p.valid?
    assert p.save
    p
  end
  private :valid_blank_payment
  
  #test pay application added against invoice if invoice is present
  def test_should_apply_new_payment_against_invoice_with_no_payments
    i = invoices(:unpaid_invoice_1)
    assert i.pay_applications.empty?
    
    u = i.created_by
    p = u.payments.build(
        :pay_type => "cash",
        :amount => i.amount_owing,
        :customer_id => i.customer
    )
    assert p.valid?
    assert p.save
    
    p.apply_to_invoice!(i)
    assert_equal 0, p.unapplied_amount
    assert_equal 0, i.amount_owing
  end
  
  #test pay application added against invoice if invoice is present
  def test_should_save_and_apply_new_payment_against_invoice_with_no_payments
    i = invoices(:unpaid_invoice_1)
    assert i.pay_applications.empty?
    
    u = i.created_by
    p = u.payments.build(
        :pay_type => "cash",
        :amount => i.amount_owing,
        :customer_id => i.customer
    )
    assert p.valid?
    
    p.save_and_apply(i)
    assert_equal "paid", i.status
    assert_equal 0, p.unapplied_amount
    assert_equal 0, i.amount_owing
  end
  
  def test_should_fail_to_apply_new_payment_against_invoice_with_no_payments
    i = invoices(:unpaid_invoice_1)
    assert i.pay_applications.empty?
    
    u = i.created_by
    p = u.payments.build(
        :pay_type => "cash",
        :amount => i.amount_owing,
        :customer_id => i.customer
    )
    assert p.valid?

    #Choose other payment path
    p.save!
    p.update_attribute(:status, 'waiting_for_gateway')

    assert_raises CantPerformEventException do
      p.save_and_apply(i)
    end
    p.reload
    i.reload
    assert_equal "sent", i.status
    assert_equal 1000, i.amount_owing
  end

  def test_should_not_apply_payment_against_invoice_for_new_record
    i = invoices(:unpaid_invoice_1)
    assert i.pay_applications.empty?

    u = i.created_by
    p = u.payments.build(
        :pay_type => "cash",
        :amount => i.amount_owing,
        :customer_id => i.customer
    )
    assert p.valid?

    assert_raise(ActiveRecord::RecordNotSaved) do
      p.apply_to_invoice!(i)
    end
  end

#  def test_should_save_but_not_apply_payment_against_invoice_for_new_record
#    i = invoices(:unpaid_invoice_1)
#    assert i.pay_applications.empty?
#
#    u = i.created_by
#    p = u.payments.build(
#        :pay_type => "cash",
#        :amount => i.amount_owing,
#        :customer_id => i.customer
#    )
#    assert p.valid?
#
##    assert_raise(ActiveRecord::RecordNotSaved) do
#      p.save_and_apply(i)
##    end
#    assert_equal "sent", i.status
#  end

  def test_should_apply_new_partial_payment_against_invoice_with_no_payments
    i = invoices(:unpaid_invoice_1)
    assert i.pay_applications.empty?
    
    u = i.created_by
    amount_applied = i.amount_owing-10
    p = u.payments.build(
        :pay_type => "cash",
        :amount => amount_applied,
        :customer_id => i.customer
    )
    assert p.valid?
    assert p.save
    
    p.apply_to_invoice!(i)
    assert_equal 0, p.unapplied_amount
    assert_equal i.total_amount - amount_applied, i.amount_owing
  end

  def test_should_save_and_apply_new_partial_payment_against_invoice_with_no_payments
    i = invoices(:unpaid_invoice_1)
    assert i.pay_applications.empty?
    
    u = i.created_by
    amount_applied = i.amount_owing-10
    p = u.payments.build(
        :pay_type => "cash",
        :amount => amount_applied,
        :customer_id => i.customer
    )
    assert p.valid?
    
    p.save_and_apply(i)
    assert_equal "acknowledged", i.status
    assert_equal 0, p.unapplied_amount
    assert_equal i.total_amount - amount_applied, i.amount_owing
  end

  def test_should_apply_new_payment_against_partially_paid_invoice
    i = invoices(:partially_paid_invoice)
    assert !i.pay_applications.empty?
    
    u = i.created_by
    payment_amount = i.amount_owing + 5
    p = u.payments.build(
        :pay_type => "cash",
        :amount => payment_amount,
        :customer_id => i.customer
    )
    assert p.valid?
    assert p.save
    
    p.apply_to_invoice!(i)
    assert_equal 5, p.unapplied_amount
    assert_equal 0, i.amount_owing
  end

  def test_should_save_and_apply_new_payment_against_partially_paid_invoice
    i = invoices(:partially_paid_invoice)
    assert !i.pay_applications.empty?
    
    u = i.created_by
    payment_amount = i.amount_owing + 5
    p = u.payments.build(
        :pay_type => "cash",
        :amount => payment_amount,
        :customer_id => i.customer
    )
    assert p.valid?
    
    p.save_and_apply(i)
    assert_equal "paid", i.status
    assert_equal 5, p.unapplied_amount
    assert_equal 0, i.amount_owing
  end

  def test_should_apply_specified_amount_of_new_payment_to_unpaid_invoice
    i = invoices(:unpaid_invoice_1)
    assert i.pay_applications.empty?
    
    u = i.created_by
    p = u.payments.build(
        :pay_type => "cash",
        :amount => 100,
        :customer_id => i.customer
    )
    assert p.valid?
    assert p.save
    
    p.apply_to_invoice!(i, 10)
    assert_equal 90, p.unapplied_amount
    assert_equal i.total_amount - 10, i.amount_owing
  end
  
  def test_should_apply_new_payment_to_multiple_unpaid_invoices
    i = invoices(:unpaid_invoice_1)
    i2 = invoices(:unpaid_invoice_2)
    assert i.pay_applications.empty?
    assert i2.pay_applications.empty?
    
    u = i.created_by
    p = u.payments.build(
        :pay_type => "cash",
        :amount => 20,
        :customer_id => i.customer
    )
    assert p.valid?
    assert p.save
    
    p.apply_to_invoice!(i, 11)
    p.apply_to_invoice!(i2, 9)
    assert_equal 0, p.unapplied_amount
    assert_equal i.total_amount - 11, i.amount_owing
    assert_equal i2.total_amount - 9, i2.amount_owing
  end

  def test_should_not_apply_payment_if_invoice_ambiguous
    p = payments(:payment_for_multiple_invoices)
    p.update_attribute(:amount, p.amount + 100) 

    assert_raises(Error) do
      p.apply_to_invoice!(nil)
    end
  end

  def test_should_apply_payment_all_available_to_unambiguous_invoice
    p = payments(:partial_payment_for_partially_paid_invoice)
    p.update_attribute(:amount, p.amount + 100) 

    i = invoices(:partially_paid_invoice)
    assert !i.pay_applications.empty?
    owing = i.amount_owing
    assert owing > 100

    p.apply_to_invoice!(nil)
    i.reload
    p.reload
    assert_equal 0, p.unapplied_amount
    assert_equal owing-100, i.amount_owing
  end

  def test_should_apply_payment_amount_specified_to_unambiguous_invoice
    p = payments(:partial_payment_for_partially_paid_invoice)
    p.update_attribute(:amount, p.amount + 100) 

    i = invoices(:partially_paid_invoice)
    assert !i.pay_applications.empty?
    owing = i.amount_owing
    assert owing > 100

    p.apply_to_invoice!(nil, 100)
    i.reload
    p.reload
    assert_equal p.amount-100, p.unapplied_amount
    assert_equal i.total_amount-100, i.amount_owing
  end
  
  def test_should_apply_payment_to_unambiguous_invoice_without_overpaying
    p = payments(:partial_payment_for_partially_paid_invoice)

    i = invoices(:partially_paid_invoice)
    p.update_attribute(:amount, i.total_amount + 100) 
    assert !i.pay_applications.empty?

    p.apply_to_invoice!(nil)
    i.reload
    p.reload
    assert_equal 100, p.unapplied_amount
    assert_equal 0, i.amount_owing
  end
  
  def test_should_apply_payment_to_unpaid_invoice_without_overpaying
    i = invoices(:unpaid_invoice_1)
    assert i.pay_applications.empty?
    
    u = i.created_by
    p = u.payments.build(
        :pay_type => "cash",
        :amount => i.amount_owing + 100,
        :customer_id => i.customer
    )
    assert p.valid?
    assert p.save
    
    p.apply_to_invoice!(i)
    assert_equal 100, p.unapplied_amount
    assert_equal 0, i.amount_owing
  end

  def test_should_not_apply_payment_against_invoice_with_other_in_progress_payment
    i = invoices(:partially_paid_invoice)
    assert !i.pay_applications.empty?
    
    i.pay_applications.each do |pa|
      pa.payment.update_attribute('status', 'authorizing')
    end
    
    u = i.created_by
    payment_amount = i.amount_owing + 5
    p = u.payments.build(
        :pay_type => "cash",
        :amount => payment_amount,
        :customer_id => i.customer
    )
    assert p.valid?
    assert p.save
    assert_no_difference "PayApplication.count" do
      assert_raise(PaymentInProgressException) do      
        p.apply_to_invoice!(i)
      end
    end
  end

  # test pay application only applied for recorded/cleared payment
  def test_should_not_apply_payment_against_invoice_unless_recorded_or_cleared
  end
    
  #test overpayment/single pay application does not exceed invoice amount.
  def test_pay_application_should_not_exceed_invoice_amount
    
  end

  #test sum of pay applications does not exceed invoice amount.
  def test_pay_application_sum_should_not_exceed_invoice_amount
    
  end

  #test for delete payment should delete associated pay applications.
  #It should also reset invoice state to acknowledged.
  def test_delete_payment_should_do_associated_cleanup
    
  end
  
  
  def test_creating_payment_for_invoice_sets_pay_application_amount_to_zero
  end
  
  def test_clearing_payment_updates_pay_application_amounts
  end
  
  def test_should_return_amount_as_cents
    p = Payment.new
    p.amount = BigDecimal.new("0")
    assert_equal 0, p.amount_as_cents
    p.amount = BigDecimal.new("1")
    assert_equal 100, p.amount_as_cents
    p.amount = BigDecimal.new("1.036")
    assert_equal 104, p.amount_as_cents
  end

  def test_should_create_pay_application_with_correct_created_by_id
    i = invoices(:unpaid_invoice_1)
    assert i.pay_applications.empty?
    
    u = i.created_by
    p = u.payments.build(
        :pay_type => "cash",
        :amount => i.amount_owing,
        :customer_id => i.customer
    )
    assert p.valid?
    assert p.save
    
    p.apply_to_invoice!(i)
    assert_equal 0, p.unapplied_amount
    assert_equal 0, i.amount_owing
    
    assert_equal 1, p.pay_applications.count
    c = p.pay_applications[0].created_by_id
    assert_equal u.id, c, "pay_application should have created_by_id of #{u.id} but was #{c}"
  end

  def test_should_get_process_lock
    p = valid_blank_payment
    p = Payment.get_process_lock(p)
    assert p
  end

  def test_should_fail_to_get_process_lock_on_locked_payment
    p = valid_blank_payment
    p = Payment.get_process_lock(p)
    assert p
    pid = ::ProcessId.pid + '1'
    Process.stubs(:pid).returns(pid)
    p = Payment.get_process_lock(p)
    assert_nil p
  end
  
  def test_should_release_process_lock
    invoice = invoices(:unpaid_invoice_1)
    assert invoice.pay_applications.empty?, "invoice starts out with no pay_applications"
    invoice.stubs(:selected_payment_type?).returns(true)
    invoice.stubs(:gateway_class).returns(PaypalGateway)
    p = Payment.create_for_invoice(invoice, nil, 'paypal', 'paypal', true)
    assert_equal ::ProcessId.pid, p.processing_pid, "locked payment should have processing pid == to this process.pid"
    p.release_process_lock
    p.reload
    assert_nil p.processing_pid, "lock should have been released"
  end

  def test_should_recognize_expired_token
    # NOTE: this is paypal-specific code
    p = valid_blank_payment
    assert !p.has_live_token?
    p.gateway_token = '123'
    assert !p.has_live_token?
    assert ::AppConfig.payments.paypal.token_life > 0

    p.gateway_token_date = Time.now
    assert p.has_live_token?

    p.gateway_token_date -= (::AppConfig.payments.paypal.token_life + 2)    
    assert !p.has_live_token?
  end
  
  def test_should_reset_stale_payments_to_cleared_for_paypal
    p = valid_blank_payment
    p.status = :confirming
    assert p.retry!

    p = valid_blank_payment
    p.status = :confirmed
    assert p.retry!

    p = valid_blank_payment
    p.status = :clearing
    assert p.retry!
  end
  
  def test_should_be_able_to_reset_stale_payments_to_cleared_for_beanstream_interac
    p = valid_blank_payment(BeanStreamInteracGateway.new)
    p.status = :clearing
    assert p.retry!
  end
  
  def test_should_not_be_able_to_reset_stale_payments_to_cleared_for_other_gateways
    p = valid_blank_payment(BeanStreamGateway.new)
    p.status = :clearing
    assert !p.retry!
  end
  
  def test_should_set_default_payment_date
    i = invoices(:unpaid_invoice_1)
    assert i.pay_applications.empty?
    
    u = i.created_by
    p = u.payments.build(
        :pay_type => "cash",
        :amount => i.amount_owing,
        :customer_id => i.customer
    )
    p.date = p.prepare_default_fields
    assert p.save
    assert_equal Date.today, p.date
  end
 
  def test_should_allow_override_of_default_date
    i = invoices(:unpaid_invoice_1)
    assert i.pay_applications.empty?
    
    u = i.created_by
    p = u.payments.build(
        :pay_type => "cash",
        :amount => i.amount_owing,
        :customer_id => i.customer
    )
    p.date = Date.today - 1
    assert p.save
    assert_equal (Date.today - 1), p.date
  end
  
  def test_should_allow_blank_date_at_save
    i = invoices(:unpaid_invoice_1)
    assert i.pay_applications.empty?
    
    u = i.created_by
    p = u.payments.build(
        :pay_type => "cash",
        :amount => i.amount_owing,
        :customer_id => i.customer
    )
    p.date = ""
    assert p.save
    assert_equal nil, p.date
  end

  def test_should_create_locked_for_invoice
    invoice = invoices(:unpaid_invoice_1)
    assert invoice.pay_applications.empty?, "invoice starts out with no pay_applications"
    invoice.stubs(:selected_payment_type?).returns(true)
    invoice.stubs(:gateway_class).returns(PaypalGateway)
    p = Payment.create_for_invoice(invoice, nil, 'paypal', 'paypal', true)
    assert_equal ::ProcessId.pid, p.processing_pid, "locked payment should have processing pid == to this process.pid"
    assert_equal 1, invoice.pay_applications.size, "after creating payment for invoice, invoice should have a pay_application"
  end

  def test_set_payment_states_results_in_paid_invoice
    i = invoices(:unpaid_invoice_1)
    p=Payment.new
    i.expects(:amount_owing).at_least_once.returns(BigDecimal.new('0'))
    i.stubs(:reload)
    p.set_payment_states!(i)
    assert i.paid?, "invoice should now be marked paid but is #{i.status}"
  end

  def test_set_payment_states_with_partial_payment_results_in_paid_invoice
    i = invoices(:unpaid_invoice_1)
    p=Payment.new
    i.expects(:amount_owing).at_least_once.returns(BigDecimal.new('1'))
    i.stubs(:reload)
    p.set_payment_states!(i)
    assert i.acknowledged?, "invoice should now be marked acknowledged but is #{i.status}"
  end

  def test_set_payment_states_raises_when_cant_fire_pay
    i = invoices(:unpaid_invoice_1)
    p=Payment.new
    i.expects(:amount_owing).at_least_once.returns(BigDecimal.new('0'))
    i.stubs(:reload)
    i.expects(:pay!).returns(false)
    assert_raises CantPerformEventException do
      p.set_payment_states!(i)
    end
  end

  def test_with_gateway
    p = Payment.new
    p.stubs(:ready_to_pay?).returns(true) # otherwise raises
    p.stubs(:gateway).returns(:the_gateway)
    result = nil
    p.with_gateway { |g| result = g }
    assert_equal(:the_gateway, result)
  end

  def test_with_gateway
    p = Payment.new
    p.stubs(:ready_to_pay?).returns(true) # otherwise raises
    p.stubs(:gateway).returns(nil)
    assert_raises(BillingError) do
      p.with_gateway 
    end
  end

  def test_submit_delegation
    p = Payment.new
    p.stubs(:ready_to_pay?).returns(true) # otherwise raises
    gateway = mock('Gateway')
    p.stubs(:gateway).returns(gateway)
    gateway.expects(:complete_purchase).with(:a, :b, [:c, :d]).returns(:result)
    assert_equal(:result, p.submit!(:a, :b, [:c, :d]))
  end

  def test_set_payment_states_raises_when_cant_fire_acknowledge
    i = invoices(:unpaid_invoice_1)
    p=Payment.new
    i.expects(:amount_owing).at_least_once.returns(BigDecimal.new('1'))
    i.stubs(:reload)
    i.expects(:acknowledge!).returns(false)
    assert_raises CantPerformEventException do
      p.set_payment_states!(i)
    end
  end

  def test_set_payment_states_raises_when_invoice_nil
    i = nil
    p=Payment.new
    assert_raises BillingError do
      p.set_payment_states!(i)
    end
  end

  def test_should_find_cancelled_for_invoice_and_token
    i = invoices(:unpaid_invoice_1)
    i.stubs(:selected_payment_type?).returns(true)
    i.stubs(:gateway_class).returns(PaypalGateway)
    p1 = Payment.create_for_invoice(i, nil, 'paypal', 'paypal')
    assert_nil i.cancelled_payment_with_gateway_token('1234')
    p1.update_attribute(:status, 'cancelled')
    assert_nil i.cancelled_payment_with_gateway_token('1234')
    p1.update_attribute(:gateway_token, '1234')
    assert_equal p1, i.cancelled_payment_with_gateway_token('1234')
  end
  
  def test_should_find_cancelled_no_redo_for_invoice_and_token
    i = invoices(:unpaid_invoice_1)
    i.stubs(:selected_payment_type?).returns(true)
    i.stubs(:gateway_class).returns(PaypalGateway)
    p1 = Payment.create_for_invoice(i, nil, 'paypal', 'paypal')
    assert_nil i.cancelled_no_redo_payment_with_gateway_token('1234')
    p1.update_attribute(:status, 'cancelled_no_redo')
    assert_nil i.cancelled_no_redo_payment_with_gateway_token('1234')
    p1.update_attribute(:gateway_token, '1234')
    assert_equal p1, i.cancelled_no_redo_payment_with_gateway_token('1234')    
  end

  def test_invoice_id_setter
    i = invoices(:unpaid_invoice_1)
    assert i.pay_applications.empty?
    
    u = i.created_by
    p = u.payments.build(
        :pay_type => "cash",
        :amount => i.amount_owing,
        :customer_id => i.customer
    )
    p.invoice_id = 12345
    assert_equal p.invoice_id, 12345
  end

  def test_should_default_to_us_currency
    assert_equal 'USD', Payment.new.currency
  end

  def test_should_use_invoice_currency_if_present
    i = invoices(:unpaid_invoice_1)
    i.currency = 'CAD'
    i.save(false)
    i.stubs(:selected_payment_type?).returns(true)
    i.stubs(:gateway_class).returns(PaypalGateway)
    p = Payment.create_for_invoice(i, nil, 'paypal', 'paypal')
    assert_equal 'CAD', p.currency
  end

  def test_active_payment_with_access_key
    key = 'zzzzz123'
    p = payments(:payment_for_invoice_10)
    p.from = key.reverse
    p.save!
    invoice = mock('invoice', :class => Invoice, :id => 123)
    AccessKey.expects(:find_keyable).with(key).returns(invoice)
    AccessKey.expects(:find).
      with(:all, :conditions => ['keyable_type = ? and keyable_id = ?', 'Invoice', 123]).
      returns([mock('key1', :key => key), mock('key2', :key => key.reverse)])
    assert_equal p, Payment.find_active_with_access_key(key)
  end

  def test_pay
    p = Payment.new
    p.expects(:ready_to_pay?).returns(true)
    gateway = mock('gateway')
    controller = mock('controller')
    gateway.expects(:payment_url).with(controller, 'key').returns('http://result')
    p.expects(:gateway).times(2).returns(gateway)
    p.expects(:payment_type=).with('payment_type')
    assert_equal 'http://result', p.pay!(controller, 'payment_type', 'key')
  end

  def test_pay_not_ready
    p = Payment.new
    p.expects(:ready_to_pay?).raises(BillingError)
    p.expects(:gateway).never
    p.expects(:payment_type=).with('payment_type')
    assert_raise BillingError do
      p.pay!(nil, 'payment_type', 'key')
    end
  end

  def test_pay_no_gateway
    p = Payment.new
    p.expects(:ready_to_pay?).returns(true)
    p.expects(:gateway).returns(nil)
    assert_raise BillingError do
      p.pay!(nil, nil, 'key')
    end
  end

  def test_not_ready_to_pay_without_applications
    p = Payment.new
    assert_raise BillingError do
      p.ready_to_pay?
    end
  end

  def test_not_ready_to_pay_wrong_state
    i = invoices(:unpaid_invoice_1)
    i.stubs(:selected_payment_type?).returns(true)
    i.stubs(:gateway_class).returns(PaypalGateway)
    p = Payment.create_for_invoice(i, nil, 'paypal', 'paypal')
    p.redirect_to_gateway!
    assert_raise BillingError do
      p.ready_to_pay?
    end
  end

  def test_ready_to_pay
    i = invoices(:unpaid_invoice_1)
    i.stubs(:amount_owing).returns(BigDecimal.new('123'))
    i.stubs(:selected_payment_type?).returns(true)
    i.stubs(:gateway_class).returns(PaypalGateway)
    p = Payment.create_for_invoice(i, nil, 'paypal', 'paypal')
    assert_equal :created, p.current_state
    assert_equal BigDecimal.new('123'), p.amount
    assert p.pay_applications.length > 0
    assert p.amount 
    assert(p.amount > BigDecimal.new('0'))
    assert_equal(BigDecimal.new('0'), p.pay_applications.inject(BigDecimal.new('0')) { |t, pa| t + pa.amount })
    assert p.ready_to_pay?
  end

  def test_is_payment_stale
    i = invoices(:unpaid_invoice_1)
    i.stubs(:selected_payment_type?).returns(true)
    i.stubs(:gateway_class).returns(PaypalGateway)

    p = Payment.create_for_invoice(i, nil, 'paypal', 'paypal')
    curr = Time.now
    p.updated_at = curr - 15.minutes - 1
    assert (p.is_stale?)
  end

  def test_is_payment_not_stale
    i = invoices(:unpaid_invoice_1)
    i.stubs(:selected_payment_type?).returns(true)
    i.stubs(:gateway_class).returns(PaypalGateway)

    p = Payment.create_for_invoice(i, nil, 'paypal', 'paypal')
    curr = Time.now
    p.updated_at = curr - 15.minutes + 1
    assert !(p.is_stale?)
  end

end
