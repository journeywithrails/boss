class RecurringInvoicesWorker < BackgrounDRb::MetaWorker
  set_worker_name :recurring_invoices_worker
  def create(args = nil)
  end
  
  def process_recurring_invoices
    logger.info "Processing recurring invoices..."
    Invoice.process_recurring_invoices
    logger.info "Processing recurring invoices complete."
  end
  
end

