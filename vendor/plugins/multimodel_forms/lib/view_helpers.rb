module MultimodelForms
  module ViewHelpers

    # => fields_for_associated :article, :link
    def fields_for_associated main, through, &block
      fields_for("#{main}[#{through.class.to_s.tableize}_attributes][]", through, &block)
    end
    
    def add_link text, through, include_js=nil
      plural_sym = through.to_s.pluralize.to_sym
      obj = through.to_s.capitalize.constantize
      link_to_function text do |page|
        page.insert_html :bottom, plural_sym, :partial => "#{plural_sym}/#{through}", :object => obj.new
        page << include_js unless include_js.blank?
      end
    end
    
    def delete_link text, through, form, klass
      l = link_to_function(text, "$(this).up('.#{klass}').down('.should_destroy').value = 1; $(this).up('.#{klass}').hide();", :class => 'delete')
      l += form.hidden_field :should_destroy, :index => nil, :class => 'should_destroy'
      l += form.hidden_field :id, :index => nil
    end
    
    def new_delete_link text, through, klass
      link_to_function("Delete", "$(this).up('.#{klass}').remove()", :class => 'delete')
    end
    
    # Defaults klass to through class name
    def delete_link_for(through, text, form, klass=nil)
      klass ||= through.class.to_s.tableize.singularize
      if through.new_record?
        new_delete_link text, through, klass
      else
        delete_link text, through, form, klass
      end
    end
  end
end