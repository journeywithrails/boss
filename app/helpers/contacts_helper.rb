module ContactsHelper
  def toggle_import_function(name)
    link_to_function name, nil do |page|
  	  page[:csv_import_form].toggle
  	  page[:show_csv_import_form].toggle
  	end
  end
  
  def add_contact_link(name, *properties)
    customer = @customer || Customer.new
    dummy_contact = customer.contacts.build
    out = link_to_function name, *properties do |page|
      page.insert_html :before, 'add_contact_row', :partial => 'contacts/contact_line_item', :object => dummy_contact, :locals => {:row_id => 'new_contact'}
      page << 'Sage.add_new_contact();'
    end
    out
  end
end
