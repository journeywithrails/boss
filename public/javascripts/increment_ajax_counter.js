
if( Sage.ajax_counter == undefined ) 
  Sage.ajax_counter = 0;

Sage.increment_ajax_counter = function () {
  Sage.ajax_counter += 1;  
  $('ajax_counter') && ($('ajax_counter').innerHTML = Sage.ajax_counter);
}

Event.observe(window, 'load',
  function() {  new Insertion.Bottom(document.body, '<div id="ajax_counter">' + Sage.ajax_counter + '</div>'); }
);

