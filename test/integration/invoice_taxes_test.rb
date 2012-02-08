require "#{File.dirname(__FILE__)}/../test_helper"

class InvoiceTaxesTest < ActionController::IntegrationTest
  
  fixtures :users, :configurable_settings, :taxes, :customers, :invoices, :line_items
  
                    
  def setup
  end
  
  def teardown
    $log_on = false
  end
  
  ######################### Creating New Invoices ####################
  
  def test_create_invoice_with_taxes_disabled_should_leave_taxes_empty
    # Show no taxes and leave invoices.taxes empty.
    
    # pre conditions: user with no taxes enabled
    user = tax_user(:basic_user)
    deny user.profile.tax_enabled
    user.login
    user.clicks_create_new_invoice
    
    user.assert_select 'div#tax_container', true, 'tax container was missing in new invoice with taxes disabled in profile'

    user.assert_select 'input#invoice_tax_1_enabled', false, "new invoice showed tax_1_enabled with taxes disabled in profile"
    user.assert_select 'input#invoice_tax_1_rate', false, "new invoice showed tax_1_rate with taxes disabled in profile"

    user.assert_select 'input#invoice_tax_2_enabled', false, "new invoice showed tax_2_enabled with taxes disabled in profile"
    user.assert_select 'input#invoice_tax_2_rate', false, "new invoice showed tax_2_rate with taxes disabled in profile"
    
    user.assert user.assigns(:invoice)
    user.assert user.assigns(:invoice).taxes.empty?
  end
  
  def test_create_invoice_with_profile_taxes_enabled_should_copy_taxes
    # copy taxes from profile on create to invoice.taxes, and enable them.
    # pre conditions: user with taxes enabled in profile
    context = "with taxes enabled in profile and valid"
    user = tax_user(:basic_user)
    user.enable_profile_taxes
    assert user.profile.tax_enabled

    user.login
    user.clicks_create_new_invoice
    
    user.assert_select 'div#tax_container', true, "new invoice screen was missing tax_container #{context}"
    
    user.assert_select 'input#invoice_tax_1_enabled', true, "new invoice showed tax_1_enabled #{context}"
    user.assert_select 'input#invoice_tax_1_rate', true, "new invoice showed tax_1_rate #{context}"

    user.assert_select 'input#invoice_tax_2_enabled', true, "new invoice showed tax_2_enabled #{context}"
    user.assert_select 'input#invoice_tax_2_rate', true, "new invoice showed tax_2_rate #{context}"
    
    user.assert user.assigns(:invoice), "new invoice page did not have an invoice assigned #{context}"
    user.deny user.assigns(:invoice).taxes.empty?, "assigns(:invoice).taxes was empty #{context}"

    user.assert_taxes(user.assigns(:invoice), context)
  end
  
  #test_create_invoice_with_profile_taxes_enabled_but_empty_should_copy_taxes_but_they_should_be_disabled_and_not_displayed
  #
  #removed due to refactoring. now invoices wont copy blank taxes from profile. they will have 1 or 0 taxes if necessary
  #next time they are edited, if profile has new taxes instead of the blank ones, the invoice taxes can be updated to reflect that.
  #this removes a range of annoying bugs
  
  def test_create_invoice_and_edit_taxes_should_copy_taxes_and_mark_edited
    context = "with taxes enabled in profile and valid"
    user = tax_user(:basic_user)
    user.enable_profile_taxes
    assert user.profile.tax_enabled

    user.login
#    puts "do click new invoice"
    user.clicks_create_new_invoice
    
    user.assert_select 'div#tax_container', true, "new invoice screen was missing tax_container #{context}"
    
    user.assert_select 'input#invoice_tax_1_enabled', true, "new invoice failed to show tax_1_enabled #{context}"
    user.assert_select 'input#invoice_tax_1_rate', true, "new invoice failed to show tax_1_rate #{context}"

    user.assert_select 'input#invoice_tax_2_enabled', true, "new invoice failed to show tax_2_enabled #{context}"
    user.assert_select 'input#invoice_tax_2_rate', true, "new invoice failed to show tax_2_rate #{context}"
    
    user.assert user.assigns(:invoice)
    user.deny user.assigns(:invoice).taxes.empty?

    user.assert_taxes(user.assigns(:invoice), context)
