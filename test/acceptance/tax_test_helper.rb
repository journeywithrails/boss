module Sage
  module TaxTestHelper
  
    def update_profile_taxes(fields)
      @user.goto_profile_url
      assert_equal "Profiles: edit", @user.title            
      @user.link(:id, 'user_taxes_link').click
      enter_profile_tax_data(fields)
      $test_ui.agree('continue?', true) if @debug
      update_profile
      if @debug
        p "@user.class = #{@user.user.class}"
      end
      @profile = @user.user.profile    
    end
  
    
    def enter_profile_tax_data(fields)
      fields.each_pair do |field, value|
        case field.to_s
        # tax_enabled and discount_before_tax are check_boxes
        when 'tax_enabled', 'discount_before_tax' then
          assert @user.checkbox(:id, "profile_#{field.to_s}").exists?, "can't find field profile_#{field.to_s}"
          if value
            @user.checkbox(:id, "profile_#{field.to_s}").set          
          else
            @user.checkbox(:id, "profile_#{field.to_s}").clear
          end
        # all the other profile tax fields are textboxes  
        else
          assert @user.text_field(:id, "profile_#{field.to_s}").exists?, "can't find field profile_#{field.to_s}"
          @user.text_field(:id, "profile_#{field.to_s}").value=(value.to_s)
        end
      end
    end  
  
    def update_profile
      @user.submits
      @user.wait
      assert_equal "Profiles: update", @user.title            
    end
    
    def assert_tax_enabled_name_and_rate_exist(exist, message, fields)
      $test_ui.agree('assert_tax_enabled_name_and_rate_exist?', true) if @debug
      fields.each_pair do |field, value|
        debug_field_value(field, value)
        case field.to_s
        when 'tax_1_enabled', 'tax_2_enabled'
          assert((@user.checkbox(:id, "invoice_#{field.to_s}").exists? == exist), message + " #{field} was #{(exist ? 'not there' : 'still there')}")
        when 'tax_1_name', 'tax_2_name'
          # get the text from the tax div and 
          # check if the tax names exist
          tax_container = @user.div(:id, 'tax_container')
          assert_not_nil((tax_container), message + " the tax_container div was missing")
          
          tax_container_text = tax_container.text
          if @debug
            puts("tax_container.text = #{tax_container.text}")
          end
          
          # check if the tax name is not displayed, use negative logic with the exist parameter 
          assert((tax_container_text.index(value.to_s).nil? != exist), message + " #{field} was #{ exist ? 'not found' : 'found'}")
        else             
          assert((@user.text_field(:id, "invoice_#{field.to_s}").exists? == exist), message + " #{field} was #{ exist ? 'not found' : 'found'}")
        end  
      end
    end
  
    def deny_tax_enabled_name_and_rate_exist(message, fields)
      assert_tax_enabled_name_and_rate_exist(false, message, fields)
    end
    
    def affirm_tax_enabled_name_and_rate_exist(message, fields)
      assert_tax_enabled_name_and_rate_exist(true, message, fields)
    end
    
    def add_standard_invoice_and_click_submit
      add_standard_invoice
      click_submit
      @standard_invoice = Invoice.find_by_unique('ApplyTax')                  
    end
  
    def goto_new_invoice_url
      @user.creates_new_invoice
      assert_equal "Invoices: new", @user.title    
    end
  
    def add_standard_invoice
      
      enter_new_invoice_data(
                :unique => "ApplyTax",
                :date => "December 26, 2007",
                :reference => "Test",
                :description => "test",
                :discount_type => "percent",
                :discount_value => "2.0",
                :line_item_attributes_name => "Item ",
                :line_item_attributes_description => "Description ",
                :line_item_attributes_quantity => 1.0,
                :line_item_attributes_price => 1.11,
                :number_of_line_items => 3
                )
                
    end

    def add_standard_oneline_invoice

      enter_new_invoice_data(
                :unique => "ApplyTax",
                :date => "December 26, 2007",
                :reference => "Test",
                :description => "test",
                :discount_type => "percent",
                :discount_value => "2.0",
                :line_item_attributes_name => "Item ",
                :line_item_attributes_description => "Description ",
                :line_item_attributes_quantity => 14,
                :line_item_attributes_price => 1.11,
                :number_of_line_items => 1
                )

    end
    
    def click_submit
      assert_difference 'Invoice.count' do
        assert_difference 'LineItem.count', @number_of_line_items do
          @user.submits        
        end
      end
    end
    
    def enter_new_invoice_data(fields)
      #Create new Invoice and fill it up
      puts "enter_new_invoice_data" if $log_on
      goto_new_invoice_url
      
      customer_name = 'Test 10 Customer ' + DateTime.now().to_s
      
      @user.enter_new_customer( 
        :name => customer_name
        )    
      
      enter_invoice_fields(fields)
      
      puts "enter_new_invoice_data: add line items" if $log_on
      # Add line items 
      # Multiply the qty and price times the line number for different totals
      (1..@number_of_line_items).each do | i |
        if i == 1 
           @user.edits_line_item(i, 
            :unit => @name + i.to_s,
            :description => @description + i.to_s,
            :quantity => (@quantity * i).to_s,
            :price => (@price * i).to_s)       
        else
          assert_equal i, @user.adds_line_item(
              :unit => @name + i.to_s,
              :description => @description + i.to_s,
              :quantity => (@quantity * i).to_s,
              :price => (@price * i).to_s)
        end
      end
    end 
    
    def edit_invoice_data(fields)
      enter_invoice_fields(fields)
    end
    
    def enter_invoice_fields(fields)
      fields.each_pair do |field, value|
      
        debug_field_value(field, value)
      
        case field.to_s
        # discount type is a select
        when 'discount_type' 
          case value
          when 'amount'
            @user.select_list(:id, "invoice_discount_type").option(:text, "amount").select      
          else
            @user.select_list(:id, "invoice_discount_type").option(:text, "percent").select      
          end
        # tax_1_enabled, tax_2_enabled
        when 'tax_1_enabled', 
             'tax_2_enabled'
          if value
            @user.checkbox(:id, "invoice_#{field.to_s}").set          
          else
            @user.checkbox(:id, "invoice_#{field.to_s}").clear
          end
        when 'line_item_attributes_name'
          @name = value
        when 'line_item_attributes_description'
          @description = value
        when 'line_item_attributes_quantity'
          @quantity = value
        when 'line_item_attributes_price'
          @price = value
        when 'number_of_line_items'
          @number_of_line_items = value
        else
          e = @user.text_field(:id, "invoice_#{field.to_s}")
          assert e.exists?, "tried to set an invalid invoice field #{field.to_s}"
          @user.populate(e, value.to_s)
          @user.wait()
        end
      end
    end  
    
    def verify_invoice_view_fields(fields)   
      fields.each_pair do |field, value|
        debug_field_value(field, value)
        case field.to_s
        when 'tax_1_name', 
             'tax_2_name'
          # get the text from the tax div and 
          # check if the tax names exist
          tax_container = @user.div(:id, 'tax_container')
          assert_not_nil(tax_container)
          
          tax_container_text = tax_container.text
          if @debug
            p("tax_container.text = #{tax_container.text}")
          end
          
          assert_not_nil(tax_container_text.index(value.to_s))
        when 'tax_1_enabled', 
             'tax_2_enabled'
          if @debug
            p "@user.text_field(:id, 'invoice_#{field.to_s}').value = " + @user.text_field(:id, "invoice_#{field.to_s}").value      
          end
          checkbox_value = @user.checkbox(:id, "invoice_#{field.to_s}").value
          checkbox_bool = checkbox_value == 0 ? false : true
          if @debug
            p "checkbox_value = #{checkbox_value}"
            p "checkbox_bool = #{checkbox_bool}"          
          end
          # compare value as a boolean, not a string
          assert_equal(value, checkbox_bool) 
        # the tax summary fields are spans
        when 'total_amount'
          assert_equal(format_amount(value).to_s, @user.span(:id, "invoice_total").text)          
        when 'line_items_total', 
             'tax_1_amount',
             'tax_2_amount',
             'discount_amount',
             'total'
          if @debug
            p "@user.span(:id, 'invoice_#{field.to_s}').value = " + @user.span(:id, "invoice_#{field.to_s}").text
          end
          assert_equal(format_amount(value).to_s, @user.span(:id, "invoice_#{field.to_s}").text)                     
        else
          if @debug
            p "@user.text_field(:id, 'invoice_#{field.to_s}').value = " + @user.text_field(:id, "invoice_#{field.to_s}").value      
          end
          assert_equal BigDecimal.new(value.to_s), BigDecimal.new(@user.text_field(:id, "invoice_#{field.to_s}").value) 
          # assert_equal(format_amount(value).to_s, @user.text_field(:id, "invoice_#{field.to_s}").value)          
        end
      end
    end
    
    def verify_invoice_preview_fields(fields)   
      fields.each_pair do |field, value|
        debug_field_value(field, value)
          if @debug
            p "@user.span(:id, 'invoice_#{field.to_s}').value = " + @user.span(:id, "invoice_#{field.to_s}").text
          end           
          assert @user.span(:id, "invoice_#{field.to_s}").text.include?(format_amount(value).to_s)
      end
    end
    
    def verify_invoice_tax_data_fields(i, fields)   
      fields.each_pair do |field, value|
        debug_field_value(field, value)
        assert_equal(value.to_s, format_amount(i.send(field)))          
      end
    end
  
    def debug_field_value(field, value)
      if @debug
        p "field = #{field.to_s} value = #{value}"
      end
    end
    
    def add_standard_invoice_update_tax_and_verify(expected_before, expected_after, &block)
      $test_ui.agree('add_standard_invoice?', true) if $debug
      
      add_standard_oneline_invoice
      $debug=false
      $test_ui.agree('verify_invoice_view_fields with before?', true) if $debug
      
      verify_invoice_view_fields(
                :line_items_total => expected_before[:line_items_total],
                :tax_1_amount => expected_before[:tax_1_amount],
                :tax_2_amount => expected_before[:tax_2_amount],
                :discount_amount => expected_before[:discount_amount],
                :total_amount => expected_before[:total])    
      
      $test_ui.agree('yield?', true) if @debug
      yield
  
      $test_ui.agree('verify_invoice_view_fields with after?', true) if $debug
      verify_invoice_view_fields(
                :line_items_total => expected_after[:line_items_total],
                :tax_1_amount => expected_after[:tax_1_amount],
                :tax_2_amount => expected_after[:tax_2_amount],
                :discount_amount => expected_after[:discount_amount],
                :total_amount => expected_after[:total])    
      $debug=false
    end
    
    def edit_standard_invoice_update_tax_and_verify(expected_before, expected_after, &block)  
      
      @user.edits_invoice(invoices(:discount_before_tax_invoice).id)
      
      verify_invoice_view_fields(
                :line_items_total => expected_before[:line_items_total],
                :tax_1_amount => expected_before[:tax_1_amount],
                :tax_2_amount => expected_before[:tax_2_amount],
                :discount_amount => expected_before[:discount_amount],
                :total_amount => expected_before[:total])    
      
      yield
  
      verify_invoice_view_fields(
                :line_items_total => expected_after[:line_items_total],
                :tax_1_amount => expected_after[:tax_1_amount],
                :tax_2_amount => expected_after[:tax_2_amount],
                :discount_amount => expected_after[:discount_amount],
                :total_amount => expected_after[:total])    
    
    end
    
    def uncheck_both_taxes
      uncheck_tax_1
      uncheck_tax_2
    end
    
    def uncheck_tax_1
      @user.expects_ajax(1) do
        edit_invoice_data(
              :tax_1_enabled => false
        )
      end
    end
  
    def uncheck_tax_2
      @user.expects_ajax(1) do    
        edit_invoice_data(
              :tax_2_enabled => false
        )
      end
    end
    
    def change_tax_1_rate(rate)
      @user.expects_ajax(1) do    
        edit_invoice_data(
              :tax_1_rate => rate
        )
      end
    end
    
    def change_tax_2_rate(rate)
      @user.expects_ajax(1) do    
        edit_invoice_data(
              :tax_2_rate => rate
        )
      end
    end
    
    def change_discount_amount(amount) 
      @user.expects_ajax(1) do    
        edit_invoice_data(
              :discount_type => 'amount'
        )
      end
      @user.expects_ajax(1) do    
        edit_invoice_data(
              :discount_value => amount            
        )
      end
    end
  
    def change_discount_percent(percent)
      edit_invoice_data(
            :discount_type => 'percent'
      )
      @user.expects_ajax(1) do    
        edit_invoice_data(
              :discount_value => percent                      
        )
      end
    end
    
    def change_discount_amount_and_rates(amount, tax_1_rate, tax_2_rate)
      change_discount_amount(amount) 
      change_tax_1_rate(tax_1_rate)    
      change_tax_2_rate(tax_2_rate)        
    end
    
    def change_discount_percent_and_rates(percent, tax_1_rate, tax_2_rate)
      change_discount_percent(percent) 
      change_tax_1_rate(tax_1_rate)    
      change_tax_2_rate(tax_2_rate)        
    end

  end
end
