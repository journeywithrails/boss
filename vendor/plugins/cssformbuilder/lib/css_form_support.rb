
class CssBuilder
  @@translate= :translate_none

  def self.translate(s)
    return _(s) if @@translate== :translate_gettext
    return s.t if @@translate== :translate_globalize
    s
  end
  
  #Do not translate labels and legends
  def self.no_translate
    @@translate= :translate_none
  end
  
  #Translate labels and legends using _() function
  def self.translate_as_gettext
    @@translate= :translate_gettext
  end

  #Translate labels and legends using .t method
  def self.translate_as_globalize
    @@translate= :translate_globalize
  end
  
end

class String
  def translate
    CssBuilder.translate(self)
  end
end

module ApplicationHelper  

  #like content_tag, but uses a block
  def block_tag(tag, options = {}, &block)
    concat(content_tag(tag, capture(&block), options), block.binding)
  end
  
  #generate a fieldset tag, including a _legend_ and the block content
  def fieldset_tag(legend, options = {}, &block)
    #FIXXME use block_tag
    concat(content_tag('fieldset', content_tag('legend',legend.translate) + capture(&block), options), block.binding)
  end
  
end


module ActionView
  class Base #:nodoc:
    @@field_error_proc = Proc.new{ |html_tag, instance| "<span class=\"fieldWithErrors\">#{html_tag}</span>" }
    cattr_accessor :field_error_proc
  end
end


module ActiveRecord
  class Base
    #find all items matching _condition_, and return an array of [value,key], useful for using with select
    def self.to_select(condition=nil,method='to_s')
      find(:all, :conditions=>condition).collect{|record| [record.send(method),record.id]}
    end
  end
end


class Hash
  def purge_custom_tags #:nodoc:
    self.reject{ |key,value| [:extra, :label].include?(key.to_sym) }
  end
end


module ActionView
  module Helpers
    module FormOptionsHelper  #:nodoc:
      def select_with_choises(object, method, choices, options = {}, html_options = {})
        InstanceTag.new(object, method, self, nil, options.delete(:object)).to_select_tag_with_choises(choices, options, html_options)
      end
    end
      
    class InstanceTag #:nodoc:
      def to_select_tag_with_choises(select_choices, options, html_options)
        html_options = html_options.stringify_keys
        add_default_name_and_id(html_options)
        content_tag("select", add_options(select_choices, options, value), html_options)
      end
    end
    
    class FormBuilder
      #like select but, instead of using a container (hash, array, enumerable, your type), accepts a string of option tags, that
      #can be obtained, for example, using option_groups_from_collection_for_select,
      #options_for_select,options_from_collection_for_select or other.
      #  
      def select_with_choises(method, select_choices, options = {}, html_options = {})
        @template.select_with_choises(@object_name, method, select_choices, options.merge(:object => @object), html_options)
      end
    end
  end
end
