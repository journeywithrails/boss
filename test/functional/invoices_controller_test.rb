require File.dirname(__FILE__) + '/../test_helper'
require 'invoices_controller'


# Re-raise errors caught by the controller.
class InvoicesController; def rescue_action(e) raise e end; end

class InvoicesControllerTest < Test::Unit::TestCase
  fixtures :invoices
  fixtures :users
  fixtures :line_items
  fixtures :customers
  fixtures :invoice_files  
  fixtures :taxes
  include Arts
  include InvoicesHelper

  def setup
    @controller = InvoicesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as :basic_user
    @user = users(:basic_user)
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    
  end
  
  def teardown
    $log_on = false
  end
  
  def test_should_require_login_to_view_invoices
    logout
    get :index
    assert_redirected_to 'access/denied' #
  end

  ################   CRUD ###########################
  
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:invoices)
  end

  def test_should_get_new
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :new
    assert_response :success
    assert @response.body.include?("Invoices without a customer cannot be sent")
    assert @response.body.include?("Invoices must have at least one line item with positive price and quantity before they can be sent.")
  end

  def test_should_log_created
    assert_difference('Activity.count') do
      post :create, :invoice => { }
    end
  end
  
  def test_should_create_invoice
    assert_difference('Invoice.count') do
      post :create, :invoice => { }
    end
    
    assert_redirected_to invoice_path(assigns(:invoice))
  end

  def test_should_log_viewed
     logout
     invoice = invoices(:sent_invoice)
     ak = invoice.access_keys.create
     assert_difference('Activity.count',+1) do
       get :display_invoice, :id => ak.key
     end
  end

  def test_should_not_log_viewed_if_access_key_not_tracked_and_not_loged_in
    logout
    invoice = invoices(:sent_invoice)  
    invoice.save
    ak = invoice.access_keys.create
    ak.not_tracked = true
    ak.save
    assert_no_difference('Activity.count') do
      get :display_invoice, :id => ak.key
    end
  end

  def test_should_not_log_viewed_if_current_user_is_owner
    invoice = invoices(:sent_invoice)
    invoice.created_by = @user
    invoice.save
    ak = invoice.access_keys.create
    assert_no_difference('Activity.count') do
      get :display_invoice, :id => ak.key
    end
  end

  def test_should_log_viewed_if_current_user_is_not_owner
    invoice = invoices(:sent_invoice)
    invoice.created_by = users(:complete_user)
    invoice.save
    ak = invoice.access_keys.create
    assert_difference('Activity.count') do
      get :display_invoice, :id => ak.key
    end
  end
  
  def test_should_show_invoice
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :show, :id => invoices(:invoice_with_no_customer).id
    assert_response :success
  end

  def test_should_show_invoice_with_valid_template
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    template_list = get_template_list_name()
    template_list.each do |t|
      get :show, :id => invoices(:invoice_with_line_items).id, :template => t[0]
      assert_response :success
    end
  end

  #testing if invalid template parameter is passed in, the page is still rendered
  def test_should_show_invoice_with_evil_template_name
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :show, :id => invoices(:invoice_with_line_items).id, :template => 'xIAMBADTEMPLATE'
    assert_response :success

    get :show, :id => invoices(:invoice_with_line_items).id, :template => 'xIAMLONGddddTEMPLATxxxxxxxxxxxxxxxxxxxxxxxxxxxxxsssssssssssssssssssssssssssssssssssE'
    assert_response :success
    get :show, :id => invoices(:invoice_with_line_items).id, :template => "<script> alert('dd'); </script>"
    assert_response :success
  end

  def test_should_show_localized_invoice_date
    @controller.stubs(:init_gettext).returns(true)
    GettextLocalize.set_locale("fr")
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :show, :id => invoices(:invoice_with_no_customer)

    assert_match /02 Avril 2007/,  @response.body
  end

  # def test_should_correctly_set_language_when_displaying_invoice
  #   # set_cookie
  #   @request.cookies['lang'] = CGI::Cookie.new('lang', 'fr')
  #
  #   get :display_invoice, :id => "265310dd9d5b461f8fd9c7e5d96ab510"
  #
  #   assert @request.cookies['lang']
  #
  #   assert_equal "fr", locale.language
  # end

  def test_should_get_edit
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :edit, :id => invoices(:invoice_with_no_customer).id
    assert_response :success
    assert @response.body.include?("Invoices without a customer cannot be sent")

  end

  def test_should_update_invoice
    put :update, :id => invoices(:invoice_with_no_customer).id, :invoice => { :unique => 98765 }
    assert_redirected_to invoice_path(assigns(:invoice))
  end

  def test_should_destroy_invoice
    assert_difference('Invoice.count', -1) do
      delete :destroy, :id => invoices(:invoice_with_no_customer).id
    end

    assert_redirected_to '/invoices/overview'
  end

  def test_total_shouldnt_change_after_profile_tax_on_tax_setting_is_edited
    @controller.stubs(:form_authenticity_token).returns('aaaa')    
    login_as :complete_user

    Profile.any_instance.stubs(:tax_1_in_taxable_amount).returns(false)

    post :create, :invoice => {
        :currency => "USD",
        :tax_1_enabled => 1,
        :tax_1_rate => 5,
        :tax_2_enabled => 1,
        :tax_2_rate => 7.5,
        :discount_type => "amount",
        :discount_value => "0",
        :description => "test invoice",
        :line_items_attributes => [
          {:quantity => 1, :price => 1278, :row_id => "line_item_new_1", :should_destroy => 0, :tax_1_enabled => "1", :tax_2_enabled => "1"}
        ]
      }

    i =  Invoice.find(:first, :conditions => {:description => "test invoice"})

    Profile.any_instance.stubs(:tax_1_in_taxable_amount).returns(true)
    put :update, :id => i.id, :invoice => { :tax_2_enabled => 1 }

    i2 =  Invoice.find i.id
    assert_equal i.total_amount, i2.total_amount
  end
  
  ##############  User Story 7 ####################################
  
  def test_should_create_invoice_and_assign_existing_customer_and_contact
    assert_difference('Invoice.count') do
      post :create, :invoice => {:description => 'test_create_invoice_and_assign_existing_customer_and_contact',
        :contact_id => contacts(:basic_contact).id,
        :customer_id => customers(:customer_with_contacts).id
      }
    end
    
    assert_redirected_to invoice_path(assigns(:invoice))    
    invoice = assigns(:invoice)
    assert_equal 'test_create_invoice_and_assign_existing_customer_and_contact', invoice.description, 'should save the right invoice'
    assert_equal customers(:customer_with_contacts), invoice.customer, "newly created invoice should have bobs_company as customer"
    assert_equal contacts(:basic_contact), invoice.contact, "newly created invoice should have bob as contact"
  end
  
  def test_create_invoice_and_on_the_fly_customer
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    assert_no_difference('Contact.count') do
      assert_difference('Customer.count') do
        assert_difference('Invoice.count') do
          post :create, :invoice => {
            :description => 'test_create_invoice_and_on_the_fly_customer invoice',
            :customer_attributes => {:name => 'on-the-fly customer'}
          }
          assert_not_nil assigns(:invoice)
          assert_redirected_to invoice_path(assigns(:invoice))
        end
      end
    end
    
    invoice = assigns(:invoice)
    assert_equal 'on-the-fly customer', invoice.customer.name, 'customer params should be passed to the new customer'

  end
  
  def test_should_create_invoice_and_on_the_fly_customer_with_on_the_fly_contact      
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    assert_difference('Contact.count') do
      assert_difference('Customer.count') do
        assert_difference('Invoice.count') do
          post :create, :invoice => {
            :description => 'test_create_invoice_and_on_the_fly_customer_with_on_the_fly_contact',
            :customer_attributes => {
              :name => 'on-the-fly customer with on_the_fly contact',
              :contacts_attributes => [{
                :first_name => 'on-the-fly contact first name',
                :last_name => 'on-the-fly contact last name',
                :email => 'on-the-fly@valid.com'
              }]
            }
          }
        end
      end
    end

    invoice = assigns(:invoice)
    assert_equal 'on-the-fly customer with on_the_fly contact', invoice.customer.name, 'customer params should be passed to the new customer'
    assert_equal 'on-the-fly contact first name', invoice.customer.contacts.first.first_name, 'contact params should be passed to the new contact'
    assert_equal invoice.customer.contacts.first, invoice.contact, "invoice contact should equal new customer contact"

  end

  def test_should_create_invoice_with_existing_customer_with_on_the_fly_contact
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    assert_difference('Contact.count') do
      assert_no_difference('Customer.count') do
        assert_difference('Invoice.count') do
          post :create, :invoice => {
            :description => 'test_create_invoice_and_existing_customer_with_on_the_fly_contact',
            :customer_id => customers(:customer_with_contacts).id,
            :contact_attributes => {
              :first_name => 'on-the-fly contact first name',
              :last_name => 'on-the-fly contact last name',
              :email => 'on-the-fly@valid.com'
            }
          }
        end
      end
    end

    invoice = assigns(:invoice)
    assert_equal customers(:customer_with_contacts), invoice.customer, 'should assign existing customer to invoice'
    assert_equal 'on-the-fly contact first name', invoice.contact.first_name, 'contact params should be passed to the new contact'
    assert_not_nil invoice.customer.contacts.find(invoice.contact.id), 'customer should contain newly created contact'

  end

  ##################### Create Invoice with LineItems (User Story 8) ############################

  # Quotes
  
  def test_should_get_new_quote
    get :new, :is_quote => "1"
    assert_response :success
  end

  def test_should_create_quote_with_existing_customer
    assert_difference('Invoice.count') do
      post :create, :invoice => {
        :description => 'test_should_create_quote_with_existing_customer',
        :customer_id => customers(:customer_with_contacts).id
      }, :is_quote => "1"
    end
    invoice = assigns(:invoice)
    assert_equal invoice.status, "quote_draft"
  end

  def test_should_convert_quote_into_invoice
    invoice = invoices(:quote)
    get :convert_quote, :id => invoice.id
    invoice = assigns(:invoice)
    assert_equal invoice.status, "draft"
  end

  def test_new_quote_should_use_separate_numbering
    previous_quote = Invoice.create(:created_by=>@user) and previous_quote.save_quote!
    previous_quote.unique = 2345678
    previous_quote.save!

    previous_invoice = Invoice.create(:created_by=>@user)
    previous_invoice.unique = 1234567
    previous_invoice.save!

    get :new, :is_quote=>1
    assert_equal 2345678+1, assigns(:invoice).unique.to_i, "quote should have received number after previous quote"

    get :create, :is_quote=>"1", :invoice => {}
    assert_equal 2345678+1, assigns(:invoice).unique.to_i, "quote should have received number after previous quote"
  end

  def test_quote_should_be_created_with_custom_number
    get :create, :is_quote=>"1", :invoice => {:unique => 7654321 }
    assert_equal 7654321, assigns(:invoice).unique.to_i, "quote should get custom number"
  end

  def test_should_not_record_payments_for_quotes
    invoice = invoices(:quote_sent)
    
    assert_raise Exception do
      post :mark_record_payment, :id=>invoice.id
    end

  end

  ##################### Filters & Pagination (User Story 4) ############################

  def test_should_find_invoice_by_unique_number
    # ask for invoice with unique number 2
    get :index, :filters=>{:unique=>"2"}
    assert_response :success
    assert_not_nil assigns(:invoices)
    assert assigns(:invoices).kind_of?(Array), "invoices should be an array"
    assert_equal 1, assigns(:invoices).length, "there should only be one invoice"
    assert_equal "2", assigns(:invoices).first.unique_number.to_s
  end

  def test_should_remember_search_filter_settings
    get :index, :filters=>{:unique=>"2", :something => 'blah'}
    assert_response :success
    assert_not_nil assigns(:filters)
    assert assigns(:filters).kind_of?(OpenStruct)
    assert_equal "2", assigns(:filters).unique
    assert_equal "blah", assigns(:filters).something
  end

  def test_grid_filter_should_remember_search_filter_settings
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    put :filter, :filters=>{:customers => "test_customer", :fromdate => "2007-01-11", :todate=> "2008-01-11"}
    assert_response :success
    assert_template "overview"
    assert_not_nil assigns(:filters)
    assert assigns(:filters).kind_of?(OpenStruct)
    assert_equal "test_customer", assigns(:filters).customers[0]
    assert_equal "2007-01-11", assigns(:filters).fromdate[0]
    assert_equal "2008-01-11", assigns(:filters).todate[0]
  end

  def test_should_clear_search_filter_settings
    get :index, :filters=>{:unique=>"2", :something => 'blah', :clear => "Clear"}
    assert_response :success
    assert_not_nil assigns(:filters)
    assert assigns(:filters).kind_of?(OpenStruct)
    assert_equal nil, assigns(:filters).unique
    assert_equal nil, assigns(:filters).something
  end

  def test_grid_filter_should_clear_search_filter_settings
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    put :filter, :filters=>{:customers => "test_customer", :fromdate => "2007-01-11", :todate=> "2008-01-11", :clear => "Clear"}
    assert_response :success
    assert_template "overview"
    assert_not_nil assigns(:filters)
    assert assigns(:filters).kind_of?(OpenStruct)
    assert_equal nil, assigns(:filters).customers
    assert_equal nil, assigns(:filters).fromdate
    assert_equal nil, assigns(:filters).todate
  end

  def test_should_paginate_invoice_list
    login_as :heavy_user
    get :index
    assert_response :success
    assert_not_nil assigns(:invoices)
    assert assigns(:invoices).kind_of?(PagingEnumerator)
    assert assigns(:invoices).size > ::AppConfig.pagination.invoices.page_size
    assert_equal ::AppConfig.pagination.invoices.page_size, assigns(:invoices).page_size
    assert_equal ::AppConfig.pagination.invoices.page_size, assigns(:invoices).results.length
    first = assigns(:invoices).results.first
    
    get :index, :page => 2
    assert_response :success
    assert_not_nil assigns(:invoices)
    assert assigns(:invoices).kind_of?(PagingEnumerator)
    assert assigns(:invoices).size > ::AppConfig.pagination.invoices.page_size
    assert_equal ::AppConfig.pagination.invoices.page_size, assigns(:invoices).page_size
    assert_equal ::AppConfig.pagination.invoices.page_size, assigns(:invoices).results.length
    assert assigns(:invoices).results.first.id != first.id
  end
  
  def test_should_find_invoices_for_one_customers
    login_as :heavy_user

    get :index
    assert !assigns(:nested)
    
    get :index, :customer_id => customers(:heavy_user_customer_1)
    #heavy_user_customer_1 has 22 invoices
    assert assigns(:nested)
    assert_response :success
    assert_equal 22, assigns(:invoices).size
    assert assigns(:invoices).results.all?{|i| i.customer == customers(:heavy_user_customer_1)}
    
    get :index, :customer_id => customers(:heavy_user_customer_2)
    #heavy_user_customer_2 has 22 invoices
    assert assigns(:nested)
    assert_response :success
    assert_equal 1, assigns(:invoices).size
    assert_equal customers(:heavy_user_customer_2), assigns(:invoices).results.first.customer
  end
  
  def test_should_find_invoices_for_multiple_customers
    login_as :heavy_user
    get :index, :filters=>{:customers=>"#{customers(:heavy_user_customer_2).id}, #{customers(:heavy_user_customer_3).id}"}
    assert_response :success
    assert !assigns(:nested)
    assert_equal 6, assigns(:invoices).size
    assert assigns(:invoices).results.any?{|i| i.customer == customers(:heavy_user_customer_2)}    
    assert assigns(:invoices).results.any?{|i| i.customer == customers(:heavy_user_customer_3)}    
    assert assigns(:invoices).results.all?{|i| i.customer == customers(:heavy_user_customer_2) || i.customer == customers(:heavy_user_customer_3)}    
  end
  
  def test_should_find_draft_invoices
    get :index, :filters =>{:statuses => 'draft', :customers => "#{customers(:customer_with_every_status_invoice).id}"}
    assert_response :success
    assert_equal 1, assigns(:invoices).size
    assert assigns(:invoices).results.all?{|i| i.draft?}        
  end
  
  def test_should_find_sent_invoices
    get :index, :filters =>{:statuses => 'sent', :customers => "#{customers(:customer_with_every_status_invoice).id}"}
    assert_response :success
    assert_equal 2, assigns(:invoices).size
    assert assigns(:invoices).results.all?{|i| i.sent? or i.resent?}        
  end
  
  def test_should_find_unsent_invoices
    get :index, :filters =>{:statuses => 'unsent', :customers => "#{customers(:customer_with_every_status_invoice).id}"}
    assert_response :success
    assert_equal 2, assigns(:invoices).size
    assert assigns(:invoices).results.all?{|i| i.draft? or i.changed?}        
  end
  
  
  def test_should_find_unsent_invoices
    get :index, :filters =>{:statuses => 'paid', :customers => "#{customers(:customer_with_every_status_invoice).id}"}
    assert_response :success
    assert_equal 1, assigns(:invoices).size
    assert assigns(:invoices).results.all?{|i| i.paid?}     
  end
  
  def test_should_find_unpaid_invoices
    get :index, :filters =>{:statuses => 'unpaid', :customers => "#{customers(:customer_with_every_status_invoice).id}"}
    assert_response :success
    assert_equal 4, assigns(:invoices).size
    assert assigns(:invoices).results.all?{|i| !i.paid?}        
  end
  
  ##############  User Story 6 ####################################
  
  
  def test_should_display_line_items_in_existing_invoice
    saved = Invoice.find(invoices(:invoice_with_line_items).id)
    assert_equal 'Name of line item one', saved.line_items.find(line_items(:line_item_one).id).unit
  end

  def test_should_line_items_attributes_when_saving_existing_invoice
    assert_no_difference('LineItem.count') do
      assert_no_difference('Invoice.count') do
        put :update, :id => invoices(:invoice_with_line_items), :invoice => {
          :line_items_attributes => [
            {:id => line_items(:line_item_one).id, :unit => 'New unit for line item one', :description => line_items(:line_item_one).description },
            {:id => line_items(:line_item_two).id, :unit => line_items(:line_item_two).unit, :description => line_items(:line_item_two).description}
            ]
          }
      end
    end
    
    saved = Invoice.find(invoices(:invoice_with_line_items).id)
    assert_equal 'New unit for line item one', saved.line_items.find(line_items(:line_item_one).id).unit
  end
    


    ##############  User Story 16 ####################################
    
    def test_updating_sent_invoice_should_change_state_to_changed
      i=@user.invoices.create
      i.line_items.create({:quantity => BigDecimal.new('1'), :price => BigDecimal.new('1')})
      deny i.sendable?
      i.customer=@user.customers.create({:name => 'Some Customer'})
      i.save
      assert i.sendable?
      i.deliver!
      assert i.sent?
      post :update, :id => i.id, :invoice => {
        :description => 'updating'
      }
      i.reload
      assert i.changed?
    end
    
  ##############  User Story 11 ####################################
  def test_should_recalculate_total_when_updating_discount_amount_when_saving_existing_invoice
    assert_no_difference('LineItem.count') do
      assert_no_difference('Invoice.count') do
        put :update, :id => invoices(:invoice_with_line_items), :invoice => {
            :discount_value => "0.66",
            :discount_type => 'amount'
          }
      end
    end
    
    i = Invoice.find(invoices(:invoice_with_line_items).id)
    assert_equal BigDecimal.new("32.67"), i.total_amount, "invoice with line items total of 33.33 and a discount of .66 should have invoice total of 32.67. Actual total is #{i.total_amount} "   
  end    
  
  def test_should_recalculate_total_when_updating_discount_percent_when_saving_existing_invoice
    assert_no_difference('LineItem.count') do
      assert_no_difference('Invoice.count') do
        put :update, :id => invoices(:invoice_with_line_items), :invoice => {
            :discount_value => "2.00",
            :discount_type => Invoice::PercentDiscountType
          }
      end
    end

    i = Invoice.find(invoices(:invoice_with_line_items).id)
    assert_equal BigDecimal.new("32.66"), i.total_amount, "invoice with line items total of 33.33 and a discount percent of 2.00 should have invoice total of 32.66. Actual total is #{i.total_amount} "
  end

  ################ Invoice with date, reference number, comment, invoice number (User story 14) ######

  # reject the following date string:
  # "Random string"
  def test_should_reject_invalid_date
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    assert_no_difference('LineItem.count') do
      assert_no_difference('Invoice.count') do
        put :update, :id => invoices(:invoice_with_line_items), :invoice => {
            :date => "Random string"
          }
      end
    end

    assert_nil assigns(:date)
    assert_equal "is an invalid date", assigns(:invoice).errors.on(:date)
  end

  # accept the following date formats:
  # "Jul 29, 2006"
  # "12/31/2007"
  def test_should_parse_dates
    assert_no_difference('LineItem.count') do
      assert_no_difference('Invoice.count') do
        put :update, :id => invoices(:invoice_with_line_items), :invoice => {
            :date => "Jul 29, 2006"
          }
      end   
    end

    i = Invoice.find(invoices(:invoice_with_line_items).id)
    assert_equal Date.new(2006, 7, 29), i.date, "invoice date should be July 29, 2006."
    
    assert_no_difference('LineItem.count') do
      assert_no_difference('Invoice.count') do
        put :update, :id => invoices(:invoice_with_line_items), :invoice => {
            :date => "12/31/2007"
          }
      end   
    end

    i = Invoice.find(invoices(:invoice_with_line_items).id)
    assert_equal Date.new(2007, 12, 31), i.date, "invoice date should be parsed as Dec 31, 2007."

  end
  
  def test_should_load_overview
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :overview
    assert_response :success
  end

  def test_should_load_past_due_overview_as_json
    # basic sanity check that overview_data creates filters object, and fetches the overdue invoice in users(:basic)
    # TODO: these tests could be better factored to isolate testing what the controller does rather than just the end result
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    xhr :get, :overview, :meta_status => Invoice::META_STATUS_PAST_DUE, :limit => '10'
    assert_response :success
    
    assert_not_nil assigns(:filters)
    assert_match /"status": "resent"/, @response.body
    assert_match /"total": 1/, @response.body
  end

  def test_should_load_draft_overview_as_json
    # basic sanity check that overview_data creates filters object, and fetches the overdue invoice in users(:basic)
    # TODO: these tests could be better factored to isolate testing what the controller does rather than just the end result
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    xhr :get, :overview, :meta_status => Invoice::META_STATUS_DRAFT, :limit => '10'
    assert_response :success
    assert_not_nil assigns(:filters)
    assert_match /"status": "draft"/, @response.body
    json_data = ActiveSupport::JSON.decode( @response.body )
    # the :limit param should limit the number of rows returned, however, the total param will always be the total number of records.
    assert_equal 19, json_data["total"]
    assert_equal 10, json_data["invoices"].length
    
    # compare the JSON data with the database
    json_data = ActiveSupport::JSON.decode( @response.body )
    filters = OpenStruct.new()
    filters.conditions = Invoice.find_by_meta_status_conditions( Invoice::META_STATUS_DRAFT )
    inv = Invoice.filtered_invoices(users(:basic_user).invoices, filters)
    assert_equal inv.length, json_data["total"], "Number of JSON rows matches the number of invoices."
    0.upto( json_data["invoices"].length-1 ) do |i|
      json_inv = json_data["invoices"][i]
      assert_equal inv[i].unique, json_inv["unique"], "JSON invoice number matches invoice with id #{inv[i].id}"
      json_date = json_inv["date"].blank? ? "" : Date.parse( json_inv["date"] )
      inv_date = inv[i].date.blank? ? "" :  inv[i].date 
      assert_equal inv_date, json_date, "JSON date matches invoice with id #{inv[i].id}"
    end

    # compare the JSON data with fixture data (not dependent on the same code which generates the the JSON data)     
    inv = invoices(:invoice_with_line_items)
    assert_equal json_data["invoices"][2]["unique"], inv.unique, "JSON data matches fixture invoice data"
    assert_equal json_data["invoices"][2]["status"], inv.status, "JSON data matches fixture invoice data"
    assert_equal json_data["invoices"][2]["date"], inv.date, "JSON data matches fixture invoice data"
    inv = invoices(:invoice_with_unique_name)
    assert_equal json_data["invoices"][6]["unique"], inv.unique, "JSON data matches fixture invoice data"
    assert_equal json_data["invoices"][6]["status"], inv.status, "JSON data matches fixture invoice data"
    assert_equal json_data["invoices"][6]["date"], inv.date, "JSON data matches fixture invoice data"
  end

  ############# User story 10: Taxes on invoice.
  def test_should_setup_taxes
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    Invoice.any_instance.expects(:setup_taxes)
    get :new
  end
  
  # Ticket #90, tax heading
  def test_should_hide_tax_heading_from_lnav
    
    @controller.stubs(:form_authenticity_token).returns('aaaa')    

    #mock tax preferences enabled
    User.any_instance.stubs(:settings).returns(
      {
       'tax_enabled' => OpenStruct.new(:value => true)
      }
    ).at_least_once

    u_tax = Tax.new(:rate => '5.0', :name => 'GST', :profile_key => 'tax_1')
    # i_tax = u_tax.new_copy
    # assert i_tax.root == u_tax
    
    User.any_instance.stubs(:taxes).returns([u_tax])
    # Invoice.any_instance.stubs(:taxes).returns([i_tax])
    
    get :new
    assert_response :success
    
    #verify tax heading is present
    assert_select 'div#tax_container', :count => 1 do
      assert_select 'h1', /Tax/
    end
    
    #mock tax preferences disabled
    u_tax.enabled = false

    get :new
    assert_response :success

    #verify tax heading is absent
    assert_select 'div#tax_container:empty', :count => 1
  end  
  
  ####
  def test_should_properly_place_overdue_invoices
    
    login_as :basic_user  
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    
    #not overdue
    i1 = invoices(:invoice_with_date_and_due_date)
    i1.due_date = Date.today
    i1.save!
    i1.deliver!
    
    #overdue
    i2 = invoices(:invoice_with_date_and_no_due_date)
    i2.due_date = Date.today - 1
    i2.save!
    i2.deliver!
    
    #overdue but draft
    i3 = invoices(:invoice_with_due_date_and_no_date)
    i3.due_date = Date.today - 1
    i3.save!
    
    get :overview
    
    xhr :get, :overview, :meta_status => Invoice::META_STATUS_DRAFT, :start => 0, :limit => 10
    assert_response :success
    assert_not_nil assigns(:filters)
    json_data = ActiveSupport::JSON.decode( @response.body )
    assert_equal 17, json_data["total"]

    xhr :get, :overview, :meta_status => Invoice::META_STATUS_OUTSTANDING
    assert_response :success
    assert_not_nil assigns(:filters)
    json_data = ActiveSupport::JSON.decode( @response.body )
    assert_equal 3, json_data["total"]
    
    xhr :get, :overview, :meta_status => Invoice::META_STATUS_PAST_DUE
    assert_response :success
    assert_not_nil assigns(:filters)
    json_data = ActiveSupport::JSON.decode( @response.body )
    assert_equal 2, json_data["total"]
        
  end
  
  def test_default_auto_generated
    login_as :user_without_invoices
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :new
    assert_select "input[id=invoice_unique][value=1]"   
  end
  
  def test_blank_unique_generates_auto
    login_as :user_without_invoices
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :new
    assert_difference('Invoice.count') do
      post :create, :invoice => {:unique => ''}
    end
    get :new
    assert_select "input[id=invoice_unique][value=2]"  
  end
  
  def test_check_validation_on_error
    login_as :user_without_invoices
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :new
    assert_difference('Invoice.count') do
      post :create, :invoice => {:unique => 'asdf'}
    end
    assert_no_difference('Invoice.count') do
      post :create, :invoice => {:unique => 'asdf'}
      # assert_select "div[id=errorExplanation]" # FIXME we get a popup now so does this apply?
    end

  end
  
  def test_check_no_validation_on_auto_intercept
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    login_as :user_without_invoices
    get :new
    assert_difference('Invoice.count') do
      post :create, :invoice => {:unique => '1'}
    end
    assert_no_difference('Invoice.count') do
      post :create, :invoice => {:unique => '1'}
      assert_select "div[id=errorExplanation]", :count => 0
    end    
  end
  
  def test_check_default_invoice_date_rendered
    login_as :user_without_invoices
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :new
    TzTime.zone = TZInfo::Timezone.get("#{@user.profile.tz}")
    today =  Date::new(TzTime.now.year, TzTime.now.month, TzTime.now.day)
    assert_select "input[id=invoice_date][value='#{today}']"
  end
  
  def test_check_virtual_availability_attributes
    login_as :user_without_invoices
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :new
    post :create, :invoice => {:unique => '5'}
    post :create, :invoice => {:unique => '5'}
    assert_select "span[id=wanted_auto][value=5]"
    assert_select "span[id=available_auto][value=6]"    
   
  end
  ####

  def do_not_test_should_generate_pdf
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    load 'test/benchmark/generate_test_data.rb'
    i = $t.really_big_invoice

    ENV["RAILS_ASSET_ID"] = ''
    
    get :show, :id => i.to_param, :no_sidebar => '1'
    ofile = File.join(RAILS_ROOT, "tmp", "test.pdf")    
    if Test::Unit::TestCase.is_windows?
      prince_cmd = "\"C:\\Program\ Files\\prince\\engine\\bin\\prince.exe\" - --no-network -o #{ofile}"
    else
      prince_cmd = "/usr/local/bin/prince - --no-network -o #{ofile}"
    end

    #ix = 0
    # @response.body.each{|line|  ix += 1; puts "#{ix} #{line}"}
    
    body = @response.body.gsub(/(href|src)="/, "\\1=\"#{File.join(RAILS_ROOT, "public")}/")
    # body.gsub!('media="screen"', '')

    # puts body
    public_folder = RAILS_ROOT + '/public'
    head = '<head>' + "\n" +
    '<link href="' << public_folder << '/yui/build/reset/reset.css"  rel="stylesheet" type="text/css" />' + "\n" +
   	'<link href="' << public_folder << '/yui/build/fonts/fonts.css"  rel="stylesheet" type="text/css" />' + "\n" +
   	'<link href="' << public_folder << '/yui/build/grids/grids.css"  rel="stylesheet" type="text/css" />' + "\n" +
    '<link href="' << public_folder << '/stylesheets/tornado.css"  rel="stylesheet" type="text/css" />' + "\n" +

   	'<link href="' << public_folder << '/stylesheets/main_fixed_2.css"  rel="stylesheet" type="text/css" />' + "\n" +
    '<link href="' << public_folder << '/stylesheets/web_invoice.css"  rel="stylesheet" type="text/css" />' + "\n" +
    '<link href="' << public_folder << '/stylesheets/print.css"  rel="stylesheet" type="text/css" />' + "\n" +

   	'<title>Howdy</title>' + "\n" +
   	"</head>\n"
    
    body.sub!(/<head>.*<\/head>/mi, head)
    # URL encode an ampersand which confuses PrinceXML, in  _send_invoice_dialog.html.erb, url:
    body.gsub!( '&delivery%5B', '%26delivery%5B' ) 
    # debug only
    File.open(File.join(RAILS_ROOT, "tmp", "the_html.html"), "w+") { |f|
      f << body
    }
    
    start = Time.now
    pdf = IO.popen(prince_cmd, "w+")
    pdf.puts body
    pdf.close_write
    output = pdf.gets(nil)
    pdf.close
    end_time = Time.now

    puts "Making the pdf took #{end_time - start}"
    ENV["RAILS_ASSET_ID"] = nil
  end
  
  def test_toggle_customer_with_no_customer_selected
    xhr :post, :toggle_customer, :selected => ""
    assert_rjs :replace_html, 'on_the_fly_attributes'
    assert @response.body.include?("$(\"edit-btn\").hide();")
  end  
  
  def test_toggle_customer_with_customer_selected
    xhr :post, :toggle_customer, :selected => "1"
    assert_rjs :replace_html, 'on_the_fly_attributes'
    assert @response.body.include?("$(\"edit-btn\").show();")
  end  
    
  def test_should_render_nonzero_discount_on_show
    login_as :complete_user
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    put :update, :id => invoices(:discount_before_tax_invoice), :invoice => {
            :discount_value => "5.00",
            :discount_type => 'amount' }

    get :show, :id => 63
    assert_select "span[id=invoice_discount_amount]"
  end
  
  def test_should_not_render_zero_discount_on_show
    login_as :complete_user
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    put :update, :id => invoices(:discount_before_tax_invoice), :invoice => {
            :discount_value => "0.00",
            :discount_type => 'amount' }

    get :show, :id => 63
    assert_select "span[id=invoice_discount_amount]", :count => 0    
  end
  
  def test_csv_generation
    get :index, :format => 'csv'
    assert_response :success
    assert @response.body.include?("Customer")
    assert @response.body.include?("Grand totals:")
    assert @response.headers["type"].include?("text/csv")
  end
  
  def test_currency
    @controller.stubs(:form_authenticity_token).returns('aaaa') 
    login_as :user_without_invoices
    u = users(:user_without_invoices)
    u.profile.currency = "USD"
    u.profile.save(false)
    
    get :new
 
    assert_select "select[id=invoice_currency]" do
      assert_select "option[selected=selected][value=USD]"
    end
    
    @controller.instance_variable_set(:@current_user, nil) # force reload of current_user object!
    
    assert_difference('Invoice.count') do

      post :create, :invoice => {:unique => 98765, :currency => "CAD"}
    
    end

    @controller.instance_variable_set(:@current_user, nil) # force reload of current_user object!
    
    get :new
    assert_select "select[id=invoice_currency]" do
      assert_select "option[selected=selected][value=CAD]"
    end    

  end
  
  ############# bug fix tests ##################
  
  #TODO
  def test_should_remove_commas_and_spaces_from_numbers
      # from invoices test
      # post :create, :payment => {
      #   :customer_id => customers(:customer_for_payments).id,
      #   :invoice_id => invoices(:unpaid_invoice_1).id,
      #   :pay_type => 'cash',
      #   :amount => "1,0",
      #   :created_by_id => users(:user_for_payments).id }
      # 
      # i = Invoice.find(invoices(:unpaid_invoice_1))
      # assert_equal 10.0, i.paid_amount
  end
  
  def test_should_handle_default_contact_and_customer_contacts
    @controller.stubs(:form_authenticity_token).returns('aaaa')    
    invoice = add_valid_invoice(@user)
    customer = add_valid_customer(@user)
    invoice.customer = customer
    customer.save!
    invoice.save!
    
    get :edit, :id => invoice.id   
    assert_response :success
  end
  
  #TODO
  def test_should_calculate_discounted_total_before_displaying_edit
  end
  

  def test_recalc_new_invoice
    i = invoices(:unpaid_invoice_1)
    xhr :post, :recalculate, :invoice => {
      :currency => "USD", 
      :line_items_attributes => [
        {:quantity => 4, :price => 17, :row_id => "line_item_new_1", :should_destroy => 0},
        {:quantity => 1, :price => 1, :row_id => "line_item_new_2", :should_destroy => 0}
      ]
    }
    # page.replace_html 'invoice_line_items_total', format_amount(@invoice.line_items_total)
    # page.replace_html 'invoice_discount_amount', format_amount(@invoice.discount_amount)
    # @invoice.taxes.each do |tax|
    #   page.replace_html "invoice_#{tax.profile_key}_amount", format_amount(tax.amount)
    # end
    # page.replace_html 'invoice_total', format_amount(@invoice.total_amount)
    # 
    # @invoice.line_items.each do |line_item|
    #   page.select( "##{line_item.row_id} .subtotal").each do |value|
    #     page << "value.innerHTML = '#{testable_field('subtotal', format_amount(line_item.subtotal))}';"
    #   end#increment_ajax_counter_rjs(page)
    # end
    # page.increment_ajax_counter_rjs
    
    
    assert_rjs :replace_html, 'invoice_line_items_total', /"69.00"/
    assert_rjs :replace_html, 'invoice_total', /"69.00"/
  end


  def test_recalc_new_invoice_handles_blank_tax
    i = invoices(:unpaid_invoice_1)
    assert_nothing_raised(Exception) do
      xhr :post, :recalculate, :invoice => {
        :currency => "USD",
        :tax_1_enabled => 1,
        :tax_1_rate => nil,
        :tax_2_enabled => 1,
        :tax_2_rate => "",
        :line_items_attributes => [
          {:quantity => 4, :price => 17, :row_id => "line_item_new_1", :should_destroy => 0}
        ]
      }
    end
    assert_rjs :replace_html, 'invoice_line_items_total', /"68.00"/
    assert_rjs :replace_html, 'invoice_total', /"68.00"/
  end

  def test_mark_sent
    login_as :basic_user
    invoice = add_valid_invoice(users(:basic_user), {:line_items => false})
    assert !invoice.sendable?
    assert !invoice.markable_as_sent?
    assert invoice.draft?
    
    put :mark_sent, :id => invoice.id
    invoice.reload
    assert_equal 'draft', invoice.status
    assert @response.body.include?("cannot be marked")
    
    add_valid_line_item(invoice)
    invoice.save
    invoice.save_change!
    
    assert invoice.sendable?
    
    assert invoice.draft?
    put :mark_sent, :id => invoice.id
    invoice.reload
    assert_equal 'sent', invoice.status
    assert @response.body.include?("Outstanding")

  end

  def test_mark_sent_user_without_profile
    login_as :user_without_profile
    invoice = add_valid_invoice(users(:user_without_profile), {:line_items => false})
    add_valid_line_item(invoice)
    invoice.customer = Customer.new
    invoice.customer.created_by = invoice.created_by
    invoice.customer.name = "test name"
    invoice.save!
    invoice.save_change!
    assert !invoice.sendable?
    assert invoice.markable_as_sent?
    assert invoice.draft?
    
    put :mark_sent, :id => invoice.id
    invoice.reload
    assert_equal 'sent', invoice.status
    assert @response.body.include?("Outstanding")
    
  end

  def test_simply_invoice_show
    @controller.stubs(:form_authenticity_token).returns('aaaa') 
    login_as :simply_accounting_user
    @user = users(:simply_accounting_user)
    get :show, :id => 72
    assert_response :success
    #assert @response.body.include?("This invoice was created in.")
  end
  
  def test_simply_invoice_edit
    @controller.stubs(:form_authenticity_token).returns('aaaa') 
    login_as :simply_accounting_user
    @user = users(:simply_accounting_user)
    get :edit, :id => 72
    assert_response :redirect, "/"
  end
  
  def test_simply_invoice_update
    i = Invoice.find(72)
    i.description = "asdf"
    i.save(false)
    
    @controller.stubs(:form_authenticity_token).returns('aaaa') 
    login_as :simply_accounting_user
    @user = users(:simply_accounting_user)
    
    put :update, :id => 72, :invoice => {
        :description => 'fdsa',
        :due_date => Time.now+5.days,
        :unique => 987651
        }
        
    assert_response :redirect
    i = Invoice.find(72)
    assert i.description == "asdf"
  end
  
  def test_should_not_record_a_payment_without_customer
    login_as :heavy_user
    xhr :put, :mark_record_payment, :id => 78
    assert_match /Can't record a payment without a customer/, @response.body
  end
  
  def test_mark_paid
    @controller.stubs(:form_authenticity_token).returns('aaaa') 
    login_as :simply_accounting_user
    @user = users(:simply_accounting_user)
    i = Invoice.find(72)
    get :mark_paid, :id => 72
    assert_response :success

    i = Invoice.find(72)
    assert i.status == "paid"
  end
  
  def test_line_item_taxes_one_line_item
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    Profile.any_instance.stubs(:tax_1_in_taxable_amount).returns(false)
    login_as :complete_user
    post :create, :invoice => {
        :currency => "USD",
        :tax_1_enabled => 1,
        :tax_1_rate => 1,
        :tax_2_enabled => 1,
        :tax_2_rate => 10,
        :description => "invoice_with_line_item_taxes",
        :line_items_attributes => [
          {:quantity => 1, :price => 1, :row_id => "line_item_new_1", :should_destroy => 0, :tax_1_enabled => "1", :tax_2_enabled => "1"}
        ]
      }
    invoice = Invoice.find(:first, :conditions => {:description => "invoice_with_line_item_taxes"})
    assert_equal "0.01", invoice.tax_1_amount.to_s
    assert_equal "0.1", invoice.tax_2_amount.to_s
    assert_equal "1.11", invoice.total_amount.to_s
  end
  
  def test_line_item_taxes_four_line_items
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    Profile.any_instance.stubs(:tax_1_in_taxable_amount).returns(false)
    login_as :complete_user
    post :create, :invoice => {
        :currency => "USD",
        :tax_1_enabled => 1,
        :tax_1_rate => 1,
        :tax_2_enabled => 1,
        :tax_2_rate => 10,
        :description => "invoice_with_line_item_taxes",
        :line_items_attributes => [
          {:quantity => 1, :price => 10, :row_id => "line_item_new_1", :should_destroy => 0, :tax_1_enabled => "0", :tax_2_enabled => "0"},
          {:quantity => 1, :price => 100, :row_id => "line_item_new_2", :should_destroy => 0, :tax_1_enabled => "0", :tax_2_enabled => "1"},
          {:quantity => 1, :price => 1000, :row_id => "line_item_new_3", :should_destroy => 0, :tax_1_enabled => "1", :tax_2_enabled => "0"},
          {:quantity => 1, :price => 10000, :row_id => "line_item_new_4", :should_destroy => 0, :tax_1_enabled => "1", :tax_2_enabled => "1"}
        ]
      }
    invoice = Invoice.find(:first, :conditions => {:description => "invoice_with_line_item_taxes"})
    assert_equal "110.0", invoice.tax_1_amount.to_s
    assert_equal "1010.0", invoice.tax_2_amount.to_s
    assert_equal "12230.0", invoice.total_amount.to_s    
  end
  
  def test_line_item_taxes_only_one_tax_enabled
    @controller.stubs(:form_authenticity_token).returns('aaaa') 
    login_as :complete_user
    post :create, :invoice => {
        :currency => "USD",
        :tax_1_enabled => 0,
        :tax_1_rate => 1,
        :tax_2_enabled => 1,
        :tax_2_rate => 10,
        :description => "invoice_with_line_item_taxes",
        :line_items_attributes => [
          {:quantity => 1, :price => 1, :row_id => "line_item_new_1", :should_destroy => 0, :tax_1_enabled => "1", :tax_2_enabled => "1"}
        ]
      }
    invoice = Invoice.find(:first, :conditions => {:description => "invoice_with_line_item_taxes"})
    assert_equal "0.0", invoice.tax_1_amount.to_s
    assert_equal "0.1", invoice.tax_2_amount.to_s
    assert_equal "1.1", invoice.total_amount.to_s
  end
  
  #by discount before tax we do it as before, SA way:
  #subtract discount from total amount, and then add the taxes of the undiscounted subtotal
  #
  #this contrasts with Freshbook's way of doing things, which is:
  #subtract discount from total, and tax the discounted total as opposed to the whole total
  #
  #doing it Freshbook way is more complex because we need a way to distribute the invoice discount
  #across each line item, because some line items may have taxes enabled that others dont
  #
  #if accountants/legal issues require us to do it Freshbook's way, we should add a 3rd option
  #and change checkbox to dropdown. preferably with verbose explanation to the user how each way works
  def test_line_items_with_taxes_and_discount_percentage_before_tax
    Profile.any_instance.stubs(:tax_1_in_taxable_amount).returns(false)
    @controller.stubs(:form_authenticity_token).returns('aaaa') 
    login_as :complete_user
    post :create, :invoice => {
        :currency => "USD",
        :tax_1_enabled => 1,
        :tax_1_rate => 1,
        :tax_2_enabled => 1,
        :tax_2_rate => 2,
        :discount_type => "percent",
        :discount_value => "20.0",
        :description => "invoice_with_line_item_taxes",
        :line_items_attributes => [
          {:quantity => 1, :price => 200, :row_id => "line_item_new_1", :should_destroy => 0, :tax_1_enabled => "1", :tax_2_enabled => "1"}
        ]
      }
    i = Invoice.find(:first, :conditions => {:description => "invoice_with_line_item_taxes"})
    
    #the below assertion is correct using SA's way.
    # if we did it freshbook's way, it'd be "164.8"
    assert_equal "166.0", i.total_amount.to_s
  end

  def test_line_items_with_taxes_and_discount_amount_before_tax
    Profile.any_instance.stubs(:tax_1_in_taxable_amount).returns(false)
    @controller.stubs(:form_authenticity_token).returns('aaaa') 
    login_as :complete_user
    post :create, :invoice => {
        :currency => "USD",
        :tax_1_enabled => 1,
        :tax_1_rate => 1,
        :tax_2_enabled => 1,
        :tax_2_rate => 2,
        :discount_type => "amount",
        :discount_value => "40.0",
        :description => "invoice_with_line_item_taxes",
        :line_items_attributes => [
          {:quantity => 1, :price => 200, :row_id => "line_item_new_1", :should_destroy => 0, :tax_1_enabled => "1", :tax_2_enabled => "1"}
        ]
      }
    i = Invoice.find(:first, :conditions => {:description => "invoice_with_line_item_taxes"})
    
    assert_equal "166.0", i.total_amount.to_s
  end

  def test_line_items_with_taxes_and_discount_percentage_after_tax
    u = users(:complete_user)
    u.profile.discount_before_tax = false
    u.profile.save!
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    Profile.any_instance.stubs(:tax_1_in_taxable_amount).returns(false)
    login_as :complete_user
    post :create, :invoice => {
        :currency => "USD",
        :tax_1_enabled => 1,
        :tax_1_rate => 1,
        :tax_2_enabled => 1,
        :tax_2_rate => 2,
        :discount_type => "percent",
        :discount_value => "20.0",
        :discount_before_tax => false,
        :description => "invoice_with_line_item_taxes",
        :line_items_attributes => [
          {:quantity => 1, :price => 200, :row_id => "line_item_new_1", :should_destroy => 0, :tax_1_enabled => "1", :tax_2_enabled => "1"}
        ]
      }
    i = Invoice.find(:first, :conditions => {:description => "invoice_with_line_item_taxes"})
    
    assert_equal "164.8", i.total_amount.to_s
  end

  def test_line_items_with_taxes_and_discount_amount_after_tax
    u = users(:complete_user)
    u.profile.discount_before_tax = false
    u.profile.save!
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    Profile.any_instance.stubs(:tax_1_in_taxable_amount).returns(false)
    login_as :complete_user
    post :create, :invoice => {
        :currency => "USD",
        :tax_1_enabled => 1,
        :tax_1_rate => 1,
        :tax_2_enabled => 1,
        :tax_2_rate => 2,
        :discount_type => "amount",
        :discount_value => "40.0",
        :discount_before_tax => false,
        :description => "invoice_with_line_item_taxes",
        :line_items_attributes => [
          {:quantity => 1, :price => 200, :row_id => "line_item_new_1", :should_destroy => 0, :tax_1_enabled => "1", :tax_2_enabled => "1"}
        ]
      }
    i = Invoice.find(:first, :conditions => {:description => "invoice_with_line_item_taxes"})
    
    assert_equal "166.0", i.total_amount.to_s
  end
  
  def test_edited_invoice_preserves_tax_names

    @controller.stubs(:form_authenticity_token).returns('aaaa') 
    login_as :complete_user
    post :create, :invoice => {
        :currency => "USD",
        :tax_1_enabled => "1",
        :tax_1_rate => 1,
        :tax_2_enabled => "1",
        :tax_2_rate => 2,
        :discount_type => "amount",
        :discount_value => "40.0",
        :discount_before_tax => false,
        :description => "my_invoice",
        :line_items_attributes => [
          {:quantity => 1, :price => 200, :row_id => "line_item_new_1", :should_destroy => 0, :tax_1_enabled => "1", :tax_2_enabled => "1"}
        ]
      }
    invoice = Invoice.find(:first, :conditions => {:description => "my_invoice"})

    assert_equal 2, invoice.taxes.size
    assert_equal "Goods and Services Tax", invoice.tax_1.name
    assert_equal "BC PST", invoice.tax_2.name
    assert_equal "1.0", invoice.tax_1.rate.to_s
    assert_equal "2.0", invoice.tax_2.rate.to_s
    assert invoice.tax_1.enabled?
    assert invoice.tax_2.enabled?
    
    puts "put to invoice update" if $log_on
    assert_no_difference 'Tax.count' do
      put :update, :id => invoice.id, :invoice => {
          :currency => "USD",
          :tax_1_enabled => "1",
          :tax_1_rate => 1,
          :tax_2_enabled => "1",
          :tax_2_rate => 2,
          :discount_type => "amount",
          :discount_value => "40.0",
          :discount_before_tax => false,
          :description => "my_invoice",
          :line_items_attributes => [
            {:quantity => 1, :price => 200, :row_id => "line_item_new_1", :should_destroy => 0, :tax_1_enabled => "1", :tax_2_enabled => "1"}
          ]
        }
    end
    assert_equal 2, invoice.taxes.size
    assert_equal "Goods and Services Tax", invoice.tax_1.name
    assert_equal "BC PST", invoice.tax_2.name
    assert_equal "1.0", invoice.tax_1.rate.to_s
    assert_equal "2.0", invoice.tax_2.rate.to_s
    assert invoice.tax_1.enabled?
    assert invoice.tax_2.enabled?
  end

  def test_edited_invoice_preserves_tax_names_as_long_as_they_are_valid_and_even_if_they_are_disabled

    @user = users(:complete_user)

    @controller.stubs(:form_authenticity_token).returns('aaaa') 
    login_as :complete_user
    post :create, :invoice => {
        :currency => "USD",
        :tax_1_enabled => "1",
        :tax_1_rate => 1,
        :tax_2_enabled => "1",
        :tax_2_rate => 2,
        :discount_type => "amount",
        :discount_value => "40.0",
        :discount_before_tax => false,
        :description => "my_invoice",
        :line_items_attributes => [
          {:quantity => 1, :price => 200, :row_id => "line_item_new_1", :should_destroy => 0, :tax_1_enabled => "1", :tax_2_enabled => "1"}
        ]
      }
    invoice = Invoice.find(:first, :conditions => {:description => "my_invoice"})

    @user.profile.tax_1_name = "gst2"
    @user.profile.tax_2_name = "pst2"
    @user.profile.tax_1_rate = "10.0"
    @user.profile.tax_2_rate = "20.0"
    @user.profile.save!
    
    put :update, :id => invoice.id, :invoice => {
        :currency => "USD",
        :tax_1_enabled => "0",
        :tax_1_rate => 1,
        :tax_2_enabled => "0",
        :tax_2_rate => 2,
        :discount_type => "amount",
        :discount_value => "40.0",
        :discount_before_tax => false,
        :description => "my_invoice",
        :line_items_attributes => [
          {:quantity => 1, :price => 200, :row_id => "line_item_new_1", :should_destroy => 0, :tax_1_enabled => "1", :tax_2_enabled => "1"}
        ]
      }
      
    invoice.reload

    assert_equal 2, invoice.taxes.size
    assert_equal "Goods and Services Tax", invoice.tax_1.name
    assert_equal "BC PST", invoice.tax_2.name
    assert_equal "1.0", invoice.tax_1.rate.to_s
    assert_equal "2.0", invoice.tax_2.rate.to_s
    deny invoice.tax_1.enabled?
    deny invoice.tax_2.enabled?
    
  end
  
  def test_invoice_inherits_taxes_from_profile_if_had_no_prior_taxes
    $log_on = false
    @user = users(:basic_user)

    @controller.stubs(:form_authenticity_token).returns('aaaa') 
    login_as :basic_user
    post :create, :invoice => {
        :currency => "USD",
        :discount_type => "amount",
        :discount_value => "40.0",
        :discount_before_tax => false,
        :description => "my_invoice",
        :line_items_attributes => [
          {:quantity => 1, :price => 200, :row_id => "line_item_new_1", :should_destroy => 0}
        ]
      }
    invoice = Invoice.find(:first, :conditions => {:description => "my_invoice"})
    assert_equal 0, invoice.taxes.size

    
    @user.profile.tax_1_name = "gst"
    @user.profile.tax_2_name = "pst"
    @user.profile.tax_1_rate = "10.0"
    @user.profile.tax_2_rate = "20.0"
    @user.profile.tax_enabled = true
    @user.profile.save!

    put :update, :id => invoice.id, :invoice => {
        :currency => "USD",
        :tax_1_enabled => "1",
        :tax_1_rate => 10.0,
        :tax_2_enabled => "1",
        :tax_2_rate => 30.0,
        :discount_type => "amount",
        :discount_value => "40.0",
        :discount_before_tax => false,
        :description => "my_invoice",
        :line_items_attributes => [
          {:quantity => 1, :price => 200, :row_id => "line_item_new_1", :should_destroy => 0, :tax_1_enabled => "1", :tax_2_enabled => "1"}
        ]
      }
      
    invoice.reload

    assert_equal 2, invoice.taxes.size
    assert_equal "gst", invoice.tax_1.name
    assert_equal "pst", invoice.tax_2.name
    assert_equal "10.0", invoice.tax_1.rate.to_s
    assert_equal "30.0", invoice.tax_2.rate.to_s
    assert invoice.tax_1.enabled?
    assert invoice.tax_2.enabled?
  end
  
  def test_invoice_inherits_correct_taxes_from_profile_even_if_they_are_disabled_on_creation

    @user = users(:complete_user)

    @controller.stubs(:form_authenticity_token).returns('aaaa') 
    login_as :complete_user
    post :create, :invoice => {
        :tax_1_enabled => "0",
        :tax_1_rate => 6.0,
        :tax_2_enabled => "0",
        :tax_2_rate => 7.0,
        :currency => "USD",
        :discount_type => "amount",
        :discount_value => "40.0",
        :discount_before_tax => false,
        :description => "my_invoice",
        :line_items_attributes => [
          {:quantity => 1, :price => 200, :row_id => "line_item_new_1", :should_destroy => 0, :tax_1_enabled => "1", :tax_2_enabled => "1"}
        ]
      }
    invoice = Invoice.find(:first, :conditions => {:description => "my_invoice"})

    assert_equal 2, invoice.taxes.size
    assert_equal "Goods and Services Tax", invoice.tax_1.name
    assert_equal "BC PST", invoice.tax_2.name
    assert_equal "6.0", invoice.tax_1.rate.to_s
    assert_equal "7.0", invoice.tax_2.rate.to_s
    deny invoice.tax_1.enabled?
    deny invoice.tax_2.enabled?
    
  end

  def test_invoice_preserves_existing_tax_but_inherits_nonexisting_tax_from_profile
    @user = users(:basic_user)

    @user.profile.tax_1_name = "gst"
    @user.profile.tax_1_rate = "10.0"
    @user.profile.tax_enabled = true
    @user.profile.save!

    @controller.stubs(:form_authenticity_token).returns('aaaa') 
    login_as :basic_user
    post :create, :invoice => {
        :tax_1_enabled => "1",
        :tax_1_rate => 6.0,
        :currency => "USD",
        :discount_type => "amount",
        :discount_value => "40.0",
        :discount_before_tax => false,
        :description => "my_invoice",
        :line_items_attributes => [
          {:quantity => 1, :price => 200, :row_id => "line_item_new_1", :should_destroy => 0}
        ]
      }
    invoice = Invoice.find(:first, :conditions => {:description => "my_invoice"})

    assert_equal 1, invoice.taxes.size
    assert_equal "gst", invoice.tax_1.name
    assert_equal "6.0", invoice.tax_1.rate.to_s
    assert invoice.tax_1.enabled?
    
    @user.profile.tax_1_name = "gst2"
    @user.profile.tax_1_rate = "20.0"
    @user.profile.tax_2_name = "pst2"
    @user.profile.tax_2_rate = "30.0"
    @user.profile.save!
    
    put :update, :id => invoice.id, :invoice => {
        :currency => "USD",
        :tax_1_enabled => "1",
        :tax_1_rate => 40.0,
        :tax_2_enabled => "1",
        :tax_2_rate => 50.0,
        :discount_type => "amount",
        :discount_value => "40.0",
        :discount_before_tax => false,
        :description => "my_invoice",
        :line_items_attributes => [
          {:quantity => 1, :price => 200, :row_id => "line_item_new_1", :should_destroy => 0, :tax_1_enabled => "1", :tax_2_enabled => "1"}
        ]
      }
      
    invoice.reload

    assert_equal 2, invoice.taxes.size
    assert_equal "gst", invoice.tax_1.name
    assert_equal "pst2", invoice.tax_2.name
    assert_equal "40.0", invoice.tax_1.rate.to_s
    assert_equal "50.0", invoice.tax_2.rate.to_s
    assert invoice.tax_1.enabled?
    assert invoice.tax_2.enabled?
  end
  
  def test_populates_customer_from_parameter_first_customer
    @user = users(:basic_user)
    @controller.stubs(:form_authenticity_token).returns('aaaa') 
    login_as :basic_user    
    
    get :new, :customer => "1"
    assert_select 'select#invoice_customer_id', :count => 1 do
      assert_select 'option[value=1][selected=selected]', :count => 1
      assert_select 'option[value=2][selected=selected]', :count => 0
      assert_select 'option[value=2]', :count => 1
    end
  
  end

  def test_populates_customer_from_parameter_second_customer
    @user = users(:basic_user)
    @controller.stubs(:form_authenticity_token).returns('aaaa') 
    login_as :basic_user    
    
    get :new, :customer => "2"
    assert_select 'select#invoice_customer_id', :count => 1 do
      assert_select 'option[value=1][selected=selected]', :count => 0
      assert_select 'option[value=2][selected=selected]', :count => 1
      assert_select 'option[value=1]', :count => 1
    end
  end
  
  def test_populates_customer_from_parameter_wrong_customer
    @user = users(:basic_user)
    @controller.stubs(:form_authenticity_token).returns('aaaa') 
    login_as :basic_user    
    
    #customer doesnt belong to user
    get :new, :customer => "4"
    assert_select 'select#invoice_customer_id', :count => 1 do
      assert_select 'option[value=4][selected=selected]', :count => 0
      assert_select 'option[value=4]', :count => 0
    end
  end
  
  def test_can_switch_customer_for_invoice
    i = invoices(:invoice_with_customer_with_contact)
    put :update, :id => invoices(:invoice_with_customer_with_contact).id, :invoice => { :customer_id => "3" }
    assert_response :redirect
  end
  
  def test_switching_customer_type_on_invoice_updates_customer_id_on_all_payments_for_that_invoice
    login_as :user_for_payments
    i = invoices(:partially_paid_invoice)
    c = Customer.new
    c.name = "bob"
    c.created_by_id = users(:user_for_payments).id
    c.save!
    put :update, :id => i.id, :invoice => { :customer_id => c.id }
    assert_response :redirect
    i.reload
    assert_equal i.customer.id, c.id
    assert_equal c.id, i.pay_applications[0].payment.customer_id
  end
  
  def test_preview_customer_copy_link_on_show
    @controller.stubs(:form_authenticity_token).returns('aaaa') 
    login_as :basic_user
    get :show, :id => 1
    inv = Invoice.find(1)
    assert @response.body.include?("Preview customer copy")
    assert @response.body.include?(inv.get_or_create_access_key)
  end

  def test_mobile_version_show
    @controller.stubs(:form_authenticity_token).returns('aaaa') 
    get :show, :id => 1, :mobile => 'true'
    assert @response.body.include?("mobile.css")
    deny @response.body.include?("shared.css")
    deny @response.body.include?("static.css")
    assert @response.body.include?("99") #unique num for that invoice
  end
  
  def test_mobile_version_show_sendable
    @controller.stubs(:form_authenticity_token).returns('aaaa') 
    get :show, :id => 7, :mobile => 'true'
    assert @response.body.include?("mobile.css")
    deny @response.body.include?("shared.css")
    deny @response.body.include?("static.css")
    assert @response.body.include?("99") #unique num for that invoice
  end

  def test_mobile_overview
    @controller.stubs(:form_authenticity_token).returns('aaaa') 
    login_as :basic_user
    get :overview, :mobile => "true"
    assert @response.body.include?("mobile.css")
    deny @response.body.include?("shared.css")
    deny @response.body.include?("static.css")
    assert @response.body.include?("Invoices")
  end
  
  def test_mobile_version_view_new
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :new, :mobile => 'true'
    assert @response.body.include?("mobile.css")
    deny @response.body.include?("shared.css")
    deny @response.body.include?("static.css")
  end

  def test_mobile_version_view_edit
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :edit, :id => 1, :mobile => 'true'
    assert @response.body.include?("mobile.css")
    deny @response.body.include?("shared.css")
    deny @response.body.include?("static.css")
  end  

  def test_mobile_version_on_invalid_submit_new
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :new, :mobile => 'true'
    post :create, :invoice => {:unique => 99 }
    assert @response.body.include?("mobile.css")
    deny @response.body.include?("shared.css")
    deny @response.body.include?("static.css")
    assert @response.body.include?("already been taken")
  end

  def test_mobile_version_on_invalid_submit_edit
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :edit, :id => 1, :mobile => 'true'
    put :update, :id => 1, :invoice => {
      :unique => 2 }
    assert @response.body.include?("mobile.css")
    deny @response.body.include?("shared.css")
    deny @response.body.include?("static.css")
    assert @response.body.include?("already been taken")
  end
  
  def test_mobile_version_invoice_outline_correct_sorting
    users(:basic_user).invoices.each do |inv|
      inv.calculate_discounted_total
      inv.save(false)
    end
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :overview, :mobile => 'true'
    assert @response.body.include?("Late (1)")
    assert @response.body.include?("10.00 CAD is 1 days late")

    assert @response.body.include?("Sent (2)")
    assert @response.body.include?("10.00 CAD due")

    assert @response.body.include?("Draft (19)")
    assert @response.body.include?("0.00 CAD total")

    assert @response.body.include?("Paid (1)")
    assert @response.body.include?("100.00 CAD paid")
  end

  def test_mobile_version_create_quote
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    get :new, :mobile => 'true'
    assert_difference('Invoice.count') do
      post :create, :is_quote => "1", :mobile => "true", :invoice => {:description => 'test_mobile_version_create_quote',
          :contact_id => contacts(:basic_contact).id,
          :customer_id => customers(:customer_with_contacts).id
        }
    end
    assert_redirected_to :controller => "invoices", :action => "show"   
    assert assigns(:invoice).status, "quote_draft"
  end

  def test_mobile_version_convert_quote
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    invoice = Invoice.find(:first, :conditions => "status = 'quote_draft'")
    put :convert_quote, :id => invoice.id
    assert_redirected_to invoice_path(invoice)
    assert_equal assigns(:invoice).status, "draft"
  end

