require File.dirname(__FILE__) + '/../test_helper'

class ActivityTest < ActiveSupport::TestCase
  fixtures :invoices, :invoices
  
  def test_should_log_sent_invoices
    delivery = mock()
    delivery.stubs(:deliverable_type).returns("Invoice")
    delivery.stubs(:deliverable_id).returns(1)
    delivery.stubs(:recipients).returns("foo@bar.com")
    
    user = mock()
    user.stubs(:id).returns(1)
    
    @activity = Activity.log_send!(delivery, user)
    assert_equal @activity.invoice_id, delivery.deliverable_id
    assert_not_nil @activity.body
  end
  
  def test_should_log_updated_invoices
    invoice = mock()
    invoice.stubs(:id).returns(1)
    
    user = mock()
    user.stubs(:id).returns(1)
    
    @activity = Activity.log_update!(invoice, user)
    assert_equal @activity.invoice_id, invoice.id
    assert_equal "updated", @activity.body
  end
  
  def test_should_log_created_invoices
    invoice = mock()
    invoice.stubs(:id).returns(1)
    
    user = mock()
    user.stubs(:id).returns(1)
    
    @activity = Activity.log_create!(invoice, user)
    assert_equal @activity.invoice_id, invoice.id
    assert_equal "created", @activity.body
  end
  
  def test_should_log_forwarded_emails
  end
  
  def test_should_log_bounced_invoices
    delivery = mock()
    delivery.stubs(:deliverable_type).returns("Invoice")
    delivery.stubs(:deliverable_id).returns(1)
    bounce_id = 2

    @activity = Activity.log_bounce!(delivery, bounce_id)
    assert_equal @activity.invoice_id, delivery.deliverable_id
    assert_match /bounced/, @activity.body
  end
  
  def test_should_log_viewed_invoices
    invoice = invoices(:invoice_with_no_customer)
    remote_ip = "127.0.0.1"
             
    @activity = Activity.log_view!(invoice.id, remote_ip)
     
    assert_equal @activity.invoice_id, 1
    assert_match /viewed/, @activity.body
    assert_match /127.0.0.1/, @activity.extra
  end
  
  def test_should_log_payment
    invoice = invoices(:paid_invoice)
    payment = payments(:payment_for_invoice_10)
    
    @activity = Activity.log_payment!(invoice, payment)
    assert_equal @activity.invoice_id, invoice.id
    assert_match /payment_applied/, @activity.body
  end
  
  def test_should_log_edited_payment
    invoice = invoices(:paid_invoice)
    payment = payments(:payment_for_invoice_10)
    
    @activity = Activity.log_edit_payment!(invoice, payment)
    assert_equal @activity.invoice_id, invoice.id
    assert_match /payment_edited/, @activity.body
  end
  
  def test_should_log_deleted_payment
    invoice = invoices(:paid_invoice)
    payment = payments(:payment_for_invoice_10)
    
    @activity = Activity.log_delete_payment!(invoice, payment)
    assert_equal @activity.invoice_id, invoice.id
    assert_match /payment_deleted/, @activity.body
  end
  
end