#    puts "do save invoice"
    user.saves_new_invoice(:tax_1_rate => '10.1')
#    puts user.assigns(:invoice).taxes.inspect

    user.assert_taxes(user.assigns(:invoice), context, {:tax_1_rate => 10.1, :tax_1_edited => true})
  end
  
  ######################### Editing Invoices #########################

  def test_edit_invoice_with_no_taxes_after_enabling_profile_taxes_should_show_taxes_disabled_by_default
    # Show taxes but show them disabled. Upon save, copy taxes to invoice with enabled false unless user enabled with checkbox. If user changes values mark them as edited.
    context = "when editing invoice with no taxes after enabling profile taxes"
    user = tax_user(:basic_user)
    deny user.profile.tax_enabled

    user.login
    user.clicks_create_new_invoice

    user.assert user.assigns(:invoice)
    user.assert user.assigns(:invoice).taxes.empty?

    user.saves_new_invoice(
      :customer_id => user.scratch.fixture_user.customers.first.id,
      :date => Time.now.to_date.to_s(:MMDDYYYY),
      :due_date => (Time.now + 1.week).to_date.to_s(:MMDDYYYY),
      :description => Babel.random_short.gsub( '&', 'and' )
    )

    new_invoice = user.assigns(:invoice)

    user.enable_profile_taxes
    assert user.profile.tax_enabled, "after enabling taxes profile.tax_enabled was false #{context}"
    user.scratch.fixture_user.reload
    assert user.profile.tax_enabled
    
    user.edits_invoice(new_invoice.id)

    user.deny user.assigns(:invoice).taxes.empty?, "edited invoice taxes was empty #{context}"
    user.deny user.assigns(:invoice).tax_1.enabled, "edited invoice tax_1 was enabled #{context}"
    user.deny user.assigns(:invoice).tax_2.enabled, "edited invoice tax_2 was enabled #{context}"

  end
  
  
  def test_edit_invoice_with_no_taxes_after_disabling_profile_taxes_should_leave_taxes_empty
    context = "when editing invoice with no taxes after enabling then disabling profile taxes"
    user = tax_user(:basic_user)
    deny user.profile.tax_enabled

    user.login
    user.clicks_create_new_invoice

    user.assert user.assigns(:invoice)
    user.assert user.assigns(:invoice).taxes.empty?

    user.saves_new_invoice(
      :customer_id => user.scratch.fixture_user.customers.first.id,
      :date => Time.now.to_date.to_s(:MMDDYYYY),
      :due_date => (Time.now + 1.week).to_date.to_s(:MMDDYYYY),
      :description => Babel.random_short.gsub( '&', 'and' )
    )

    new_invoice = user.assigns(:invoice)

    user.enable_profile_taxes
    assert user.profile.tax_enabled, "after enabling taxes profile.tax_enabled was false #{context}"
    user.disable_profile_taxes
    deny user.profile.tax_enabled, "after enabling taxes profile.tax_enabled was false #{context}"
    

    user.edits_invoice(new_invoice.id)

    user.assert user.assigns(:invoice).taxes.empty?, "edited invoice taxes was not empty #{context}"

  end

  
  ######################### Editing Invoices with unedited taxes #########################
  def test_edit_invoice_with_unedited_enabled_taxes_with_profile_taxes_unchanged
    # show invoice.taxes
      context = "when editing invoice with unedited taxes with profile taxes unchanged"
      user = tax_user(:basic_user)
      user.enable_profile_taxes
      assert user.profile.tax_enabled


      user.login
  #    puts "do click new invoice"
      user.clicks_create_new_invoice

      user.assert user.assigns(:invoice)
      user.assert_taxes(user.assigns(:invoice), "after creating new invoice " + context)

  #    puts "do save invoice"
      user.saves_new_invoice(
        :customer_id => user.scratch.fixture_user.customers.first.id,
        :date => Time.now.to_date.to_s(:MMDDYYYY),
        :due_date => (Time.now + 1.week).to_date.to_s(:MMDDYYYY),
        :description => Babel.random_short.gsub( '&', 'and' )
      )

      new_invoice = user.assigns(:invoice)
      user.assert_taxes(new_invoice, "after saving new invoice " + context)

      new_invoice.reload
