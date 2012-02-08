Event.observe(window, 'load', init, false);

function init(){
    Lightbox.init();
}

var Lightbox = {
	lightboxType : null,
	lightboxCurrentContentID : null,
        modal  :  true,
	
	showBoxString : function(content, title, boxWidth, boxHeight){
		this.setLightboxDimensions(boxWidth, boxHeight);
		this.lightboxType = 'string';
		var contents = $('boxContents');
		contents.innerHTML = content;
                this.setTitle(title);
		this.showBox();
		return false;
	},


	showBoxImage : function(href, title) {
		this.lightboxType = 'image';
		var contents = $('boxContents');
		var objImage = document.createElement("img");
		objImage.setAttribute('id','lightboxImage');
		contents.appendChild(objImage);
		imgPreload = new Image();
		imgPreload.onload=function(){
			objImage.src = href;
			Lightbox.showBox();
		}
                this.setTitle(title);
		imgPreload.src = href;
		return false;
	},

	showBoxByID : function(id, title, boxWidth, boxHeight) {

		this.lightboxType = 'id';
		this.lightboxCurrentContentID = id;

		this.setLightboxDimensions(boxWidth, boxHeight);

		var element = $(id);
         
		var contents = $('boxContents');
		contents.appendChild(element);
		Element.show(id);
                this.setTitle(title);
		this.showBox();    
		return false;
	},

	showBoxByAJAX : function(el, title, boxWidth, boxHeight) {
                this.cleanContent();
		this.lightboxType = 'ajax';
		this.setLightboxDimensions(boxWidth, boxHeight);
		var contents = $('boxContents');
		var myAjax = new Ajax.Updater(contents, el.href, {method: 'get', evalScripts: true});
		this.showBox();
                this.setTitle(title);
		return false;
	},

        setTitle: function(text){

            if ($('boxTitle').innerHTML == '' )
                new Insertion.Top('boxTitle', text)
        },
	
	setLightboxDimensions : function(width, height) {
		var windowSize = this.getPageDimensions();
		if(width) {
			if(width < windowSize[0]) {
				$('dialog-container').style.width = width + 'px';
                                $('boxContents').style.width =  parseInt(width) - 16 + 'px'
                                $('boxShadow').style.width = parseInt(width) + 8 + 'px';

                                $('boxShadow').down('.xsbc').style.width = parseInt(width)-4 + 'px'
                                $('boxShadow').down('.xsmc').style.width =  parseInt(width)-4  + 'px'
                                $('boxShadow').down('.xstc').style.width =  parseInt(width)-4  + 'px'


			} else {
				$('dialog-container').style.width = (windowSize[0] - 50) + 'px';
                                $('boxContents').style.width =  (windowSize[0] - 50)  - 16 + 'px'
                                $('boxShadow').style.width = p(windowSize[0] - 50)  + 8 + 'px';

                                $('boxShadow').down('.xsbc').style.width = (windowSize[0] - 50) -4 + 'px'
                                $('boxShadow').down('.xsmc').style.width =  (windowSize[0] - 50) -4  + 'px'
                                $('boxShadow').down('.xstc').style.width =  (windowSize[0] - 50) -4  + 'px'

			}
		}
		if(height) {
			if(height < windowSize[1]) {
				$('dialog-container').style.height = parseInt(height) + 'px';
                                $('boxContents').style.height = parseInt(height) - 66 + 'px';
                                $('boxShadow').style.height = parseInt(height)+ 'px';
                                $('boxShadow').down('.xsc').style.height = parseInt(height) - 7 +  'px';

			} else {
				$('dialog-container').style.height = (windowSize[1] - 50) + 'px';
                                $('boxContents').style.height =(windowSize[1] - 50) - 66 + 'px';
                                $('boxShadow').style.height = (windowSize[1] - 50)+ 'px';
                                $('boxShadow').down('.xsc').style.height = (windowSize[1] - 50) - 7 +  'px';
			}
		}
                $('boxShadow').style.display = "block";
	},


	showBox : function() {
                this.showOverlay();
		this.center('dialog-container');
		return false;
	},



        showOverlay: function(){
            if (this.modal)
                Element.show('overlay');
            else
                Element.hide('overlay');
        },

        cleanContent: function(){
            $('boxContents').innerHTML = "";
        },
	
	hideBox : function(){
//		var contents = $('boxContents');
//		if(this.lightboxType == 'id') {
//			var body = document.getElementsByTagName("body").item(0);
//			Element.hide(this.lightboxCurrentContentID);
//			body.appendChild($(this.lightboxCurrentContentID));
//		}
//		contents.innerHTML = '';
                Element.hide('overlay');
		$('dialog-container').style.width = null;
		$('dialog-container').style.height = null;
		Element.hide('dialog-container');
		Element.hide('boxShadow');
		return false;
	},
	
	// taken from lightbox js, modified argument return order
	getPageDimensions : function(){
		var xScroll, yScroll;
	
		if (window.innerHeight && window.scrollMaxY) {	
			xScroll = document.body.scrollWidth;
			yScroll = window.innerHeight + window.scrollMaxY;
		} else if (document.body.scrollHeight > document.body.offsetHeight){ // all but Explorer Mac
			xScroll = document.body.scrollWidth;
			yScroll = document.body.scrollHeight;
		} else { // Explorer Mac...would also work in Explorer 6 Strict, Mozilla and Safari
			xScroll = document.body.offsetWidth;
			yScroll = document.body.offsetHeight;
		}
		
		var windowWidth, windowHeight;
		if (self.innerHeight) {	// all except Explorer
			windowWidth = self.innerWidth;
			windowHeight = self.innerHeight;
		} else if (document.documentElement && document.documentElement.clientHeight) { // Explorer 6 Strict Mode
			windowWidth = document.documentElement.clientWidth;
			windowHeight = document.documentElement.clientHeight;
		} else if (document.body) { // other Explorers
			windowWidth = document.body.clientWidth;
			windowHeight = document.body.clientHeight;
		}	
		
		// for small pages with total height less then height of the viewport
		if(yScroll < windowHeight){
			pageHeight = windowHeight;
		} else { 
			pageHeight = yScroll;
		}
	
		// for small pages with total width less then width of the viewport
		if(xScroll < windowWidth){	
			pageWidth = windowWidth;
		} else {
			pageWidth = xScroll;
		}
		arrayPageSize = new Array(windowWidth,windowHeight,pageWidth,pageHeight) 
		return arrayPageSize;
	},
	
	center : function(element){
		try{
			element = document.getElementById(element);
                        var boxShadow = document.getElementById('boxShadow');
		}catch(e){

			return;
		}

		var windowSize = this.getPageDimensions();
		var window_width  = windowSize[0];
		var window_height = windowSize[1];
		
		element.style.position = 'absolute';
		element.style.zIndex   = 1299;

                $('overlay').style.height = windowSize[3] + 'px';
	
		var scrollY = 0;
	
		if ( document.documentElement && document.documentElement.scrollTop ){
			scrollY = document.documentElement.scrollTop;
		}else if ( document.body && document.body.scrollTop ){
			scrollY = document.body.scrollTop;
		}else if ( window.pageYOffset ){
			scrollY = window.pageYOffset;
		}else if ( window.scrollY ){
			scrollY = window.scrollY;
		}
	
		var elementDimensions = Element.getDimensions(element);
		var setX = ( window_width  - elementDimensions.width  ) / 2;
		var setY = ( window_height - elementDimensions.height ) / 2 + scrollY;
	
		setX = ( setX < 0 ) ? 0 : setX;
		setY = ( setY < 0 ) ? 0 : setY;
	
		element.style.left = setX + "px";
		element.style.top  = setY + "px";
                boxShadow.style.left = setX-4 + "px";
                boxShadow.style.top  = setY+3 + "px";
		Element.show(element);                
                                 
	},

        setup : function( settings ) {
            var buttons = settings.buttons;
            this.modal = settings.modal;
            var text = '  <table cellspacing="0"> <tr>';
            for(var i=0; i<buttons.length; i++)
            {
                text += '<td id="ext-gen380" class="x-panel-btn-td">'+
                    '<table id="dialog-button-'+buttons[i].label+'" class="x-btn-wrap x-btn" cellspacing="0" cellpadding="0" border="0" style="width: 75px;">'+
                        '<tr>'+
                            '<td class="x-btn-left"><i> </i></td>'+
                            '<td class="x-btn-center">'+
                                '<em unselectable="on"><button id="'+buttons[i].id+'" class="x-btn-text" type="button">'+ buttons[i].label +'</button></em>'+
                            '</td>'+
                            '<td class="x-btn-right"><i> </i></td>'+
                        '</tr>'+
                    '</table>'+
                '</td>'
            }
           text +=' </tr> </table><div class="x-clear"/>';

           var btnscontainer = $$('div.x-panel-btns').first();
           btnscontainer.update( text );

           for(var i=0; i<buttons.length; i++)
           {
                $(buttons[i].id).observe('click',buttons[i].action);
                $('dialog-button-'+buttons[i].label).observe('click',buttons[i].action);
                $('dialog-button-'+buttons[i].label).observe('mouseover',function(){$(this).addClassName("x-btn-over")});
                $('dialog-button-'+buttons[i].label).observe('mouseout',function(){$(this).removeClassName("x-btn-over")});
           }

           this.showOverlay();
        },
	init : function() {				  

         var lightboxtext = '<div id="overlay" style="display:none"></div>'+
                            '<div class="x-shadow" id="boxShadow" style="z-index:1000; overflow:visible;"> <div class="xst">  <div class="xstl"></div>  <div class="xstc" style=""></div>  <div class="xstr"></div> </div> <div class="xsc" style=""> <div class="xsml"></div>  <div class="xsmc" style=""></div>  <div class="xsmr"></div> </div> <div class="xsb"> <div class="xsbl"></div>  <div class="xsbc" style=""></div> <div class="xsbr"></div> </div></div>'+
                             '<div id="dialog-container" class=" x-window x-window-plain x-resizable-pinned" style="display:none;">'+                               
                                '<div class="x-window-tl">'+
                                  '<div class="x-window-tr">'+
                                    '<div class="x-window-tc">'+
                                     ' <div class="x-window-header x-unselectable " id="boxTitle" style="text-align:center;"></div>'+
                                      '<img id="close" src="/images/close.png" onClick="Lightbox.hideBox()" alt="Close" title="Close this window" />'+
                                    '</div>'+
                                  '</div>'+
                                '</div>'+
                              '<div class="x-window-bwrap">'+
                               ' <div class="x-window-ml">'+
                                '  <div class="x-window-mr">'+
                                 '   <div class="x-window-mc">'+
                                      '<div id="boxContents" class="x-window-body" style="">'+
                                      '</div>'+
                                    '</div>'+
                                  '</div>'+
                                '</div>'+
                                '<div class="x-window-bl">'+
                                  '<div class="x-window-br">'+
                                    '<div class="x-window-bc">'+
                                      '<div class="x-window-footer">'+
                                        '<div class="x-panel-btns-ct">'+
                                        '<div id="buttons-container" class="x-panel-btns x-panel-btns-right">'+                                               
                                        '</div>'+
                                        '</div>'+
                                      '</div>'+
                                    '</div>'+
                                  '</div>'+
                                '</div>'+
                              '</div>'+
                              '<div class="x-unselectable"></div>'+
                              '<div class="x-unselectable"></div>'+
                              '<div class="x-unselectable"></div>'+
                              '<div class="x-unselectable"></div>'+
                              '<div class="x-unselectable"></div>'+
                              '<div class="x-unselectable"></div>'+
                              '<div class="x-unselectable"></div>'+
                              '<div class="x-unselectable"></div>'+

                            '</div>'
                      
		var parent = document.body;
		new Insertion.Bottom(parent, lightboxtext);
	}
}




