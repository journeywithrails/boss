/**
 * @author Ryan Johnson <ryan@livepipe.net>
 * @copyright 2007 LivePipe LLC
 * @package Control.TextArea.ToolBar.Markdown
 * @license MIT
 * @url http://livepipe.net/projects/control_textarea/
 * @version 1.0.1
 */

Control.TextArea.ToolBar.Markdown = Class.create();
Object.extend(Control.TextArea.ToolBar.Markdown.prototype,{
	textarea: false,
	toolbar: false,
	options: {},
	initialize: function(textarea,options){
		this.textarea = new Control.TextArea(textarea);
		this.toolbar = new Control.TextArea.ToolBar(this.textarea);
		this.converter = (typeof(Showdown) != 'undefined') ? new Showdown.converter : false;
		this.options = {
			preview: false,
			afterPreview: Prototype.emptyFunction
		};
		Object.extend(this.options,options || {});
		if(this.options.preview){
			this.textarea.observe('change',function(textarea){
				if(this.converter){
					$(this.options.preview).update(this.converter.makeHtml(textarea.getValue()));
					this.options.afterPreview();
				}
			}.bind(this));
		}

		//buttons
		this.toolbar.addButton('Italics',function(){
			this.wrapSelection('*','*');
		},{
			id: 'markdown_italics_button'
		});
		
		this.toolbar.addButton('Bold',function(){
			this.wrapSelection('**','**');
		},{
			id: 'markdown_bold_button'
		});
		
		this.toolbar.addButton('Link',function(){
			var selection = this.getSelection();
			var response = prompt('Enter Link URL','');
			if(response == null)
				return;
			this.replaceSelection('[' + (selection == '' ? 'Link Text' : selection) + '](' + (response == '' ? 'http://link_url/' : response).replace(/^(?!(f|ht)tps?:\/\/)/,'http://') + ')');
		},{
			id: 'markdown_link_button'
		});
		
		this.toolbar.addButton('Image',function(){
			var selection = this.getSelection();
			var response = prompt('Enter Image URL','');
			if(response == null)
				return;
			this.replaceSelection('![' + (selection == '' ? 'Image Alt Text' : selection) + '](' + (response == '' ? 'http://image_url/' : response).replace(/^(?!(f|ht)tps?:\/\/)/,'http://') + ')');
		},{
			id: 'markdown_image_button'
		});
		
		this.toolbar.addButton('Heading',function(){
			var selection = this.getSelection();
			if(selection == '')
				selection = 'Heading';
			var str = '';
			(Math.max(5,selection.length)).times(function(){
				str += '-';
			});
			this.replaceSelection("\n" + selection + "\n" + str + "\n");
		},{
			id: 'markdown_heading_button'
		});
		
		
		this.toolbar.addButton('Unordered List',function(event){
			this.injectEachSelectedLine(function(lines,line){
				lines.push((event.shiftKey ? (line.match(/^\*{2,}/) ? line.replace(/^\*/,'') : line.replace(/^\*\s/,'')) : (line.match(/\*+\s/) ? '*' : '* ') + line));
				return lines;
			});
		},{
			id: 'markdown_unordered_list_button'
		});
		
		this.toolbar.addButton('Ordered List',function(event){
			var i = 0;
			this.injectEachSelectedLine(function(lines,line){
				if(!line.match(/^\s+$/)){
					++i;
					lines.push((event.shiftKey ? line.replace(/^\d+\.\s/,'') : (line.match(/\d+\.\s/) ? '' : i + '. ') + line));
				}
				return lines;
			});
		},{
			id: 'markdown_ordered_list_button'
		});
		
		this.toolbar.addButton('Block Quote',function(event){
			this.injectEachSelectedLine(function(lines,line){
				lines.push((event.shiftKey ? line.replace(/^\> /,'') : '> ' + line));
				return lines;
			});
		},{
			id: 'markdown_quote_button'
		});
		
		this.toolbar.addButton('Code Block',function(){
			this.injectEachSelectedLine(function(lines,line){
				lines.push((event.shiftKey ? line.replace(/    /,'') : '    ' + line));
				return lines;
			});
		},{
			id: 'markdown_code_button'
		});
		
		this.toolbar.addButton('Help',function(){
			window.open('http://daringfireball.net/projects/markdown/dingus');
		},{
			id: 'markdown_help_button'
		});
	}
});