#      puts "new_invoice: #{new_invoice.inspect}"
      user.assert_taxes(new_invoice, "after reloading invoice object " + context)
      
  #    puts "do edit invoice with #{new_invoice.id} user.assigns(:invoice): #{user.assigns(:invoice).inspect}"
      user.edits_invoice(new_invoice.id)

  #    puts user.assigns(:invoice).taxes.inspect
      user.deny user.assigns(:invoice).taxes.empty?, "edited invoice taxes was, empty #{context}"
      user.assert_taxes(user.assigns(:invoice), "after editing new invoice " + context)

  end

  def test_edit_invoice_with_unedited_enabled_taxes_with_profile_taxes_now_disabled
    # show invoice.taxes, enabled. So, after disabling taxes in profile, user must disable taxes in any saved invoices individually. Should warn the user about this in profile
      # show invoice.taxes
        context = "when editing invoice with unedited taxes with profile taxes now disabled"
        user = tax_user(:basic_user)
        user.enable_profile_taxes
        assert user.profile.tax_enabled

        user.login
    #    puts "do click new invoice"
        user.clicks_create_new_invoice

        user.assert user.assigns(:invoice)
        user.assert_taxes(user.assigns(:invoice), "after creating new invoice " + context)

    #    puts "do save invoice"
        user.saves_new_invoice(
          :customer_id => user.scratch.fixture_user.customers.first.id,
          :date => Time.now.to_date.to_s(:MMDDYYYY),
          :due_date => (Time.now + 1.week).to_date.to_s(:MMDDYYYY),
          :description => Babel.random_short.gsub( '&', 'and' )
        )

        new_invoice = user.assigns(:invoice)
        user.assert_taxes(new_invoice, "after saving new invoice " + context)

        new_invoice.reload
#        puts "new_invoice: #{new_invoice.inspect}"
        user.assert_taxes(new_invoice, "after reloading invoice object " + context)

        user.disable_profile_taxes
        deny user.profile.tax_enabled, "after enabling taxes profile.tax_enabled was false #{context}"

    #    puts "do edit invoice with #{new_invoice.id} user.assigns(:invoice): #{user.assigns(:invoice).inspect}"
        user.edits_invoice(new_invoice.id)

    #    puts user.assigns(:invoice).taxes.inspect
        user.deny user.assigns(:invoice).taxes.empty?, "edited invoice taxes was, empty #{context}"
        user.assert_taxes(user.assigns(:invoice), "after editing new invoice " + context)

  end

  def test_edit_invoice_with_unedited_enabled_taxes_with_one_profile_tax_now_disabled
    # show invoice.taxes, enabled. So, after disabling taxes in profile, user must disable taxes in any saved invoices individually. Should warn the user about this in profile
      # show invoice.taxes
        context = "when editing invoice with unedited taxes with one profile now disabled"
        user = tax_user(:basic_user)
        user.enable_profile_taxes
        assert user.profile.tax_enabled

        user.login
    #    puts "do click new invoice"
        user.clicks_create_new_invoice

        user.assert user.assigns(:invoice)
        user.assert_taxes(user.assigns(:invoice), "after creating new invoice " + context)

    #    puts "do save invoice"
        user.saves_new_invoice(
          :customer_id => user.scratch.fixture_user.customers.first.id,
          :date => Time.now.to_date.to_s(:MMDDYYYY),
          :due_date => (Time.now + 1.week).to_date.to_s(:MMDDYYYY),
          :description => Babel.random_short.gsub( '&', 'and' )
        )

        new_invoice = user.assigns(:invoice)
        user.assert_taxes(new_invoice, "after saving new invoice " + context)

        new_invoice.reload
