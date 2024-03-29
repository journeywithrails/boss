/**
 * @author Ryan Johnson <ryan@livepipe.net>
 * @copyright 2007 LivePipe LLC
 * @package Control.SelectMultiple
 * @license MIT
 * @url http://livepipe.net/projects/control_select_multiple/
 * @version 1.0.0
 */

if(typeof(Control) == 'undefined')
	var Control = {};
Control.SelectMultiple = Class.create();
Object.extend(Control.SelectMultiple.prototype,{
	select: false,
	container: false,
	numberOfCheckedBoxes: 0,
	checkboxes: [],
	hasExtraOption: false,
	initialize: function(select,container,options){
		this.options = {
			checkboxSelector: 'input[type=checkbox]',
			nameSelector: 'span.name',
			labelSeparator: ', ',
			valueSeparator: ',',
			afterChange: Prototype.emptyFunction,
			overflowString: function(str){
				return str.truncate();
			},
			overflowLength: 30
		};
		Object.extend(this.options,options || {});
		this.select = $(select);
		this.container =  $(container);
		this.checkboxes = (typeof(this.options.checkboxSelector) == 'function')
			? this.options.checkboxSelector.bind(this)()
			: this.container.getElementsBySelector(this.options.checkboxSelector)
		;
		this.hasExtraOption = false;
		this.checkboxes.each(function(checkbox){
			checkbox.observe('click',this.checkboxOnClick.bind(this,checkbox));
		}.bind(this));
		this.select.observe('change',this.selectOnChange.bind(this));
		this.countAndCheckCheckBoxes();
		var value_was_set = false;
		if(this.options.value){
			value_was_set = true;
			this.setValue(this.options.value);
			delete this.options.value;
		}
		if(!value_was_set)
			this.scanCheckBoxes();
		this.notify('afterChange',this.select.options[this.select.options.selectedIndex].value);
	},
	countAndCheckCheckBoxes: function(){
		this.numberOfCheckedBoxes = this.checkboxes.inject(0,function(number,checkbox){
			checkbox.checked = (this.select.options[this.select.options.selectedIndex].value == checkbox.value);
			if(checkbox.checked)
				++number;
			return number;
		}.bind(this));
	},
	setValue: function(value_string){
		this.numberOfCheckedBoxes = 0;
		(value_string.split ? value_string.split(this.options.valueSeparator) : value_string).each(function(value){
			this.checkboxes.each(function(checkbox){
				if(checkbox.value == value){
					++this.numberOfCheckedBoxes;
					checkbox.checked = true;
				}
			}.bind(this));
		}.bind(this));
		this.scanCheckBoxes();
	},
	selectOnChange: function(){
		this.removeExtraOption();
		this.countAndCheckCheckBoxes();
		this.notify('afterChange',this.select.options[this.select.options.selectedIndex].value);
	},
	checkboxOnClick: function(checkbox){
		this.numberOfCheckedBoxes += (checkbox.checked) ? 1 : -1;
		this.scanCheckBoxes();
		this.notify('afterChange',this.select.options[this.select.options.selectedIndex].value);
	},
	scanCheckBoxes: function(){
		switch(this.numberOfCheckedBoxes){
			case 1:
				this.checkboxes.each(function(checkbox){
					if(checkbox.checked){
						$A(this.select.options).each(function(option,i){
							if(option.value == checkbox.value){
								this.select.options.selectedIndex = i;
								throw $break;
							}
						}.bind(this));
						throw $break;
					}
				}.bind(this));
			case 0:
				this.removeExtraOption();
				break;
			default:
				this.addExtraOption();
				break;
		};
	},
	getLabelForExtraOption: function(){
		var label = (typeof(this.options.nameSelector) == 'function' 
			? this.options.nameSelector.bind(this)()
			: this.container.getElementsBySelector(this.options.nameSelector).inject([],function(labels,name_element,i){
				if(this.checkboxes[i].checked)
					labels.push(name_element.innerHTML);
				return labels;
			}.bind(this))
		).join(this.options.labelSeparator);
		return (label.length >= this.options.overflowLength && this.options.overflowLength > 0)
			? (typeof(this.options.overflowString) == 'function' ? this.options.overflowString(label) : this.options.overflowString)
			: label
		;
	},
	getValueForExtraOption: function(){
		return this.checkboxes.inject([],function(values,checkbox){
			if(checkbox.checked)
				values.push(checkbox.value);
			return values;
		}).join(this.options.valueSeparator);
	},
	addExtraOption: function(){
		this.removeExtraOption();
		this.hasExtraOption = true;
		this.select.options[this.select.options.length] = new Option(this.getLabelForExtraOption(),this.getValueForExtraOption());
		this.select.options.selectedIndex = this.select.options.length - 1;
	},
	removeExtraOption: function(){
		if(this.hasExtraOption){
			this.select.remove(this.select.options.length - 1);
			this.hasExtraOption = false;
		}
	},
	notify: function(event_name){
		try{
			if(this.options[event_name])
				return [this.options[event_name].apply(this.options[event_name],$A(arguments).slice(1))];
		}catch(e){
			if(e != $break)
				throw e;
			else
				return false;
		}
	}
});
if(typeof(Object.Event) != 'undefined')
	Object.Event.extend(Control.SelectMultiple);