unless ENV['OFFLINE']  # skip if OFFLINE
  def doesnt_work_test_generated_pdf_should_include_logo
    # TODO: figure out how to tell if image is there. problem is I think prince is compositing the image before creating pdf -- ie, there is no obj in the pdf corresponding to the logo.
    @controller.stubs(:form_authenticity_token).returns('aaaa')
    user = users(:basic_user)
    puts "user.logo: #{user.logo.inspect}"
    image_path = Test::Unit::TestCase.fixture_path + "/files/test_logo.gif"
    image_file = File.open(image_path, 'r')
    # logo = user.build_logo
    # logo.set_from_file(image_file)
    # logo.save!
    puts "user.logo: #{user.logo.inspect}"
    invoice = user.invoices.find(:first, :conditions => 'total_amount > 0.0')
    puts "invoice: #{invoice.inspect}"
    
    get :show, :id => invoice.id, :format => 'pdf'
    
    File.open('/tmp/test_pdf.pdf', 'w') {|f| f.write(@response.body) }
    
    puts "IMAGE 64------->\n\n\n\n"
    puts Base64.encode64(File.read(image_path))

    puts "RESPONSE------->\n\n\n\n"
    # puts Base64.encode64(@response.body)
    puts @response.body
    
    flunk("dont run everything yet")
  end
