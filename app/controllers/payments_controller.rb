class PaymentsController < ::ApplicationController
  prepend_before_filter CASClient::Frameworks::Rails::Filter, :except => [:direct, :confirm, :complete, :cancel, :submit]
  before_filter :find_parent
    before_filter :validate_created_by_id

  include Sage::BusinessLogic::Exception
  layout :external_layout

  # GET /invoices/:invoice_id/payments
  # GET /payments
  # GET /payments.xml
  def index
      redirect_to "/" #global payments overview not yet implemented. we may make a proper report later
  end

  # GET /invoices/:invoice_id/payments/1
  # GET /payments/1
  # GET /payments/1.xml)
  def show
      redirect_to "/" #show screen not used for app
  end

  # GET /invoices/:invoice_id/payments/new
  # GET /payments/new
  # GET /payments/new.xml

  def new
    @payment = Payment.new
    @payment.prepare_default_fields
    find_customer(true)
    find_invoice(true)
    respond_to do |format|
      format.html do
        render_with_mobile_support(:layout => internal_layout, :mobile_layout => 'mobile', :action => "new")
      end
      format.xml  { render :xml => @payment }
    end
  end

  # GET /invoices/:invoice_id/payments/1/edit
  # GET /payments/1/edit
  def edit
    @payment ||= @parent.payments.find(params[:id])
    find_customer(true)
    find_invoice(true)
    respond_to do |format|
      format.html do
        render_with_mobile_support(:layout => internal_layout, :mobile_layout => 'mobile', :action => "edit")
      end
    end
  end

  # POST /payments
  # POST /payments.xml
  def create
    sanitize_params

    #can't use @parent here because the association doesn't exist yet.
    if !params[:payment][:pay_type].blank?
      raise Sage::BusinessLogic::Exception::IncorrectDataException if !Payment::PayByManual.include?(params[:payment][:pay_type])
    end
    @payment = current_user.payments.build(params[:payment])
    find_customer(true)
    find_invoice(true)
    render_with_mobile_support(:layout => internal_layout, :mobile_layout => 'mobile', :action => "new") and return unless validate_payment_amount
    begin
      if @invoice.markable_as_sent? && @invoice.meta_status == Invoice::META_STATUS_DRAFT
        @invoice.mark_sent_without_sending!
      end
      respond_to do |format|
        @payment.save_and_apply(@invoice)
        Activity.log_payment!(@invoice,@payment)
        flash[:notice] = _('Payment was successfully recorded.')
        format.html do
          if @invoice.nil?
            redirect_to(payment_url(@payment))
          else
            redirect_to(invoice_url(@invoice))
          end
        end
      end
    rescue CantPerformEventException, PaymentInProgressException => e
      if e.is_a? PaymentInProgressException
        flash[:notice] = _('This invoice has a payment in progress. Please wait a moment and try again.')
      else
        flash[:notice ] = e.message
      end
      respond_to do |format|
        format.html { render_with_mobile_support(:layout => internal_layout, :mobile_layout => 'mobile', :action => "new")}
        format.xml  { render :xml => @payment, :status => :cancelled, :location => @payment }
      end
    rescue => e
      log_error(e)
      respond_to do |format|
        format.html { render_with_mobile_support(:layout => internal_layout, :mobile_layout => 'mobile', :action => "new") }
        format.xml  { render :xml => @payment.errors.to_xml }
      end
    end

  end

  # PUT /payments/1
  # PUT /payments/1.xml
  def update
    raise Sage::BusinessLogic::Exception::IncorrectDataException if params[:payment][:pay_type] && !Payment::PayByManual.include?(params[:payment][:pay_type])
    @payment = @parent.payments.find(params[:id])
    sanitize_params

    find_customer(true)
    find_invoice(true)

    # payments can only be changed under certain circumstances
    # -- that should be enforced through state and validations (dw 2008-5-4)

    render_with_mobile_support(:layout => internal_layout, :mobile_layout => 'mobile', :action => "edit") and return unless validate_payment_amount

    @payment.update_attributes(params[:payment])
    begin
      @payment.save_and_apply(@invoice)
      @invoice.reload
      @invoice.cancel_payment! if @invoice.amount_owing > 0
      @invoice.save!
      Activity.log_edit_payment!(@invoice, @payment)
      respond_to do |format|
        flash[:notice] = _('Payment was successfully recorded.')
        format.html { redirect_to(invoice_url(@invoice)) }
        format.xml  { head :ok }
      end
    rescue => e
      log_error(e)
      respond_to do |format|
        format.html { render_with_mobile_support(:layout => internal_layout, :mobile_layout => 'mobile', :action => "new") }
        format.xml  { render :xml => @payment.errors.to_xml }
        #format.xml  { render :xml => @payment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /payments/1
  # DELETE /payments/1.xml
  def destroy

    @payment = @parent.payments.find(params[:id])
    find_customer(true)
    find_invoice(true)
    Activity.log_delete_payment!(@invoice, @payment)
    @payment.destroy
    @invoice.reload
    @invoice.cancel_payment!    
    #recalculate to reflect cached amounts such as amount owing, paid.
    @invoice.calculate_discounted_total
    @invoice.save!
    flash[:notice] = _('Payment deleted.')
    respond_to do |format|
      format.html { redirect_to(invoice_url(@invoice)) } # payments_url(:invoice_id=>@invoice.id)
      format.xml  { head :ok }
    end
  end

  def validate_created_by_id
    if params[:payment] && params[:payment][:created_by_id]
      raise Error, "created_by_id is not that of current user" unless (params[:payment][:created_by_id].to_s == current_user.id.to_s)
    end
  end

  protected
  def sanitize_params
    remove_commas_and_spaces(params[:payment][:amount])
  end

  def validate_payment_amount
    #the interface doesn't support applying a payment to multiple invoices
    #but the db does. for now we use the controller to disallow payment amounts greater
    #than the invoice amount due.
    
    if !params[:payment][:amount] ||
        (BigDecimal.new(params[:payment][:amount].to_s) == BigDecimal.new('0'))
      flash[:warning] = _('Submitted payment amount must be greater than zero.')
      return false
    end
    if BigDecimal.new(params[:payment][:amount].to_s) >
        (@invoice.amount_owing + (@payment.new_record? ? BigDecimal.new('0') : @payment.amount))
      flash[:warning] = _('Submitted payment amount is greater than the invoice amount owing.')
      return false
    else
      return true
    end
  end

  def find_parent
    find_invoice
    @nested = !@invoice.nil?
    @parent = @invoice || current_user
  end

  def find_invoice(force=false)
    invoice_id = params[:payment]['invoice_id'] unless (params[:payment].nil? or params[:payment]['invoice_id'].blank?)
    invoice_id ||= params['invoice_id'] unless params['invoice_id'].blank?

    if (@invoice.nil? and !invoice_id.nil? and logged_in?)
      @invoice = current_user.invoices.find(invoice_id)
    end
    if @invoice.nil? && params[:id]
      @invoice = current_user.payments.find(params[:id]).pay_applications[0].invoice
    end

    raise Exception, "Recording a payment without an invoice has been disabled" if force && @invoice.blank?
  end

  def find_customer(force=false)
    if (@customer.nil?)
      @customer = current_user.customers.find(params['customer_id']) unless (params['customer_id'].blank?)
    end
    if (@customer.nil? and !@payment.nil?)
      @customer = @payment.customer
    end
    if (@customer.nil? and !@invoice.nil?)
      @customer = @invoice.customer
    end
    raise Exception, "Customer does not belong to user" if @customer && !current_user.customers.include?(@customer)
    raise Exception, "Can't find customer to record payment for" if force && @customer.blank?
  end

end
