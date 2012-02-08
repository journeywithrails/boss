class LineItemsController < ApplicationController
  # GET /line_items
  # GET /line_items.xml
  prepend_before_filter CASClient::Frameworks::Rails::Filter 
  before_filter :find_invoice
  before_filter :biller_view
  def index
    @line_items = LineItem.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @line_items }
    end
  end

  # GET /line_items/1
  # GET /line_items/1.xml
  def show
    find_line_item

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @line_item }
    end
  end

  # GET /line_items/new
  # GET /line_items/new.xml
  def new
    @line_item = @invoice.line_items.build()

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @line_item }
      format.js   { self.create }
    end
  end

  # GET /line_items/1/edit
  def edit
    find_line_item
  end

  # POST /line_items
  # POST /line_items.xml
  def create
    @line_item = @invoice.line_items.build(:unit => @invoice.line_items.count+1)
    @line_item.attributes = params[:line_item]
    if params[:after]
      logger.debug "params :after branch"
      after = @invoice.line_items.find(params[:after])
    end

    respond_to do |format|
      if @line_item.save
        @line_item.insert_at(after.position+1) if after
        flash[:notice] = _('LineItem was successfully created.')
        format.html { redirect_to(invoice_line_item_url(:invoice_id => @invoice, :id => @line_item)) }
        format.xml  { render :xml => @line_item, :status => :created, :location => @line_item }
        format.js do
          @line_items = @invoice.line_items
          render :template => "line_items/update"
      end
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @line_item.errors, :status => :unprocessable_entity }
        format.js do
          @line_items = @invoice.line_items
          render :template => "line_items/update"
        end
      end
    end
  end

  # PUT /line_items/1
  # PUT /line_items/1.xml
  def update
    find_line_item

    respond_to do |format|
      if @line_item.update_attributes(params[:line_item])
        flash[:notice] = _('LineItem was successfully updated.')
        format.html { redirect_to(invoice_line_item_url(:invoice_id => @invoice, :id => @line_item)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @line_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /line_items/1
  # DELETE /line_items/1.xml
  def destroy
    find_line_item
    @line_item.destroy

    respond_to do |format|
      format.html { redirect_to(invoice_line_items_url(:invoice_id => @invoice)) }
      format.xml  { head :ok }
      format.js do
        @line_items = @invoice.line_items
        render :template => "line_items/update"
      end
    end
  end
  
  protected
  def find_invoice
    @invoice = current_user.invoices.find(params[:invoice_id])
  end
  
  def find_line_item
    @line_item = @invoice.line_items.find(params[:id])
  end
  
end
