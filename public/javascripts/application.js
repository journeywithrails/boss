// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

// Namespace Sage javascript
var Sage = function () {
	return {
		HIGHLIGHT_COLOR: '#96BCCD', // light blue
    
		// used to mark child items deleted client side to be deleted from db when parent is saved
		mark_for_destroy: function (elm){
		  elm = $(elm);
		  while(elm && !elm.hasClassName('child_item')){
		    elm = elm.up();
		  }
			$(elm).getElementsBySelector('input.should_destroy').first().value = 1;
			$(elm).hide();
		},

		// serialize a form except for elements with names in except (array of names)
		serializedFormExceptNames: function (form, except, getHash){
			var elements = Form.getElements(form).reject(function (x) { return except.include(x.name);});
			return Form.serializeElements(elements, getHash)
		},
		
		serializedFormWithoutMethod: function (form){
			var h = new Hash;
			return Sage.serializedFormExceptNames(form, ['_method'], true);
		},
		
		add_new_line_item: function (){
      var new_line_item_id = 'line_item_new_' + Sage.db_agnostic_ids['line_item'];
      $$('#new_line_item .row_id')[0].value = new_line_item_id;
      $('new_line_item').id = new_line_item_id;
      ++Sage.db_agnostic_ids['line_item'];	  
      var new_watch_fields = Sage.get_line_item_watch_fields(new_line_item_id);
      new_watch_fields.each(
        function(elm){
          //RADAR this depends on a function added on the invoice page. Some reorganization is needed
          if(elm.hasClassName('cover_input')){
            Event.observe(elm, 'click', function(event){Sage.update_real_tax_fields(Event.element(event));Sage.update_invoice_totals();});
          } else {
            Event.observe(elm, 'change', Sage.update_invoice_totals);
          }
        }
      );
		},

		add_new_mobile_line_item: function (){
      var new_line_item_id = 'line_item_new_' + Sage.db_agnostic_ids['line_item'];
      $$('#new_line_item .row_id')[0].value = new_line_item_id;
      $('new_line_item').id = new_line_item_id;
      ++Sage.db_agnostic_ids['line_item'];	  
      var new_watch_fields = Sage.get_line_item_mobile_watch_fields(new_line_item_id);
      new_watch_fields.each(
        function(elm){
            Event.observe(elm, 'change', Sage.update_invoice_totals);
        }
      );
		},
		
		protect_form: function(form_name, message){
      new Event.observe(window, 'load', function() {
      	Sage.dirty_page = false;
      	new Form.EventObserver($(form_name), function(element, value) {Sage.dirty_page = true; });
      	new Event.observe(window, 'beforeunload', function(e){
      		if(Sage.dirty_page) {
      			Event.stop(e);
      			e.returnValue = message;
      	    return message;
      		}
      	})
      	Form.getInputs(form_name, "submit").each(function(btn){
      		Event.observe(btn, 'click', function(){Sage.dirty_page = false;});
      	});
      	Form.getInputs(form_name, "button").each(function(btn){
      		Event.observe(btn, 'click', function(){Sage.dirty_page = false;});
      	});
      });
		},
		
		add_new_contact: function (){
      var new_contact_id = 'contact_new_' + Sage.db_agnostic_ids['customer_contact'];
      $$('#new_contact .row_id').each(function(elm){elm.value = new_contact_id});
      $('new_contact').id = new_contact_id;
      ++Sage.db_agnostic_ids['customer_contact'];	  
		},
		
		get_line_item_watch_fields: function (elm){
		  return $(elm).getElementsBySelector('.price input', '.quantity input', '.tax_1_checkbox input', '.tax_2_checkbox input');
		},

		get_line_item_mobile_watch_fields: function (elm){
		  return $(elm).getElementsBySelector('.price input', '.quantity input');
		},

		get_line_item_tax_1_fields: function (elm){
		  return $(elm).getElementsBySelector('.tax_1_checkbox input');
		},

		get_line_item_tax_2_fields: function (elm){
		  return $(elm).getElementsBySelector('.tax_2_checkbox input');
		},

		get_customer_watch_fields: function (elm){
		  return $(elm).getElementsById('div_customer_country');
		},
		
		get_tax_rate_watch_fields: function (){
			return $('invoice_tax_1_rate', 'invoice_tax_2_rate').compact();
		},
		
		get_tax_checkbox_watch_fields: function (){
			return $('invoice_tax_1_enabled', 'invoice_tax_2_enabled').compact();
		},
		
		get_cover_watch_fields: function (elm){

		  return $(elm).getElementsBySelector('.cover input');
		},
		
		highlight_element: function(elm){
	      new Effect.Highlight(elm, {startcolor: Sage.HIGHLIGHT_COLOR , endcolor:'#ffffff'})
		},

		// TODO: possible that ExtJS library update needed to fix decoding weirdness
		json_to_escaped_html: function(value){
          var res = eval( "({x:'" + value.replace(/'/g, "\\'") + "'})" );
          return res.x.escapeHTML();
        }
	};
}();


