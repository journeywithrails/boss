# A PayApplication is a portion of a single payment that is
# applied to an invoice.  This is because a payment may cover
# more than one invoice.
class PayApplication < ActiveRecord::Base
  belongs_to :invoice
  belongs_to :payment
  validates_presence_of :payment, :amount
  validates_uniqueness_of :invoice_id, :scope => :payment_id
  validate :invoice_is_not_included_twice
  validate :same_currency_as_other_invoices_in_payment

  def invoice_is_not_included_twice
    return if not invoice
    with_this_inv = payment.pay_applications.select { |pa| pa.invoice == invoice }
    if with_this_inv.length > 1
      errors.add('invoice', 'can not be paid twice on the same payment')
    end
  end

  def same_currency_as_other_invoices_in_payment
    if payment.pay_applications.any? { |pa| pa.invoice.currency != invoice.currency }
      errors.add('', 'Can apply a payment to two invoices with different currencies')
    end
  end
end
