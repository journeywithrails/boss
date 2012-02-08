
class ReportsController < ApplicationController
  prepend_before_filter CASClient::Frameworks::Rails::Filter    
  before_filter :set_up 
  #before_filter :bookkeeper_required
  before_filter :find_parent  # , :only => 'show' 
  def index
    
  end
  
  def print
    
    @tax_1 = 0
    @tax_2 = 0
    @subtotal_amount = 0
    @discount_amount = 0
    @total_amount = 0
    @paid_amount = 0
    @owing_amount = 0
    
    @amount = 0
    
    @skip_header = true
    @skip_footer = true
    
    case params[:id]
    when 'invoice'
      split_multi_params(params[:filters], :customers, :fromdate, :todate, :currency)
      setup_search_filters(@filter_name, :page_size => nil, :current => nil, :parent => @parent)    
      @filters.exclude << "quote"
      
      @invoices = Invoice.filtered_invoices(@parent.invoices, @filters) 
      render :template => 'reports/invoice_print'
    when "payment"
      split_multi_params(params[:filters], :customers, :fromdate, :todate, :currency)
      setup_search_filters(@filter_name, :page_size => nil, :current => nil, :parent => @parent)    


      @payments = Payment.filtered_payments(@parent.payments, @filters)
      render :template => 'reports/payment_print'
    else
      raise Exception, "Don't know about a #{params[:id]} report"
    end
    

  end
  
  def show
    case params[:id]
    when 'invoice'
      respond_to do |format|
        format.html do
          @currencies = @parent.invoices.map(&:currency).uniq
          @statuses = ([[s_("dropdown|– All Statuses –"), Invoice::META_STATUS_NONE.to_s]] + @parent.invoices.map {|i| [i.brief_meta_status_string, i.meta_status.to_s]}.uniq.reject{|i| i[1] == "5"})
          
          split_multi_params(params[:filters], :customers, :fromdate, :todate)
          setup_search_filters(@filter_name, :page_size => ::AppConfig.pagination.invoices.page_size, :current => nil, :parent => @parent)
          render :template => 'reports/invoice'
        end
        format.js do
          invoice_data
        end
        format.json do
          invoice_data
        end
        
        format.csv do
          
          setup_search_filters(@filter_name, :page_size => nil, :current => nil, :parent => @parent)
          @filters.exclude << "quote"
          @invoices, @summary = Invoice.filtered_invoices(@parent.invoices, @filters, true)          
          stream_csv do |csv|
            csv << [_("Invoice \#"), _("Customer"), _("Reference \#"), _("Date"), _("Tax 1"), _("Tax 2"), _("Discount"), _("Subtotal"), _("Total"), _("Paid"), _("Owed")]
            @invoices.each do |i|
              csv << [i.unique, i.customer_name, i.reference, i.date, format_amount(i.tax_1_amount), format_amount(i.tax_2_amount), format_amount(i.discount_amount), format_amount(i.subtotal_amount), format_amount(i.total_amount), format_amount(i.paid_amount), format_amount(i.owing_amount)]
            end
            csv << [_("Grand totals:"), "", "", "", format_amount(@summary['tax_1_amount']), format_amount(@summary['tax_2_amount']), format_amount(@summary['discount_amount']), format_amount(@summary['subtotal_amount']), format_amount(@summary['total_amount']), format_amount(@summary['paid_amount']), format_amount(@summary['owing_amount'])]
          end
        end
      end
    when 'payment'
      respond_to do |format|
        format.html do
          @currencies = @parent.payments.map {|p| p.invoices.map(&:currency)}.uniq.flatten
          split_multi_params(params[:filters], :customers, :statuses, :fromdate, :todate)
          setup_search_filters(@filter_name, :page_size => ::AppConfig.pagination.payments.page_size, :current => nil, :parent => @parent)

          render :template => 'reports/payment'
        end
        format.js do
          payment_data
        end
        format.json do
          payment_data
        end
        
        format.csv do
          
          setup_search_filters(@filter_name, :page_size => nil, :current => nil, :parent => @parent)
          @payments, @summary = Payment.filtered_payments(@parent.payments, @filters, true)
          stream_csv do |csv|
            csv << [_("Customer"), _("Invoice \#"), _("Invoice Amount"), _("Payment Type"), _("Payment Amount"), _("Date")]
            @payments.each do |p|
              csv << [p.customer_name, p.invoice_no, format_amount(p.invoice_full_amount), p.pay_type, format_amount(p.amount), p.date]
            end
            csv << [_("Grand totals:"), "", "", format_amount(@summary['amount']), ""]
          end
        end
      end
    when ''
      #show the report list page
    else
      raise Exception, "Don't know about a #{params[:id]} report"
    end
  end

  private
  def set_up
    @page_id = 'Reports'
  end
  
  def invoice_data
    report = InvoiceReport.new
    sort_col = (params[:sort] || 'id')
    sort_dir = (params[:dir] || 'ASC')
    sort_col = case sort_col
               when 'customer_name' then 'customers.name'
               when 'unique' then "invoices.unique_number #{sort_dir}, invoices.unique_name"
               else "invoices.#{sort_col}"
               end

    start = params[:start].to_i
    size = params[:limit].to_i
    size = 20 unless size > 0
    
    page = ((start/size).to_i)+1

    split_multi_params(params[:filters], :customers, :fromdate, :todate)

    setup_search_filters(@filter_name, :page_size => size, :current => page, :parent => @parent)
    
    if @filters.currency.blank?
      @filters.currency = @parent.invoices.first_fallback.currency unless @parent.invoices.first_fallback.nil?
    end

    @filters.conditions = Invoice.find_by_meta_status_conditions(meta_status_from_str(@filters.meta_status)) unless meta_status_from_str(@filters.meta_status) == Invoice::META_STATUS_NONE
    
    @filters.options = {:order=>sort_col+' '+sort_dir,
                        :include => [:pay_applications, :customer, :line_items]}
                        
    @filters.exclude << "quote"
    @filters.exclude << "recurring"
    
    @json = Invoice.filtered_invoices_with_summary_as_json(@parent.invoices, @filters, report.json_params)
    
    @json = globalize_for_ext(@json)

    render :text=>@json, :layout=>false
  end
  
  def payment_data
    report = PaymentReport.new
    sort_col = (params[:sort] || 'id')
    sort_dir = (params[:dir] || 'ASC')
    sort_col = case sort_col
               when 'customer_name' then 'customers.name'
               else "payments.#{sort_col}"
               end
               
    start = params[:start].to_i
    size = params[:limit].to_i
    size = 20 unless size > 0
    
    page = ((start/size).to_i)+1
    
    split_multi_params(params[:filters], :customers, :statuses, :fromdate, :todate)
    
    setup_search_filters(@filter_name, :page_size => size, :current => page, :parent => @parent)

    if @filters.currency.blank?
      @filters.currency = @parent.payments.first_fallback_currency unless @parent.payments.first_fallback_currency.blank?
    end
    
    @filters.options = {:order=>sort_col+' '+sort_dir,
                        :include => [:customer]}
    
    @json = Payment.filtered_payments_with_summary_as_json(@parent.payments, @filters, report.json_params)

    @json = globalize_for_ext(@json)
    
    render :text=>@json, :layout=>false
  end
  
protected
  def find_parent
    find_bookkeeper_client
    @nested = !@client.nil?
    if !@nested
      @parent = current_user
      @filter_name = "#{params[:id]}_report".to_sym
    else
      @parent = @client.user
      @filter_name = "client_#{@client.id}_#{params[:id]}_report".to_sym
    end
  end
  
  def find_bookkeeper_client
    @bookkeeper = current_user.bookkeeper
    @client = @bookkeeper.bookkeeping_clients.find(params[:bookkeeping_client_id]) unless (@bookkeeper.nil? or params[:bookkeeping_client_id].blank?)
  end    


  class MyNumberHelper
    include ActionView::Helpers::NumberHelper
  end
  
  def format_amount(amount)
    my_helper = MyNumberHelper.new    
    my_helper.number_to_currency(amount, {:precision => 2, :unit=> "", :separator => ".", :delimiter => ","} )
  end


end
