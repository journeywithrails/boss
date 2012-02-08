	Sage.resize_graphics = function (graphics, menu_graphics) {  
	  var myWidth = 0, myHeight = 0;
	  if( typeof( window.innerWidth ) == 'number' ) {
	    //Non-IE
	    myWidth = window.innerWidth;
	    myHeight = window.innerHeight;
	  } else if( document.documentElement && ( document.documentElement.clientWidth || document.documentElement.clientHeight ) ) {
	    //IE 6+ in 'standards compliant mode'
	    myWidth = document.documentElement.clientWidth;
	    myHeight = document.documentElement.clientHeight;
	  } else if( document.body && ( document.body.clientWidth || document.body.clientHeight ) ) {
	    //IE 4 compatible
	    myWidth = document.body.clientWidth;
	    myHeight = document.body.clientHeight;
	  }


	  //FIXME: fix this so this function can be reusable
	  if (myWidth < 910)
	  {
				$("contest_content").className = "content contest_content_small"
				$("tour_header").className = "tour_box_tl  tour_header_small"
		}
	  else {
				$("contest_content").className = "content contest_content"
				$("tour_header").className = "tour_box_tl  tour_header"
	  }

	  for (graphic in menu_graphics)
	  {
	    if (myWidth < 910)
	    {
	  	  	$(menu_graphics[graphic]).innerHTML = "<img src='/themes/default/images/" + menu_graphics[graphic] + "_small.gif' />";
			}
	    else {
		  	$(menu_graphics[graphic]).innerHTML = "<img src='/themes/default/images/" + menu_graphics[graphic] + ".gif' />";
	    }
	  }  

	  for (graphic in graphics)
	  {
	    if (myWidth < 910)
	    {
	      $(graphics[graphic]).innerHTML = "<img src='/images/" + graphics[graphic] + "_small.gif' />";
	    }
	    else if(myWidth < 1400)
	    {
	      $(graphics[graphic]).innerHTML = "<img src='/images/" + graphics[graphic] + "_medium.gif' />";
	    }
	    else 
	    {
	      $(graphics[graphic]).innerHTML = "<img src='/images/" + graphics[graphic] + "_large.gif' />";
	    }
	  }  
	}


	Sage.setGraphics = function() {
	  switch(document.title)
	  {
	    case 'Billing Boss: Free Online Invoicing':
	      Sage.resize_graphics(new Array('main_graphic'), new Array('btn_enter_to_win', 'tour_img')); 
	    break;    
	  default:
	  }  
	}  



	Event.observe(window, 'load', Sage.setGraphics);
	Event.observe(window, 'resize', Sage.setGraphics);
