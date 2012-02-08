function closeDiv(divid){

	if(document.getElementById(divid).style.display == 'block'){
		document.getElementById(divid).style.display = 'none';
	}	

}

function openDiv(divid){

	if(document.getElementById(divid).style.display == 'none'){
		document.getElementById(divid).style.display = 'block';
	}	

}

Sage.setGraphics = function() {
  switch(document.title)
  {
    case 'Billing Boss: Free Online Invoicing':
      setGraphicList(new Array('main_graphic'));       
      setMenuGraphicList(new Array('tour_img')); 
    break;    
  default:
  }  
}  
  
function setGraphicList(list) {  
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

  for (graphic in list)
  {
    if (myWidth < 910)
    {
      $(list[graphic]).innerHTML = "<img src='/images/" + list[graphic] + "_small.gif' />";
    }
    else if(myWidth < 1400)
    {
      $(list[graphic]).innerHTML = "<img src='/images/" + list[graphic] + "_medium.gif' />";
    }
    else 
    {
      $(list[graphic]).innerHTML = "<img src='/images/" + list[graphic] + "_large.gif' />";
    }
  }  
}

function setMenuGraphicList(list) {  
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
  var tour_header = document.getElementById("tour_header");
  for (graphic in list)
  {
    if (myWidth < 910)
    {
				tour_header.className = "tour_box_tl  tour_header_small"
		  	$(list[graphic]).innerHTML = "<img src='/themes/default/images/" + list[graphic] + "_small.gif' />";
		}
    else {
				tour_header.className = "tour_box_tl  tour_header"
		  	$(list[graphic]).innerHTML = "<img src='/themes/default/images/" + list[graphic] + ".gif' />";
    }
  }  
}    

Event.observe(window, 'load', Sage.setGraphics);
Event.observe(window, 'resize', Sage.setGraphics);


