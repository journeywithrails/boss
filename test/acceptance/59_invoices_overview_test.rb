
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/acceptance_test_helper'

# Test cases for User Story 59 - Invoices Overview

class InvoicesOverviewTest < Test::Unit::TestCase
  include AcceptanceTestSession
  # necessary to include invoices fixture so that invoice data is fresh for each test!
  fixtures :users, :invoices
  
  def setup
    @user = watir_session.with(:basic_user)
    @user.logs_in
    start_email_server
  end
  
  def teardown
    end_email_server
    @user.teardown
  end
  
  def test_can_click_to_view_invoice
    @user.displays_invoice_overview
    @user.expects_ajax(4,0)
    
    # click on the first invoice link 9 8 1 10
    @user.link(:id, 'past_due_invoices_grid-9-edit-link-1').click
    @user.b.wait
    assert @user.contains_text( "Invoice" ), "Expecting an invoice to be shown."
  end

  def test_can_attempt_to_send_invoice
    @user.displays_invoice_overview
    @user.expects_ajax(5,0)
    # get the link for sending invoice with id 3, the second row in the draft grid
    l = @user.link(:id, 'draft_invoices_grid-3-action-link') # xpath was ABOMINABLY slow, so I added ids
    l.click
    # expect the invoice cannot be sent because there are no line items
    Watir::Waiter.new(25).wait_until do
      @user.div(:id, "validation-errors").exists?
    end
    assert_match /invoice cannot be mailed because/, 
      @user.div(:id, "send-dialog-container").div(:id, 'validation-errors').text
  end

  def test_can_send_invoice_and_grid_updates
    
    # send the invoice with id 13, and expect it to move from Draft to Outstanding.
    @user.recalc_invoices
    @user.displays_invoice_overview
    
    @user.expects_ajax(5,0)
    assert_equal 'Past Due (1)', @user.div(:id, 'past_due_invoices_grid').span(:class, 'x-panel-header-text').text    
    assert_equal 'Outstanding (2)', @user.div(:id, 'outstanding_invoices_grid').span(:class, 'x-panel-header-text').text
    assert_equal 'Draft (16)', @user.div(:id, 'draft_invoices_grid').span(:class, 'x-panel-header-text').text
    @user.expects_ajax(1) do
      @user.div(:id, "draft_invoices_grid").button(:class, "x-btn-text x-tbar-page-next").click    
    end
    l = @user.link(:id, 'draft_invoices_grid-65-action-link') # xpath was ABOMINABLY slow, so I added ids
    @user.expects_ajax(1) do
      l.click
    end
    @user.populate(@user.text_field(:id, 'delivery_recipients'), "dontsend@test.com")
    @user.expects_ajax(6) do
      @user.div(:id, "send-dialog-container").button(:text, "Send").click
      @user.b.wait
    end
    assert_equal 'Draft (15)', @user.div(:id, 'draft_invoices_grid').span(:class, 'x-panel-header-text').text
    assert_equal 'Past Due (2)', @user.div(:id, 'past_due_invoices_grid').span(:class, 'x-panel-header-text').text
  end

  def test_data_present
    # check that the invoice data is present 
    
    @user.displays_invoice_overview
    @user.expects_ajax(5,0)
    
    grids = [
      { :meta_status => 'draft', :heading => 'Draft (num)', :div_id => 'draft_invoices_grid' },
      { :meta_status => 'past_due',  :heading => 'Past Due (num)', :div_id => 'past_due_invoices_grid' },
      { :meta_status => 'quote',  :heading => 'Quotes (num)', :div_id => 'quote_invoices_grid' },
      { :meta_status => 'outstanding',  :heading => 'Outstanding (num)', :div_id => 'outstanding_invoices_grid' },
      { :meta_status => 'paid',  :heading => 'Paid (num)', :div_id => 'paid_invoices_grid' }
    ]

    filters = OpenStruct.new()
    grids.each do |g|
    
      filters.conditions = Invoice.find_by_meta_status_conditions( g[:meta_status] )
      invoices = Invoice.filtered_invoices(users(:basic_user).invoices, filters)
      num_invoices = invoices.length
      
      # find exactly one grid heading
        expected_heading = g[:heading].gsub( /num/, num_invoices.to_s )
        headings_found = 0
        1.upto(@user.spans.length) do |s|
          if @user.spans[s].class_name.strip == 'x-panel-header-text'
            if expected_heading == @user.spans[s].text.strip
              headings_found = headings_found + 1
            end
          end
        end
       assert_equal 1, headings_found, "Expecting exactly one instance of heading '#{expected_heading}'."
        
      # find the grid div

        1.upto(@user.divs.length) do |d|
          if @user.divs[d].id == g[:div_id]
            
            # iterate through each invoice row and compare the data with the database
              grid_div = @user.divs[d] 
              rows_found = 0 
              1.upto(grid_div.divs.length) do |r|
                if grid_div.divs[r].class_name.strip =~ /invoice-row/
                  rows_found = rows_found + 1
                  row_div = grid_div.divs[r] 

                  # invoice no.
                    found_number = row_div.div(:class,/col-inv-unique/).text
                    assert_equal invoices[rows_found-1].unique.to_s, found_number, 
                      "Expecting the invoice number in row #{rows_found} of grid #{g[:meta_status]} to match the database."
                    
                  # date
                    found_date = row_div.div(:class,/inv-date/).text 
                    if !found_date.blank? 
                      found_date = Date.parse( found_date )
                    else
                      found_date = ""
                    end
                    database_date = invoices[rows_found-1].date.to_s
                    if !database_date.blank? then
                      database_date = Date.parse( database_date )
                    else
                      database_date = ""
                    end
                    assert_equal database_date, found_date 
                      "Expecting the date in row #{rows_found} of grid #{g[:meta_status]} to match the database."
                    
                  # customer
                    found_customer = row_div.div(:class,/cust-name/).text
                    if invoices[rows_found-1].customer then
                      database_customer = invoices[rows_found-1].customer.name
                    else
                      database_customer = ""
                    end
                    assert_equal database_customer, found_customer,
                      "Expecting the customer in row #{rows_found} of grid #{g[:meta_status]} to match the database."
                    
                  # total
                    found_total = row_div.div(:class,/col-3/).text
                    assert_equal invoices[rows_found-1].total_amount, BigDecimal.new(found_total), 
                    "Expecting the total in row #{rows_found} of grid #{g[:meta_status]} to match the database."
                    
                  # due
                    found_due = row_div.div(:class,/col-4/).text
                    assert_equal invoices[rows_found-1].amount_owing, BigDecimal.new(found_due), 
                    "Expecting the amount due in row #{rows_found} of grid #{g[:meta_status]} to match the database."
                  
                end
              end # finding invoice rows
              
              if g[:meta_status] == 'draft'
                assert_equal 10, rows_found, 
                  "Expecting to find 10 rows (max per page) for status #g[:meta_status]#"
              else
                assert_equal num_invoices, rows_found, 
                  "Expecting to find #num_invoices# rows for status #g[:meta_status]#"
              end
            
            break
          end
        end # finding grid div
      
    end
    
    # click on the next-page link, and expect just one row in the drafts grid.
      @user.expects_ajax(1) do
        @user.div(:id, 'draft_invoices_grid').button(:class, 'x-btn-text x-tbar-page-next').click
        @user.b.wait
      end
      # find the grid div and count each invoice row
        rows_found = 0 
        1.upto(@user.divs.length) do |d|
          if @user.divs[d].id == 'draft_invoices_grid'
            grid_div = @user.divs[d] 
            1.upto(grid_div.divs.length) do |r|
              if grid_div.divs[r].class_name.strip =~ /invoice-row/
                rows_found = rows_found + 1
              end
            end
          end
        end
      assert_equal 6, rows_found, "Expect 5 invoices on the second page of the drafts grid."
    
  end
  
  def test_escaped_data_on_ext_grid
    end_email_server

    @user = watir_session.with(:user_without_invoices)
    @user.logs_in

    start_email_server

    user = User.find(:first, :conditions => {:sage_username => "user_without_invoices"})
    inv = user.invoices.new
    inv.unique = "<b>bolded_unique</b>"
    inv.save!
    @user.displays_invoice_overview
    @user.b.wait
    html = @user.html.to_s.downcase
    deny html.include?("<b>bolded_unique</b>")
    if ::WatirBrowser.ie?
      assert html.include?("\\u003cb\\u003ebolded_unique\\u003c\/b\\u003e")
    else
      assert html.include?("&lt;b&gt;bolded_unique&lt;/b&gt;")
    end
  end
  
end