#        puts "new_invoice: #{new_invoice.inspect}"
        user.assert_taxes(new_invoice, "after reloading invoice object " + context)
        
        
        # user.disable_profile_taxes
        user.profile.tax_2.name = ''
        user.profile.tax_2.rate = ''
        user.profile.save!
        user.scratch.fixture_user.reload
        deny user.profile.tax_2.enabled, "after disabling profile.tax_2 and reloading it was still enabled #{context}"

    #    puts "do edit invoice with #{new_invoice.id} user.assigns(:invoice): #{user.assigns(:invoice).inspect}"
        user.edits_invoice(new_invoice.id)

    #    puts user.assigns(:invoice).taxes.inspect
        user.deny user.assigns(:invoice).taxes.empty?, "edited invoice taxes was, empty #{context}"
        user.assert_taxes(user.assigns(:invoice), "after editing new invoice taxes should be same and tax_2 should still be enabled " + context)

  end

  def test_edit_invoice_with_unedited_enabled_taxes_with_profile_taxes_now_changed
    #show invoice.taxes, enabled. After changing taxes in profile, user must change taxes in any saved invoices individually. Give user option to update them from the profile taxes.
    context = "when editing invoice with unedited taxes with profile taxes now changed"
    user = tax_user(:basic_user)
    user.enable_profile_taxes
    assert user.profile.tax_enabled

    user.login
#    puts "do click new invoice"
    user.clicks_create_new_invoice

    user.assert user.assigns(:invoice)
    user.assert_taxes(user.assigns(:invoice), "after creating new invoice " + context)

#    puts "do save invoice"
    user.saves_new_invoice(
      :customer_id => user.scratch.fixture_user.customers.first.id,
      :date => Time.now.to_date.to_s(:MMDDYYYY),
      :due_date => (Time.now + 1.week).to_date.to_s(:MMDDYYYY),
      :description => Babel.random_short.gsub( '&', 'and' )
    )

    new_invoice = user.assigns(:invoice)
    user.assert_taxes(new_invoice, "after saving new invoice " + context)

    new_invoice.reload
#    puts "new_invoice: #{new_invoice.inspect}"
    user.assert_taxes(new_invoice, "after reloading invoice object " + context)

    user.profile.tax_1_name = 'alex'
    user.profile.tax_2_rate = 9
    user.profile.save!
    user.scratch.fixture_user.reload
  
#    puts "do edit invoice with #{new_invoice.id} user.assigns(:invoice): #{user.assigns(:invoice).inspect}"
    user.edits_invoice(new_invoice.id)

