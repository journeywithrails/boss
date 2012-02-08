$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'

# Test cases for User Story 38
# Manage my Company Information

# Description:As a user, I want to manage my company information
# so that the Invoice I sent out include my company identity

class CompanyInformationTest < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :users, :invoices, :customers

  def setup
    @user = watir_session.with(:user_without_profile)
    @user.logs_in  
  end
  
  def teardown
    @user.teardown
  end

  # 1. Invoice includes Company Address Information
  def test_company_address_information
    	# Fill up Profile Information
  	@user.goto(@user.profile_url)	
  	fills_company_information_for @user	
  	@user.submits
  	
  	assert_not_nil @user.contains_text("Your settings were successfully updated")
  	
  	# Create an Invoice
  	add_invoice  	
  	assert_not_nil @user.contains_text("Invoice was successfully created"), "invoice NOT successfully created"
  	  
      # Verify that Invoce includes the company's address info
  	checks_company_information(:name => "The Companys Name",
  							   :address1 => "The Companys Address 1",
  							   :address2 => "The Companys Address 2",
  							   :city => "The Companys City",
  							   :state => "The Companys State",
  							   :country => "Aruba",	
  							   :phone => "(604)-657-9087",
  							   :fax => "(604)-657-9088")
  end

  # 2.1 Users add their company logo in a jpg format
  def test_company_address_information_plus_logo_jpg
    	# Fill up Profile Information
  	@user.goto(@user.profile_url)	
  	fills_company_information_for @user	
  	@user.submits
	@user.goto(@user.site_url + '/logo_settings/')
	@user.b.wait
  	# Add jpg logo
  	file_name = "logo_1.jpg"
  	path = Dir.getwd + '/public/images/testimages/' + file_name	
  	realpath = path.gsub('/', '\\')
  
  	#simulate choosing a file 
  	# TODO - else part (Only pass string path to file_field
      if (WatirBrowser.ie?)
  		@user.file_field(:id, 'logo_uploaded_data').click_no_wait
  		startClicker(@user, "&Open",10,realpath)	
  		@user.wait
  	else
  	  @user.populate(@user.file_field(:id, 'logo_uploaded_data'), (path))
  	end
  		
  	@user.submits
  	
  	assert_not_nil @user.contains_text("Your settings were successfully updated")
  	
  	# Create an Invoice
  	add_invoice  	
  	assert_not_nil @user.contains_text("Invoice was successfully created"), "invoice NOT successfully created"
  	  
      # Verify that Invoce includes the company's address info
  	checks_company_information(:name => "The Companys Name",
  							   :address1 => "The Companys Address 1",
  							   :address2 => "The Companys Address 2",
  							   :city => "The Companys City",
  							   :state => "The Companys State",
  							   :country => "Aruba",	
  							   :phone => "(604)-657-9087",
  							   :fax => "(604)-657-9088")
  							   
  	# Verify that logo_1 is the current image in the Invoice
  	assert @user.image(:alt, /(L|l)ogo_1/).exist?
  end

  # 2.2 Users add their company logo in a gif format
  def test_company_address_information_plus_logo_gif
  	# Fill up Profile Information
  	@user.goto(@user.profile_url)	
  	fills_company_information_for @user	
  	@user.submits
	@user.goto(@user.site_url + '/logo_settings/')
	@user.b.wait
  	# Add gif logo
  	file_name = "logo_3.gif"
  	path = Dir.getwd + '/public/images/testimages/' + file_name	
  	realpath = path.gsub('/', '\\')
  
  	#simulate choosing a file 
  	# TODO - else part (Only pass string path to file_field
      if (WatirBrowser.ie?)
  		@user.file_field(:id, 'logo_uploaded_data').click_no_wait
  		startClicker(@user, "&Open",10,realpath)	
  		@user.wait
  	else
  	  @user.populate(@user.file_field(:id, 'logo_uploaded_data'),(path))
  	end

  	@user.submits
  	

  	assert_not_nil @user.contains_text("Your settings were successfully updated")
  	
  	# Create an Invoice
  	add_invoice  	
  	assert_not_nil @user.contains_text("Invoice was successfully created"), "invoice NOT successfully created"
  	  
      # Verify that Invoce includes the company's address info
  	checks_company_information(:name => "The Companys Name",
  							   :address1 => "The Companys Address 1",
  							   :address2 => "The Companys Address 2",
  							   :city => "The Companys City",
  							   :state => "The Companys State",
  							   :country => "Aruba",	
  							   :phone => "(604)-657-9087",
  							   :fax => "(604)-657-9088")
  							   
  	# Verify that logo_1 is the current image in the Invoice
  	assert @user.image(:alt, /(L|l)ogo_3/).exist?
  end

  # 2.3 Users add their company logo in a png format
  def test_company_address_information_plus_logo_png
  	# Fill up Profile Information
  	@user.goto(@user.profile_url)	
  	fills_company_information_for @user	
  	@user.submits
	@user.goto(@user.site_url + '/logo_settings/')
	@user.b.wait
  	# Add png logo
  	file_name = "logo_5.png"
  	path = Dir.getwd + '/public/images/testimages/' + file_name	
  	realpath = path.gsub('/', '\\')
  
  	#simulate choosing a file 
  	# TODO - else part (Only pass string path to file_field
    if (WatirBrowser.ie?)
  		@user.file_field(:id, 'logo_uploaded_data').click_no_wait
  		startClicker(@user, "&Open",10,realpath)	
  		@user.wait
  	else
  	  @user.populate(@user.file_field(:id, 'logo_uploaded_data'),(path))
  	end
  			
  	@user.submits
  	
  	assert_not_nil @user.contains_text("Your settings were successfully updated")
  	
  	# Create an Invoice
  	add_invoice  	
  	assert_not_nil @user.contains_text("Invoice was successfully created"), "invoice NOT successfully created"
  	  
      # Verify that Invoce includes the company's address info
  	checks_company_information(:name => "The Companys Name",
  							   :address1 => "The Companys Address 1",
  							   :address2 => "The Companys Address 2",
  							   :city => "The Companys City",
  							   :state => "The Companys State",
  							   :country => "Aruba",	
  							   :phone => "(604)-657-9087",
  							   :fax => "(604)-657-9088")
  							   
  	# Verify that logo_1 is the current image in the Invoice
  	assert @user.image(:alt, /(L|l)ogo_5/).exist?
  end
  
  # 3.1 Users can remove their company logo form their invoice
  def test_company_address_information_plus_logo_remove_jpg
  	# Fill up Profile Information
  	@user.goto(@user.profile_url)	
  	fills_company_information_for @user	
  	
  	# Add jpg logo
  	file_name = "logo_2.jpg"
  	path = Dir.getwd + '/public/images/testimages/' + file_name	
  	realpath = path.gsub('/', '\\')
    @user.submits
	@user.goto(@user.site_url + '/logo_settings/')
	@user.b.wait
  	#simulate choosing a file 
  	# TODO - else part (Only pass string path to file_field
      if (WatirBrowser.ie?)
  		@user.file_field(:id, 'logo_uploaded_data').click_no_wait
  		startClicker(@user, "&Open",10,realpath)	
  		@user.wait
  	else
  	  @user.populate(@user.file_field(:id, 'logo_uploaded_data'),(path))
  	end
  			
  	@user.submits
  	
  	assert_not_nil @user.contains_text("Your settings were successfully updated")
  	
  	# Create an Invoice
  	add_invoice  	
  	assert_not_nil @user.contains_text("Invoice was successfully created"), "invoice NOT successfully created"
  	  
      # Verify that Invoce includes the company's address info
  	checks_company_information(:name => "The Companys Name",
  							   :address1 => "The Companys Address 1",
  							   :address2 => "The Companys Address 2",
  							   :city => "The Companys City",
  							   :state => "The Companys State",
  							   :country => "Aruba",	
  							   :phone => "(604)-657-9087",
  							   :fax => "(604)-657-9088")
  							   
  	# Verify that logo_1 is the current image in the Invoice
  	assert @user.image(:alt, /(L|l)ogo_2/).exist?
  	
  	# Remove Logo
	@user.goto(@user.site_url + '/logo_settings/')
	@user.b.wait
  	@user.checkbox(:id, "logo[delete]").set(true)
  	@user.submits
  	
  	assert_not_nil @user.contains_text("Your settings were successfully updated")
  	
  	# Verify Logo is not shown in Invoice
  	last_invoice = Invoice.find(:first, :order => "id DESC")
  	@user.displays_invoice_list()
  	@user.shows_invoice(last_invoice.id)
  	
  	assert !@user.image(:alt, /(L|l)ogo_2/).exist?
  end

  # 3.2 Users can remove their company logo form their invoice
  def test_company_address_information_plus_logo_remove_gif
  	# Fill up Profile Information
  	@user.goto(@user.profile_url)	
  	fills_company_information_for @user	
  	
  	# Add gif logo
  	file_name = "logo_4.gif"
  	path = Dir.getwd + '/public/images/testimages/' + file_name	
  	realpath = path.gsub('/', '\\')
    @user.submits
	@user.goto(@user.site_url + '/logo_settings/')
	@user.b.wait
  	#simulate choosing a file 
  	# TODO - else part (Only pass string path to file_field
      if (WatirBrowser.ie?)
  		@user.file_field(:id, 'logo_uploaded_data').click_no_wait
  		startClicker(@user, "&Open",10,realpath)	
  		@user.wait
  	else
  	  @user.populate(@user.file_field(:id, 'logo_uploaded_data'),(path))
  	end
  			
  	@user.submits
  	
  	assert_not_nil @user.contains_text("Your settings were successfully updated")
  	
  	# Create an Invoice
  	add_invoice  	
  	assert_not_nil @user.contains_text("Invoice was successfully created"), "invoice NOT successfully created"
  	  
      # Verify that Invoce includes the company's address info
  	checks_company_information(:name => "The Companys Name",
  							   :address1 => "The Companys Address 1",
  							   :address2 => "The Companys Address 2",
  							   :city => "The Companys City",
  							   :state => "The Companys State",
  							   :country => "Aruba",	
  							   :phone => "(604)-657-9087",
  							   :fax => "(604)-657-9088")
  							   
  	# Verify that logo_1 is the current image in the Invoice
  	assert @user.image(:alt, /(L|l)ogo_4/).exist?
  	
  	# Remove Logo
	@user.goto(@user.site_url + '/logo_settings/')
	@user.b.wait
  	@user.checkbox(:id, "logo[delete]").set(true)
  	@user.submits
  	
  	assert_not_nil @user.contains_text("Your settings were successfully updated")
  	
  	# Verify Logo is not shown in Invoice
  	last_invoice = Invoice.find(:first, :order => "id DESC")
  	@user.displays_invoice_list()
  	@user.shows_invoice(last_invoice.id)
  	
  	assert !@user.image(:alt, /(L|l)ogo_4/).exist?
  end

  # 3.3 Users can remove their company logo form their invoice
  def test_company_address_information_plus_logo_remove_png
  	# Fill up Profile Information
  	@user.goto(@user.profile_url)	
  	fills_company_information_for @user	
  	
  	# Add png logo
  	file_name = "logo_6.png"
  	path = Dir.getwd + '/public/images/testimages/' + file_name	
  	realpath = path.gsub('/', '\\')
    @user.submits
	@user.goto(@user.site_url + '/logo_settings/')
	@user.b.wait
  	#simulate choosing a file 
  	# TODO - else part (Only pass string path to file_field
      if (WatirBrowser.ie?)
  		@user.file_field(:id, 'logo_uploaded_data').click_no_wait
  		startClicker(@user, "&Open",10,realpath)	
  		@user.wait
  	else
  	  @user.file_field(:id, 'logo_uploaded_data').set(path)
  	end
  			
  	@user.submits
  	
  	assert_not_nil @user.contains_text("Your settings were successfully updated")
  	
  	# Create an Invoice
  	add_invoice  	
  	assert_not_nil @user.contains_text("was successfully created"), "invoice NOT successfully created"
  	  
      # Verify that Invoce includes the company's address info
  	checks_company_information(:name => "The Companys Name",
  							   :address1 => "The Companys Address 1",
  							   :address2 => "The Companys Address 2",
  							   :city => "The Companys City",
  							   :state => "The Companys State",
  							   :country => "Aruba",	
  							   :phone => "(604)-657-9087",
  							   :fax => "(604)-657-9088")
  							   
  	# Verify that logo_1 is the current image in the Invoice
  	assert @user.image(:alt, /(L|l)ogo_6/).exist?
  	
  	# Remove Logo
	@user.goto(@user.site_url + '/logo_settings/')
	@user.b.wait
  	@user.checkbox(:id, "logo[delete]").set(true)
  	@user.submits
  	
  	assert_not_nil @user.contains_text("Your settings were successfully updated")
  	
  	# Verify Logo is not shown in Invoice
  	last_invoice = Invoice.find(:first, :order => "id DESC")
  	@user.displays_invoice_list()
  	@user.shows_invoice(last_invoice.id)
  	
  	assert !@user.image(:alt, /(L|l)ogo_6/).exist?
  end

  # 4.1 Edge Case - Users add their company logo in a jpg format but it is bigger than
  # the maximum (500x150)
  def test_company_address_information_plus_big_logo_jpg
  	# Fill up Profile Information
  	@user.goto(@user.profile_url)	
  	fills_company_information_for @user	
  	@user.submits
	@user.goto(@user.site_url + '/logo_settings/')
	@user.b.wait
  	# Add jpg logo
  	file_name = "BigLogo.jpg"
  	path = Dir.getwd + '/public/images/testimages/' + file_name	
  
  	#simulate choosing a file 
  	# TODO - else part (Only pass string path to file_field
    @user.link(:id, "user_logo_link").click

    if (WatirBrowser.ie?)
      windoze_path = path.gsub('/', '\\')
  		@user.file_field(:id, 'logo_uploaded_data').click_no_wait
  		startClicker(@user, "&Open",10,windoze_path)	
  		@user.wait
  	else
  	  @user.file_field(:id, 'logo_uploaded_data').set(path)
  	end
  		
  	@user.submits
  	
  	assert_not_nil @user.contains_text("Your settings were successfully updated")
  	
  	# Create an Invoice
  	add_invoice  	
  	assert_not_nil @user.contains_text("Invoice was successfully created"), "invoice NOT successfully created"
  	  
      # Verify that Invoce includes the company's address info
  	checks_company_information(:name => "The Companys Name",
  							   :address1 => "The Companys Address 1",
  							   :address2 => "The Companys Address 2",
  							   :city => "The Companys City",
  							   :state => "The Companys State",
  							   :country => "Aruba",	
  							   :phone => "(604)-657-9087",
  							   :fax => "(604)-657-9088")
  							   
  	# Verify that logo_1 is the current image in the Invoice
  	assert @user.image(:alt, /(B|b)ig(L|l)ogo/).exist?
  end

  # 4.2 Edge Case - Users add their company logo and then decides to 
  # replace it with another, at the same time
  # the maximum (500x150)
  def test_company_address_information_plus_logo_remove_add
  	# Fill up Profile Information
  	@user.goto(@user.profile_url)	
  	fills_company_information_for @user	
  	@user.submits
	@user.goto(@user.site_url + '/logo_settings/')
	@user.b.wait
  	# Add png logo
  	file_name = "Logo_5.png"
  	path = Dir.getwd + '/public/images/testimages/' + file_name	
  
  	#simulate choosing a file 
  	# TODO - else part (Only pass string path to file_field
    if (WatirBrowser.ie?)
    	realpath = path.gsub('/', '\\')
  		@user.file_field(:id, 'logo_uploaded_data').click_no_wait
  		startClicker(@user, "&Open",10,realpath)	
  		@user.wait
  	else
  	  @user.file_field(:id, 'logo_uploaded_data').set(path)
  	end
  		
  	@user.submits
  	
  	assert_not_nil @user.contains_text("Your settings were successfully updated")
  	
  	# Create an Invoice
  	add_invoice  	
  	assert_not_nil @user.contains_text("Invoice was successfully created"), "invoice NOT successfully created"
  	  
      # Verify that Invoce includes the company's address info
  	checks_company_information(:name => "The Companys Name",
  							   :address1 => "The Companys Address 1",
  							   :address2 => "The Companys Address 2",
  							   :city => "The Companys City",
  							   :state => "The Companys State",
  							   :country => "Aruba",	
  							   :phone => "(604)-657-9087",
  							   :fax => "(604)-657-9088")
  							   
  	# Verify that logo_1 is the current image in the Invoice
  	assert @user.image(:alt, /(L|l)ogo_5/).exist?
  	
  	# Remove Logo
	@user.goto(@user.site_url + '/logo_settings/')
	@user.b.wait
	
  	@user.checkbox(:id, "logo[delete]").set(true)
  
  	# Add Logo
  	file_name = "Logo_6.png"
  	path = Dir.getwd + '/public/images/testimages/' + file_name	
  	realpath = path.gsub('/', '\\')
  
  	#simulate choosing a file 
  	# TODO - else part (Only pass string path to file_field
    if (WatirBrowser.ie?)
  		@user.file_field(:id, 'logo_uploaded_data').click_no_wait
  		startClicker(@user, "&Open",10,realpath)	
  		@user.wait
  	else
  	  @user.file_field(:id, 'logo_uploaded_data').set(path)
  	end
  
  	@user.submits
  
  	assert_not_nil @user.contains_text("Your settings were successfully updated")	
  end

  # 4.3 Edge Case - Users add their company logo but the file is not an image 
  # The file extension is correct (gif)
  def test_company_logo_not_an_image_1
  	# Fill up Profile Information
  	@user.goto(@user.profile_url)	
  	fills_company_information_for @user	
	@user.submits
	@user.goto(@user.site_url + '/logo_settings/')
	@user.b.wait
  	# Add gif logo
  	file_name = "NotAnImage.gif"
  	path = Dir.getwd + '/public/images/testimages/' + file_name	
  	realpath = path.gsub('/', '\\')
  
    @user.link(:id, "user_logo_link").click

  	#simulate choosing a file 
  	# TODO - else part (Only pass string path to file_field
    if (WatirBrowser.ie?)
  		@user.file_field(:id, 'logo_uploaded_data').click_no_wait
  		startClicker(@user, "&Open",10,realpath)	
  		@user.wait
  	else
  	  @user.file_field(:id, 'logo_uploaded_data').set(path)
  	end
  		
  	@user.submits
    
  	assert_not_nil @user.contains_text("1 error prohibited this logo from being saved")
  end

  # 4.4 Edge Case - Users add their company logo but the file is not an image 
  # The file extension is txt
  def test_company_logo_not_an_image_2
  	# Fill up Profile Information
  	@user.goto(@user.profile_url)	
  	fills_company_information_for @user	
    @user.submits
	@user.goto(@user.site_url + '/logo_settings/')
	@user.b.wait
  	# Add txt file
  	file_name = "TextFile.txt"
  	path = Dir.getwd + '/public/images/testimages/' + file_name	
  	realpath = path.gsub('/', '\\')
  
  	#simulate choosing a file 
  	# TODO - else part (Only pass string path to file_field
      if (WatirBrowser.ie?)
  		@user.file_field(:id, 'logo_uploaded_data').click_no_wait
  		startClicker(@user, "&Open",10,realpath)	
  		@user.wait
  	else
  	  @user.file_field(:id, 'logo_uploaded_data').set(path)
  	end
  		
  	@user.submits
  	
  	assert_not_nil @user.contains_text("1 error prohibited this logo from being saved")
  end

  def test_js_traverse
    @user.goto(@user.profile_url)
    
    assert @user.text_field(:id, "profile_company_name").visible?


    fills_company_information_for(@user)
    
    @user.submits
    @user.b.wait
    assert @user.checkbox(:id, "profile_tax_enabled").visible?
    #deny @user.text_field(:id, "profile_company_name").visible?
    @user.checkbox(:id, "profile_tax_enabled").click
    @user.b.wait
    @user.populate(@user.text_field(:id, "profile_tax_1_name"),("negative"))
    @user.populate(@user.text_field(:id, "profile_tax_1_rate"),("-5"))
    
    @user.submits
    @user.b.wait
	
    assert @user.text_field(:id, "profile_tax_1_rate").visible?
    @user.populate(@user.text_field(:id, "profile_tax_1_name"),("positive"))
    @user.populate(@user.text_field(:id, "profile_tax_1_rate"),("5"))
    
    @user.submits
    @user.b.wait
    assert @user.file_field(:id, "logo_uploaded_data").visible?
    
    @user.submits
    @user.b.wait
    assert @user.checkbox(:id, "profile_mail_opt_in").visible?
    
    @user.submits
    @user.b.wait
    
    assert @user.checkbox(:id, "user_gateway_selections[]").visible?
    
    @user.submits
    @user.b.wait
    #sleep 5000
    assert @user.b.html.include?("Invoice List")
  
  end
  
  private
  def fills_company_information_for(user)

		user.select_list(:id, "profile_heard_from").set('Banks')

  	@user.populate(user.text_field(:id, "profile_company_name"),('The Companys Name'))
	@user.populate(user.text_field(:id, "profile_company_address1"),('The Companys Address 1'))
	@user.populate(user.text_field(:id, "profile_company_address2"),('The Companys Address 2'))
	@user.populate(user.text_field(:id, "profile_company_city"),('The Companys City'))
  user.expects_ajax(1) do
    user.select_list(:id, "profile_company_country").set('Aruba')
  end
	@user.populate(user.text_field(:id, "profile_company_state"),('The Companys State'))
  @user.populate(	user.text_field(:id, "profile_company_phone"),('(604)-657-9087'))
	@user.populate(user.text_field(:id, "profile_company_fax"),('(604)-657-9088'))
		
  end

  def fill_invoice_for user
  
    # Invoice Info
    user.sets_invoice_info(
      :unique => "Inv-0001",
      :date => "2007-12-15",
      :reference => "Ref-0001",
      :description => "Original description for this Invoice"
    )
    
    # Contact Info
    #user.sets_invoice_contact(
    #    :first_name => "My Contact First Name",
    #    :last_name => "My Contact Last Name",
    #    :email => "abc@address.com"
    #)    
  end    
  
  def checks_company_information(fields)
    fields.each_pair do |field, value|
      e = @user.b.span(:id, "invoice_profile_#{field.to_s}")
	  assert e.text.include?(value), "The company's #{field.to_s} doesn't match #{value}"
    end
    self    
  end
  
  def add_invoice
  	@number_of_line_items = 5
  	subtotal = 0
    discount = 50.00
    discount_percent = 10.00
    
	  assert_difference 'Invoice.count' do
      @user.creates_new_invoice
      fill_invoice_for @user
      
      #Customer Info    
      
      current_customer = customers("heavy_user_customer_1".to_sym)
      @user.enter_new_customer( 
          :name => current_customer.name
      )    
      
      # quantity and price initial values   
      quantity = 20
      price = 4.00
	        
      # Add line items
      (1..@number_of_line_items).each do | i |
      if i == 1 
         @user.edits_line_item(i, 
          :unit => "Item A" + i.to_s,
          :description => "Description for Item A" + i.to_s,
          :quantity => quantity.to_s,
          :price => price.to_s)
      else
        assert_equal i, @user.adds_line_item(
          :unit => "Item A" + i.to_s,
          :description => "Description for Item A" + i.to_s,
          :quantity => quantity.to_s,
          :price => price.to_s)
      end
        
	      subtotal += quantity * price					
        quantity += 1
        price += 1
      end

      # Discount and Type
      @user.populate(@user.text_field(:id, "invoice_discount_value"),(discount.to_s))
      @user.select_list(:id, "invoice_discount_type").option(:text, "amount").select



      puts("number_of_line_items is " + @number_of_line_items.to_s)
      # Submit and verify
      assert_difference 'LineItem.count', @number_of_line_items do
       @user.submits        
      end
	  end  
  end 
  
end #end class
