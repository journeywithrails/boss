require File.dirname(__FILE__) + '/../test_helper'

class PayApplicationTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  fixtures :invoices
  
  def prepare
    @i = invoices(:unpaid_invoice_1)
    @p = Payment.new
    add_invoice
  end

  def test_should_have_no_errors_with_unique_invoice
    prepare
    @p.pay_applications.each do |pa| 
      assert pa.valid?
    end
  end

  def test_should_have_no_errors_with_unique_invoices
    prepare
    add_invoice(invoices(:unpaid_invoice_2))
    @p.pay_applications.each do |pa| 
      assert pa.valid?
    end
  end

  def test_should_validate_uniqueness_of_invoice
    prepare
    add_invoice
    @p.pay_applications.each do |pa| 
      assert !pa.valid?
    end
  end

  def test_should_not_be_valid_with_multiple_currencies
    prepare
    i = invoices(:unpaid_invoice_2)
    i.currency = 'RUBLES'
    add_invoice(i)
    @p.pay_applications.each do |pa| 
      assert !pa.valid?
    end
  end

  private

  def add_invoice(i = nil)
    @p.pay_applications.build(:payment => @p, :invoice => (i || @i), :amount => 10)
  end
end