#    puts user.assigns(:invoice).taxes.inspect
    user.deny user.assigns(:invoice).taxes.empty?, "edited invoice taxes was, empty #{context}"
    user.assert_taxes(user.assigns(:invoice), "after editing new invoice " + context)
    user.assert_not_equal user.profile.tax_1_name, user.assigns(:invoice).tax_1_name, "profile tax_1_name and invoice tax_1_name were still the same " + context
    user.assert_not_equal user.profile.tax_2_rate, user.assigns(:invoice).tax_2_rate, "profile tax_2_rate and invoice tax_2_rate were still the same " + context
  end
  

  ######################### Editing Invoices with edited taxes #########################
  # currently, invoices with edited enabled taxes behave identically to invoices with unedited enabled taxes
  #
  def test_edit_invoice_with_edited_enabled_taxes_with_profile_taxes_unchanged
  # show invoice.taxes. Include a link to use profile taxes.
        context = "when editing invoice with edited taxes with profile taxes unchanged"
        user = tax_user(:basic_user)
        user.enable_profile_taxes
        assert user.profile.tax_enabled

        user.login
    #    puts "do click new invoice"
        user.clicks_create_new_invoice

        user.assert user.assigns(:invoice)
        user.assert_taxes(user.assigns(:invoice), "after creating new invoice " + context)

    #    puts "do save invoice"
        user.saves_new_invoice(
          :customer_id => user.scratch.fixture_user.customers.first.id,
          :date => Time.now.to_date.to_s(:MMDDYYYY),
          :due_date => (Time.now + 1.week).to_date.to_s(:MMDDYYYY),
          :description => Babel.random_short.gsub( '&', 'and' ),
          :tax_1_name => 'custom',
          :tax_2_rate => 9
        )

        new_invoice = user.assigns(:invoice)
        user.assert_taxes(new_invoice, "after saving new invoice " + context, 
            {:tax_2_rate => 9, :tax_2_edited => true, :tax_1_name => 'custom', :tax_1_edited => true})

        new_invoice.reload
  #      puts "new_invoice: #{new_invoice.inspect}"
        user.assert_taxes(new_invoice, "after reloading invoice object " + context,
            {:tax_2_rate => 9, :tax_2_edited => true, :tax_1_name => 'custom', :tax_1_edited => true})

    #    puts "do edit invoice with #{new_invoice.id} user.assigns(:invoice): #{user.assigns(:invoice).inspect}"
        user.edits_invoice(new_invoice.id)

    #    puts user.assigns(:invoice).taxes.inspect
        user.deny user.assigns(:invoice).taxes.empty?, "edited invoice taxes was, empty #{context}"
        user.assert_taxes(user.assigns(:invoice), "after editing new invoice " + context,
            {:tax_2_rate => 9, :tax_2_edited => true, :tax_1_name => 'custom', :tax_1_edited => true})          

  end

  def test_edit_invoice_with_edited_enabled_taxes_with_profile_taxes_now_disabled
    # show invoice.taxes, enabled. So, after disabling taxes in profile, user must disable taxes in any saved invoices individually. Should warn the user about this in profile
    context = "when editing invoice with edited taxes with profile taxes now disabled"
    user = tax_user(:basic_user)
    user.enable_profile_taxes
    assert user.profile.tax_enabled

    user.login
#    puts "do click new invoice"
    user.clicks_create_new_invoice

    user.assert user.assigns(:invoice)
    user.assert_taxes(user.assigns(:invoice), "after creating new invoice " + context)

#    puts "do save invoice"
    user.saves_new_invoice(
      :customer_id => user.scratch.fixture_user.customers.first.id,
      :date => Time.now.to_date.to_s(:MMDDYYYY),
      :due_date => (Time.now + 1.week).to_date.to_s(:MMDDYYYY),
      :description => Babel.random_short.gsub( '&', 'and' ),
      :tax_1_name => 'custom',
      :tax_2_rate => 9
    )

    new_invoice = user.assigns(:invoice)
    user.assert_taxes(new_invoice, "after saving new invoice " + context, 
        {:tax_2_rate => 9, :tax_2_edited => true, :tax_1_name => 'custom', :tax_1_edited => true})

    new_invoice.reload
#      puts "new_invoice: #{new_invoice.inspect}"
    user.assert_taxes(new_invoice, "after reloading invoice object " + context,
        {:tax_2_rate => 9, :tax_2_edited => true, :tax_1_name => 'custom', :tax_1_edited => true})



    user.disable_profile_taxes
    deny user.profile.tax_enabled, "after enabling taxes profile.tax_enabled was false #{context}"

