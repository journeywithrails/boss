require 'test/test_helper'

#require File.dirname(__FILE__) +'/../init.rb'
require File.dirname(__FILE__) +"/../lib/css_form_support.rb"
require File.dirname(__FILE__) +"/../lib/css_form_builder.rb"
require File.dirname(__FILE__) +"/../lib/css_show_builder.rb"

def _(s); "__#{s}__" end

class String
  def t
    "**#{self}**"
  end
end

class CssFormSupportTest < Test::Unit::TestCase

  include Test::Unit::Assertions
  include ActiveSupport::CoreExtensions::Hash::Keys
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::CaptureHelper
  include ApplicationHelper
  
  def test_no_translate
    CssBuilder.no_translate
    assert_equal 'String','String'.translate
  end
  
  def test_translate_as_gettext
    CssBuilder.translate_as_gettext    
    assert_equal '__String__','String'.translate
  end
  
  def test_translate_as_globalize
    CssBuilder.translate_as_globalize
    assert_equal '**String**','String'.translate
  end
  
  def test_block_tag
    _erbout = ''
    block_tag("div",:class=>'aa') do
      _erbout.concat 'AAA'
    end
    assert_dom_equal "<div class='aa'>AAA</div>", _erbout
  end
  
  def test_fieldset_tag
    _erbout = ''
    fieldset_tag("A legend",:class=>'aa') do
      _erbout.concat 'AAA'
    end
    assert_dom_equal "<fieldset class='aa'><legend>A legend</legend>AAA</fieldset>", _erbout
  end
  
end