end # skip if OFFLINE

  # Recurring invoices

  def test_should_create_recurring_invoice_from_regular
    @regular_invoice = invoices(:invoice_with_no_customer)    
    params = { "frequency" => 'monthly' }
    @recurring_invoice = mock_model(Invoice)
    Invoice.expects(:create_recurring_from).with(@regular_invoice,params).returns( @recurring_invoice )

    put :create_recurring, :id => @regular_invoice.id, :invoice => params

    assert_select "*", /created successfully/
    assert_select "a[href='#{invoice_url(@recurring_invoice)}']"
  end

  def test_should_lists_recurring_invoices
    get :recurring

    assert_response :success
    assert_equal 2, assigns(:invoices).size
    assert_equal [91,92], assigns(:invoices).map(&:id)
  end

  def test_should_display_recurring_schedule_description
    recurring = invoices(:recurring)

    get :show, :id=>recurring.id

    assert_select ".schedule-info" do
      assert_select "*", /each month/
      assert_select "*", /Sep 24, 2009/
    end

  end

  def test_should_lists_invoices_generated_by_recurring_invoice
    recurring = invoices(:recurring_sendable)

    invoice_mock = invoices(:invoice_with_customer_with_contact)
    generated_invoices = [invoice_mock,invoice_mock,invoice_mock]
    Invoice.any_instance.expects(:generated_invoices).returns(generated_invoices)

    get :generated, :id => recurring.id
    
    assert_response :success
    assert_equal 3, assigns(:invoices).count
  end
  
end