#    puts "do edit invoice with #{new_invoice.id} user.assigns(:invoice): #{user.assigns(:invoice).inspect}"
    user.edits_invoice(new_invoice.id)

#    puts user.assigns(:invoice).taxes.inspect
    user.deny user.assigns(:invoice).taxes.empty?, "edited invoice taxes was, empty #{context}"
    user.assert_taxes(user.assigns(:invoice), "after editing new invoice " + context,
        {:tax_2_rate => 9, :tax_2_edited => true, :tax_1_name => 'custom', :tax_1_edited => true})          

  end

  def test_edit_invoice_with_edited_enabled_taxes_with_profile_taxes_now_changed
    #show invoice.taxes, enabled. After changing taxes in profile, user must change taxes in any saved invoices individually. Give user option to update them from the profile taxes.
    context = "when editing invoice with edited taxes with profile taxes now changed"
    user = tax_user(:basic_user)
    user.enable_profile_taxes
    assert user.profile.tax_enabled

    user.login
#    puts "do click new invoice"
    user.clicks_create_new_invoice

    user.assert user.assigns(:invoice)
    user.assert_taxes(user.assigns(:invoice), "after creating new invoice " + context)

#    puts "do save invoice"
    user.saves_new_invoice(
      :customer_id => user.scratch.fixture_user.customers.first.id,
      :date => Time.now.to_date.to_s(:MMDDYYYY),
      :due_date => (Time.now + 1.week).to_date.to_s(:MMDDYYYY),
      :description => Babel.random_short.gsub( '&', 'and' ),
      :tax_1_name => 'custom',
      :tax_2_rate => 10
    )

    new_invoice = user.assigns(:invoice)
    user.assert_taxes(new_invoice, "after saving new invoice " + context, 
        {:tax_2_rate => 10, :tax_2_edited => true, :tax_1_name => 'custom', :tax_1_edited => true})

    new_invoice.reload
#    puts "new invoice: #{user.assigns(:invoice).taxes.inspect}"
    user.assert_taxes(new_invoice, "after reloading invoice object " + context,
        {:tax_2_rate => 10, :tax_2_edited => true, :tax_1_name => 'custom', :tax_1_edited => true})



    user.profile.tax_1_name = 'alex'
    user.profile.tax_2_rate = 9
    user.profile.save!
    user.scratch.fixture_user.reload

#    puts "do edit invoice with #{new_invoice.id} user.assigns(:invoice): #{user.assigns(:invoice).inspect}"
    user.edits_invoice(new_invoice.id)

