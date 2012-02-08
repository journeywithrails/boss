$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'
# Test cases for User Story 15
# Invoice terms on invoice details page


class TermsOnInvoiceDetailsTest < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :users
  fixtures :invoices
  fixtures :line_items
  
  def setup
    @basic_user = watir_session.with(:basic_user)
    @basic_user.logs_in
  end
  
  def teardown
    @basic_user.teardown
  end
 
  def test_valid_due_date_saves
    assert_difference 'Invoice.count', 1 do
      b = @basic_user.b
      @basic_user.creates_new_invoice
      b.text_field(:id, 'invoice_date').value=('2008-01-15')
      b.text_field(:id, 'invoice_due_date').value=('2008-01-16')
      b.text_field(:id, 'invoice_reference').value=('ref_15')
      b.text_field(:id, 'invoice_description').value=('desc_15')
      @basic_user.enter_new_customer( 
          :name => "Test 15 Customer"
      ) 

      @basic_user.populate(b.text_field(:id, 'invoice_line_items_attributes__description'), 'Item Desc 15')
      @basic_user.populate(b.text_field(:id, 'invoice_line_items_attributes__quantity'), '1')
      @basic_user.populate(b.text_field(:id, 'invoice_line_items_attributes__price'), '10.0')
      b.wait
      @basic_user.submits
    end    
  end
 
  def test_invalid_due_date_does_not_save
    assert_no_difference 'Invoice.count' do

      b = @basic_user.b
      @basic_user.creates_new_invoice
      b.text_field(:id, 'invoice_date').set('2008-01-15')
      b.text_field(:id, 'invoice_due_date').set('asdf')
      b.text_field(:id, 'invoice_reference').set('ref_15')
      b.text_field(:id, 'invoice_description').set('desc_15')
      @basic_user.enter_new_customer( 
          :name => "Test 15 Customer"
      ) 

      @basic_user.populate(b.text_field(:id, 'invoice_line_items_attributes__description'), 'Item Desc 15')
      @basic_user.populate(b.text_field(:id, 'invoice_line_items_attributes__quantity'), '1')
      @basic_user.populate(b.text_field(:id, 'invoice_line_items_attributes__price'), '10.0')
      b.wait
      @basic_user.submits
    end
  end
  
  def test_due_date_before_date_does_not_save
    assert_no_difference 'Invoice.count' do
      b = @basic_user.b
      @basic_user.creates_new_invoice
      @basic_user.populate(b.text_field(:id, 'invoice_date'), '2008-01-15')
      @basic_user.populate(b.text_field(:id, 'invoice_due_date'),'2008-01-14')
      @basic_user.populate(b.text_field(:id, 'invoice_reference'), 'ref_15')
      @basic_user.populate(b.text_field(:id, 'invoice_description'),'desc_15')
      @basic_user.enter_new_customer( 
          :name => "Test 15 Customer"
      ) 

      @basic_user.populate(b.text_field(:id, 'invoice_line_items_attributes__description'), 'Item Desc 15')
      @basic_user.populate(b.text_field(:id, 'invoice_line_items_attributes__quantity'), '1')
      @basic_user.populate(b.text_field(:id, 'invoice_line_items_attributes__price'), '10.0')
      b.wait
      @basic_user.submits
    end  
  end
  
  def test_correct_item_sorting_in_json_tables
    @basic_user.logs_out
    @user_without_invoices = watir_session.with(:user_without_invoices)
    #test 1 (main)
    @current_user = @user_without_invoices
    @current_user.logs_in
    start_email_server
    
    b = @current_user.b

    u = User.find(:first, :conditions => {:sage_username => "user_without_invoices"})
    complete_profile_for(u)
    u.profile.save!
    u.save!
    
    #overdue, will send
    @current_user.creates_new_invoice
    b.wait
    @current_user.populate(b.text_field(:id, 'invoice_date'), '2008-01-15')
    @current_user.populate(b.text_field(:id, 'invoice_due_date'), '2008-01-16')
    @current_user.populate(b.text_field(:id, 'invoice_reference'), 'ref_15')
    @current_user.populate(b.text_field(:id, 'invoice_description'), 'desc_15')
    @current_user.enter_new_customer( 
        :name => "Test 15 Customer 1"
    ) 

    @current_user.populate(b.text_field(:id, 'invoice_line_items_attributes__description'), 'Item Desc 15')
    @current_user.populate(b.text_field(:id, 'invoice_line_items_attributes__quantity'), '1')
    @current_user.populate(b.text_field(:id, 'invoice_line_items_attributes__price'), '10.0')
    b.wait
    @current_user.submits
    b.wait




    b.link(:id, 'show-send-dialog-btn').click
    @current_user.wait_until_exists "delivery_recipients"

    @current_user.populate(@current_user.text_field(:id, "delivery_recipients"), "test@billingboss.com")


    deliverable_id = @current_user.hidden(:id, "delivery_deliverable_id").value
    message_id = @current_user.wait_for_delivery_of(deliverable_id, "send invoice") do
      @current_user.element_by_xpath("id('send-dialog-send-button')").click # don't ask for button directly, because on firefox ext wraps button in a table, and the table gets the id not the button element
    end

    #not overdue, will send
    @current_user.creates_new_invoice
    b.wait
    @current_user.populate(b.text_field(:id, 'invoice_date'),'2008-01-15')
    @current_user.populate(b.text_field(:id, 'invoice_due_date'),'2058-01-16')
    @current_user.populate(b.text_field(:id, 'invoice_reference'),'ref_15')
    @current_user.populate(b.text_field(:id, 'invoice_description'),'desc_15')
    @current_user.enter_new_customer( 
        :name => "Test 15 Customer 2"
    ) 

    @current_user.populate(b.text_field(:id, 'invoice_line_items_attributes__description'),'Item Desc 15')
    @current_user.populate(b.text_field(:id, 'invoice_line_items_attributes__quantity'),'1')
    @current_user.populate(b.text_field(:id, 'invoice_line_items_attributes__price'),'10.0')
    b.wait
    @current_user.submits
    b.wait
    b.link(:id, 'show-send-dialog-btn').click
    b.link(:id, 'show-send-dialog-btn').click
    Watir::Waiter.new(12).wait_until do
      b.text_field(:id, "delivery_recipients").exists?
    end
    @current_user.populate(b.text_field(:id, 'delivery_recipients'),"autotest@10.152.17.65")

    deliverable_id = @current_user.hidden(:id, "delivery_deliverable_id").value
    @current_user.wait_for_delivery_of(deliverable_id, "send invoice") do    
      @current_user.element_by_xpath("id('send-dialog-send-button')").click # don't ask for button directly, because on firefox ext wraps button in a table, and the table gets the id not the button element
    end
    
    #overdue, will not send
    b = @current_user.b
    @current_user.creates_new_invoice
    b.wait
    @current_user.populate(b.text_field(:id, 'invoice_date'),'2008-01-15')
    @current_user.populate(b.text_field(:id, 'invoice_due_date'),'2008-01-16')
    @current_user.populate(b.text_field(:id, 'invoice_reference'),'ref_15')
    @current_user.populate(b.text_field(:id, 'invoice_description'),'desc_15')
    @current_user.enter_new_customer( 
        :name => "Test 15 Customer 3"
    ) 

    @current_user.populate(b.text_field(:id, 'invoice_line_items_attributes__description'),'Item Desc 15')
    @current_user.populate(b.text_field(:id, 'invoice_line_items_attributes__quantity'),'1')
    @current_user.populate(b.text_field(:id, 'invoice_line_items_attributes__price'),'10.0')
    b.wait
    @current_user.submits
    b.wait
    sleep 2

    
    test_array = [1, 2, 3]      
    #control array for test 1
    ca1 = ["1", 1, 0, 0, 0]
    ca2 = ["2", 0, 1, 0, 0]
    ca3 = ["3", 0, 0, 1, 0]
    ca = [ca1, ca2, ca3]
    
    result_arrays = helper_json_counter(:user_without_invoices, test_array )
    
    assert_equal ca, result_arrays, "JSON table row data does not match test 1"
    
    #test 2, without creating customers and instead testing json multipage grids
    @current_user.logs_out
    @basic_user.logs_in
    @current_user = @basic_user

    #test array for test 2
    test_array = [16, 64, 17]
    
    #control array for test 2
    ca1 = ["1", 1, 0, 0, 0]
    ca2 = ["3", 0, 0, 1, 0]
    ca3 = ["4", 0, 0, 0, 1]
    ca = [ca1, ca2, ca3]
     
    
    result_arrays = helper_json_counter(:basic_user, test_array )
    
    assert_equal ca, result_arrays, "JSON table row data does not match test 2"
    
    end_email_server
  end

  #Checks each of the JSON rows for presence of a given array of invoice unique
  #id's returns a 2-d array of form [x,x,x] where each x is itself an array of 
  #form [string, int, int, int, int] where the ints count the 
  #number of occurences of the invoice unique id in that grid.
  #Value of string will be:
  #"0": Zero matches in any of the rows
  #number "X": Match found in exactly one table, table number X
  #"DD": Duplicate value in different tables
  #"DS": Duplicate value in same table
  #TODO: When you have time, export this into a test suite helper
  def helper_json_counter(user_id, the_invoice_unique)
    
    b = @current_user.b
    
    @current_user.displays_invoice_overview
    @current_user.expects_ajax(4,0)
    
    #If there are additional grids added later, all you need to do is 
    #add the new grid hash set to this array and rest of code should work as is 
    grids = [
      { :meta_status => 'past_due',  :heading => 'Past Due (num)', :div_id => 'past_due_invoices_grid' },
      { :meta_status => 'outstanding',  :heading => 'Outstanding (num)', :div_id => 'outstanding_invoices_grid' },
      { :meta_status => 'draft', :heading => 'Draft (num)', :div_id => 'draft_invoices_grid' },      
      { :meta_status => 'paid',  :heading => 'Paid (num)', :div_id => 'paid_invoices_grid' }
      ]
      
      result_arrays = Array.new(the_invoice_unique.length){
        ["U"] + Array.new(grids.length, 0)}

    #first loop for each grid
    grids.each_with_index do |g, current_grid|
      b.wait
      if b.div(:id, g[:div_id]).div(:class, "x-toolbar x-small-editor").exists?
        page_text = b.div(:id, g[:div_id]).div(:class, "x-toolbar x-small-editor").span(:text, /of /).text
        total_pages = page_text[(page_text.length-1), 1].to_i        
      else
        total_pages = 1
      end

      if total_pages < 1
        total_pages = 1
      end
        
      #second loop for each grid page
      i = 1
      i.upto(total_pages) do
        
        #third loop for each item on a grid page
        # find the grid div
        1.upto(@current_user.divs.length) do |d|

          if @current_user.divs[d].id == g[:div_id]

            # iterate through each invoice row and compare the data with the database
            grid_div = @current_user.divs[d] 
            rows_found = 0 
            1.upto(grid_div.divs.length) do |r|

              if grid_div.divs[r].class_name.strip =~ /invoice-row/

                rows_found = rows_found + 1
                row_div = grid_div.divs[r] 
                  
                # invoice no.
                found_number = row_div.div(:class,/col-inv-unique/).text

                # puts "#{g[:div_id]} row #{rows_found} -- id: #{found_number}"
                #if found_number.to_s == the_invoice_unique.to_s
                #  result_array[current_grid] += 1
                #end
                
                the_invoice_unique.each_with_index do | the_invoice, verify_counter |
                  if found_number.to_s == the_invoice.to_s
                    begin 
                      result_arrays[verify_counter][current_grid+1] += 1
                    rescue

                    end
                  end
                end
                
                
              end 
            end     
          end 
        end
        #end third loop

        #cycle page code
        if i < total_pages
          b.div(:id, g[:div_id]).button(:class, 'x-btn-text x-tbar-page-next').click
          b.wait
        end
      end #second loop
    end #outer loop
    
    b.wait
    
    final_arrays = helper_result_array_validator(result_arrays)
    final_arrays
 
  end #def
  
  def helper_result_array_validator(the_result_arrays)
  
  result_arrays = the_result_arrays
  result_arrays.each do |result_array|
      trigger = false
      result_array.each_with_index do |element, index|
      next if index==0
      #1.upto(result_array.length-1) do
        if not [0, 1].include? element
          result_array[0] = "DS"
        else
          if ((element == 1) and (result_array[0] == "U"))
            if trigger == false
              result_array[0] = index.to_s
              trigger = true
            else
              result_array[0] = "DD"
            end
          end
        end
      end #individual array (part 1 of 2)
      if result_array[0] == "U"
        result_array[0] = "0"
      end #individual array (part 2 of 2)

      #sleep 1
    end #all arrays
    return result_arrays
  end #def
  
    def complete_profile_for(user)
      user.profile.company_name = "Company Name"
      user.profile.company_address1 = "Address 1"
      user.profile.company_city = "Vancouver"
      user.profile.company_country = "Canada"
      user.profile.company_state = "British Columbia"
      user.profile.company_postalcode = "V1V 1V1"
      user.profile.company_phone = "123 456 7890"
      return user
    end
  
end #class