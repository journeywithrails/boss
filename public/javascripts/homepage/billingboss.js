// JavaScript Document

// Make Shadows
// if (navigator.userAgent.toLowerCase().indexOf('msie 6') == -1) {$('#banner').dropShadow({left:0, opacity:0.35, blur:3}); }

// Make Corners
// $('#signup-login-contest').cornerz({radius:25, corners: "bl br"});
// $('#quick-login').cornerz({radius:20, background:"#d9e6a3"});
$('.cornerbox').cornerz({radius:20});
$('#invite-a-friend').cornerz({radius:20});
// $('.text-block').cornerz({radius:20});

// Make Expandable/Collapsable Content
jQuery('#heavy-text').accordion({
	header: 'div.title',
	active: false,
	alwaysOpen: false,
	animated: false,
	clearStyle: true,
   	autoHeight: false
});

/***********************************************
* Cross browser Marquee II- © Dynamic Drive (www.dynamicdrive.com)
* This notice MUST stay intact for legal use
* Visit http://www.dynamicdrive.com/ for this script and 100s more.
***********************************************/

var delayb4scroll=3000 //Specify initial delay before marquee starts to scroll on page (2000=2 seconds)
var marqueespeed=1 //Specify marquee scroll speed (larger is faster 1-10)
var pauseit=1 //Pause marquee onMousever (0=no. 1=yes)?

var copyspeed=marqueespeed
var pausespeed=(pauseit==0)? copyspeed: 0
var actualheight=''

function scrollmarquee(){
  if (parseInt(cross_marquee.style.top)>(actualheight*(-1)+8)){
    newheight = parseInt(cross_marquee.style.top)-copyspeed;
    cross_marquee.style.top=newheight +"px";
    cross_marquee2.style.top=newheight+actualheight+"px";
  }else{
    tmp_swap = cross_marquee;
    cross_marquee = cross_marquee2;
    cross_marquee2 = tmp_swap;
  }
}

function initializemarquee(){
  cross_marquee=document.getElementById("vmarquee");
  cross_marquee.style.top=0;
  container=document.getElementById("marqueecontainer");
  marqueeheight=container.offsetHeight;
  actualheight=cross_marquee.offsetHeight;
  if (navigator.userAgent.indexOf("Netscape/7")!=-1){
    cross_marquee.style.height=marqueeheight+"px";
    cross_marquee.style.overflow="scroll";
    return;
  }
  cross_marquee2 = cross_marquee.cloneNode(true);
  cross_marquee2.setAttribute("id", "vmarquee2");
  container.appendChild( cross_marquee2 );
  setTimeout('lefttime=setInterval("scrollmarquee()",30)', delayb4scroll);
  cross_marquee2.style.top=actualheight+"px";
}

if (window.addEventListener)
window.addEventListener("load", initializemarquee, false)
else if (window.attachEvent)
window.attachEvent("onload", initializemarquee)
else if (document.getElementById)
window.onload=initializemarquee