#    puts "edited invoice: #{user.assigns(:invoice).taxes.inspect}"
    user.deny user.assigns(:invoice).taxes.empty?, "edited invoice taxes was, empty #{context}"
    user.assert_taxes(user.assigns(:invoice), "after editing new invoice " + context,
        {:tax_2_rate => 10, :tax_2_edited => true, :tax_1_name => 'custom', :tax_1_edited => true})
    user.assert_not_equal user.profile.tax_1_name, user.assigns(:invoice).tax_1_name, "profile tax_1_name and invoice tax_1_name were still the same " + context
    user.assert_not_equal user.profile.tax_2_rate, user.assigns(:invoice).tax_2_rate, "profile tax_2_rate and invoice tax_2_rate were still the same " + context
  end

  def test_initial_profile_has_tax_disabled_create_invoice_then_enable_taxes
    #FIXME -- why doesn't this test use the tax_user session?
    @user = users(:basic_user)  

    stub_cas_logged_in @user

    @user.profile.tax_enabled = "0"
    @user.profile.tax_1_name = ""
    @user.profile.tax_1_rate = "0.00"
    @user.profile.tax_2_name = ""
    @user.profile.tax_2_rate = "0.00"
    @user.profile.save!
    
    deny @user.profile.tax_enabled
    
    
    
    post '/invoices', 
      :cover_tax_1=>"tax_1",
      :cover_tax_2=>"tax_2",     
      :invoice=>
        {
          :tax_1_enabled=>"0",
          :tax_2_enabled=>"0", 
          :reference=>"",
          :date=>"2008-07-23", 
          :tax_2_rate=>"0.0", 
          :tax_1_rate=>"0.0", 
          :discount_type=>"percent", 
          :customer_id=>"", 
          :description=>"bobs invoice", 
          :due_date=>"", 
          :discount_value=>"", 
          :unique=>"100", 
          :currency=>"CAD",
          :line_items_attributes=>[
            {:row_id=>"line_item_new_1", 
            :tax_1_enabled=>"false",
            :tax_2_enabled=>"false", 
            :price=>"100.00", 
            :should_destroy=>"0", 
            :unit=>"Each", 
            :quantity=>"1", 
            :description=>""
          }], 
        }, :id => "invoice"
   
    @invoice = Invoice.find(:first, :conditions => {:description => "bobs invoice"})

    #since both taxes were blank and profile has no taxes, @invoice should have no taxes
    #might want to ref at how clean_up_taxes works in @invoice, and fix if its wrong
    assert @invoice.tax_1.nil?
    assert @invoice.tax_2.nil?
    
    @user.profile.tax_enabled = "1"
    @user.profile.tax_1_name = "GST"
    @user.profile.tax_1_rate = "5.00"
    @user.profile.tax_2_name = "PST"
    @user.profile.tax_2_rate = "7.00"
    @user.profile.save!              

    assert @user.profile.tax_enabled

    
    put "/invoices/#{@invoice.id}", 
      :cover_tax_1=>"tax_1",
      :cover_tax_2=>"tax_2",     
      :invoice=>
        {
          :tax_1_enabled=>"1",
          :tax_2_enabled=>"1", 
          :reference=>"",
          :date=>"2008-07-23", 
          :tax_2_rate=>"5.0", 
          :tax_1_rate=>"7.0", 
          :discount_type=>"percent", 
          :customer_id=>"", 
          :description=>"", 
          :due_date=>"", 
          :discount_value=>"", 
          :unique=>"100", 
          :currency=>"CAD",
          :line_items_attributes=>[
            {:row_id=>"line_item_1", 
            :tax_1_enabled=>"true",
            :tax_2_enabled=>"true", 
            :price=>"100.00", 
            :should_destroy=>"0", 
            :unit=>"Each", 
            :quantity=>"1", 
            :description=>""
          }], 
        }   
    #invoice should now have both taxes    
    @invoice.reload

    puts "@invoice.taxes: #{@invoice.taxes.inspect}" if $log_on

    assert !@invoice.tax_1.nil?
    assert !@invoice.tax_2.nil?
  
  end
  
  ######################### Recalculating Invoices with taxes #########################
  # currently, invoices with edited enabled taxes behave identically to invoices with unedited enabled taxes
  #
  
  # def test_recalculations_in_new_invoice_with_no_taxes
  #   flunk("not yet implement. comment out @invoice.setup_taxes in invoicesController.recalculate to get failing examples")    
  # end
  # 
  # def test_recalculations_in_new_invoice_with_profile_taxes
  #   flunk("not yet implement. comment out @invoice.setup_taxes in invoicesController.recalculate to get failing examples")    
  # end
  # 
  # def test_recalculations_in_new_invoice_with_custom_taxes
  #   flunk("not yet implement. comment out @invoice.setup_taxes in invoicesController.recalculate to get failing examples")    
  # end
  # 
  # def test_recalculations_in_edited_invoice_with_no_taxes
  #   flunk("not yet implement. comment out @invoice.setup_taxes in invoicesController.recalculate to get failing examples")    
  # end
  # 
  # def test_recalculations_in_edited_invoice_with_profile_taxes
  #   flunk("not yet implement. comment out @invoice.setup_taxes in invoicesController.recalculate to get failing examples")    
  # end
  # 
  # def test_recalculations_in_edited_invoice_with_custom_taxes
  #   flunk("not yet implement. comment out @invoice.setup_taxes in invoicesController.recalculate to get failing examples")    
  # end
  # 
  protected
  
    
  
  def tax_user(key, options={})
    user = open_session do |user|
      def user.login
        self.delegate.stub_cas_logged_in scratch.fixture_user #RADAR -- ok because only 1 integration session per test
      end
      
      def user.scratch
        @scratch ||= OpenStruct.new
      end

      def user.enable_profile_taxes(options={:tax_1_name => 'bob', :tax_1_rate => 3.2, :tax_2_name => 'mary', :tax_2_rate => 4.8})
        profile.tax_enabled = true
        profile.tax_1_name = options[:tax_1_name]
        profile.tax_1_rate = options[:tax_1_rate]
        profile.tax_2_name = options[:tax_2_name]
        profile.tax_2_rate = options[:tax_2_rate]
        assert profile.save, "when enabling profile taxes, profile.save returned false"
      end
      
      def user.disable_profile_taxes
        profile.tax_enabled = false
        assert profile.save, "when disabling profile taxes, profile.save returned false"
      end

      def user.profile
        scratch.fixture_user.profile
      end

      def user.change_profile_taxes(options)
        put 'profiles/update', :profile => options
      end

      def user.clicks_create_new_invoice
        get '/invoices/new/invoice'
        assert_response :success
      end

      def user.saves_new_invoice(options = {})
        post_via_redirect '/invoices', :invoice => options
        assert_response :success
      end

      def user.edits_invoice(id)
        get edit_invoice_path(id)
      end

      def user.assert_taxes(object, context, overrides={})
        values = {
          :tax_1_name => 'bob',
          :tax_1_rate => BigDecimal.new('3.2'),
          :tax_1_enabled => true,
          :tax_2_name => 'mary',
          :tax_2_rate => BigDecimal.new('4.8'),
          :tax_2_enabled => true,
          :tax_1_edited => false,
          :tax_2_edited => false
        }.merge(overrides)
        assert assigns(:invoice).tax_for_key('tax_1'), "invoice did not have a tax_1 #{context}"
        assert_equal values[:tax_1_enabled], object.tax_for_key('tax_1').enabled, "invoice tax_1.enabled was not #{values[:tax_1_enabled]} #{context}"
        assert_equal values[:tax_1_name], object.tax_for_key('tax_1').name, "invoice tax_1 name was not correctly copied #{context}"
        assert_equal values[:tax_1_rate], object.tax_for_key('tax_1').rate, "invoice tax_1 rate was not correctly copied #{context}"

        assert assigns(:invoice).tax_for_key('tax_2'), "invoice did not have a tax_2 #{context}"
        assert_equal values[:tax_2_enabled], object.tax_for_key('tax_2').enabled, "invoice tax_2.enabled was not #{values[:tax_2_enabled]} #{context}"
        assert_equal values[:tax_2_name], object.tax_for_key('tax_2').name, "invoice tax_2 name was not correctly copied #{context}"
        assert_equal values[:tax_2_rate], object.tax_for_key('tax_2').rate, "invoice tax_2 rate was not correctly copied #{context}"
        
        if values[:tax_1_edited]
          assert object.tax_for_key('tax_1').edited, "invoice tax_1.edited was false #{context}"
        else
          deny object.tax_for_key('tax_1').edited, "invoice tax_1.edited was false #{context}"
        end

        if values[:tax_2_edited]
          assert object.tax_for_key('tax_2').edited, "invoice tax_2.edited was true #{context}"
        else
          deny object.tax_for_key('tax_2').edited, "invoice tax_2.edited was true #{context}"
        end
      end
    end
    user.scratch.fixture_user = users(key)
    user.scratch.options = options
    user
  end
  
end
