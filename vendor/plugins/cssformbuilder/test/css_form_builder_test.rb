require 'test/test_helper'

#require File.dirname(__FILE__) +'/../init.rb'
require File.dirname(__FILE__) +"/../lib/css_form_support.rb"
require File.dirname(__FILE__) +"/../lib/css_form_builder.rb"
require File.dirname(__FILE__) +"/../lib/css_show_builder.rb"

def _(s); "__#{s}__" end

class CssFormBuilderTest < Test::Unit::TestCase

  include Test::Unit::Assertions
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::FormOptionsHelper
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::PrototypeHelper
  
  #just copied from original FormHelperTest
  
  silence_warnings do
    Post = Struct.new("Post", :title, :author_name, :body, :secret, :written_on, :cost)
    Post.class_eval do
      alias_method :title_before_type_cast, :title unless respond_to?(:title_before_type_cast)
      alias_method :body_before_type_cast, :body unless respond_to?(:body_before_type_cast)
      alias_method :author_name_before_type_cast, :author_name unless respond_to?(:author_name_before_type_cast)
    end
  end
  
  def setup
    @post = Post.new
    def @post.errors() Class.new{ def on(field) field == "author_name" end }.new end

    def @post.id; 123; end
    def @post.id_before_type_cast; 123; end

    @post.title       = "Hello World"
    @post.author_name = ""
    @post.body        = "Back to the hill and over it again!"
    @post.secret      = 1
    @post.written_on  = Date.new(2004, 6, 15)

    @controller = Class.new do
      attr_reader :url_for_options
      def url_for(options, *parameters_for_method_reference)
        @url_for_options = options
        "http://www.example.com"
      end
    end
    @controller = @controller.new
    CssBuilder.no_translate
  end

  def test_css_form_for
    _erbout = ''
    form_for(:post, @post, :html=>{:class=>'cssform'}) do |f|
      _erbout.concat "<label>Title:" + f.text_field(:title) +"</label>"
    end
    expected=_erbout
 
    _erbout = ''
    css_form_for(:post, @post) do |f|
      _erbout.concat f.text_field(:title)
    end
    assert_dom_equal expected, _erbout
  end
  
  def test_remote_css_form_for
    _erbout = ''
    remote_form_for(:post, @post, :html=>{:class=>'cssform'}) do |f|
      _erbout.concat "<label>Title:" + f.text_field(:title) +"</label>"
    end
    expected=_erbout
 
    _erbout = ''
    remote_css_form_for(:post, @post) do |f|
      _erbout.concat f.text_field(:title)
    end
    assert_dom_equal expected, _erbout
  end
  
  def test_css_fields_form_for
    _erbout = ''
    fields_for(:post, @post) do |f|
      _erbout.concat "<label>Title:" + f.text_field(:title) +"</label>"
    end
    expected=_erbout
 
    _erbout = ''
    css_fields_for(:post, @post) do |f|
      _erbout.concat f.text_field(:title)
    end
    assert_dom_equal expected, _erbout
  end
  
  def test_text_field_with_label
    _erbout = ''
    expected="<label>Custom label:"+text_field(:post,:title)+"</label>"
    css_form_for(:post, @post) do |f|
      assert_dom_equal expected, f.text_field(:title, :label=>'Custom label')
    end
  end
  
  def test_text_field_with_extra_tag
    _erbout = ''
    expected="<label>Custom label:"+text_field(:post,:title)+"<span style='float:left'>XYZ</span></label>"
    css_form_for(:post, @post) do |f|
      assert_dom_equal expected, f.text_field(:title, {:label=>'Custom label', :extra=>'XYZ'})
    end
  end
  
  def test_text_field_with_error_and_class
    _erbout = ''
    expected="<label>Author name:"+text_field(:post,:author_name,:class=>'double-size')+"</label>"
    css_form_for(:post, @post) do |f|
      assert_dom_equal expected, f.text_field(:author_name,:class=>'double-size')
    end
  end
  
  def test_field_with_translated_label
    CssBuilder.translate_as_gettext
    _erbout = ''
    expected="<label>__Title__:"+text_field(:post,:title)+"</label>"
    css_form_for(:post, @post) do |f|
      assert_dom_equal expected, f.text_field(:title)
    end
  end
  
  def test_hidden_field
    _erbout = ''
    expected = hidden_field(:post,:title)
    css_form_for(:post, @post) do |f|
      assert_dom_equal expected, f.hidden_field(:title)
    end
  end
    
  def test_select
    _erbout = ''
    expected = "<label>Title:"+select(:post,:title,['a','b'])+"</label>"
    css_form_for(:post, @post) do |f|
      assert_dom_equal expected, f.select(:title, ['a','b'])
    end
  end
  
  def test_select_with_choises
    _erbout = ''
    expected = "<label>Title:<select name='post[title]' id='post_title'>"+options_for_select([["Dollar", "$"], ["Kroner", "DKK"]])+"</select></label>"
    css_form_for(:post, @post) do |f|
      assert_dom_equal expected, f.select_with_choises(:title,  options_for_select([["Dollar", "$"], ["Kroner", "DKK"]]))
    end
  end
  
  def test_check_box
    _erbout = ''
    expected = "<label>Secret:"+check_box(:post,:secret)+"</label>"
    css_form_for(:post, @post) do |f|
      assert_dom_equal expected, f.check_box(:secret)
    end
  end
    
  def test_radio_button
    _erbout = ''
    expected = "<label>Secret:"+radio_button(:post,:secret,'V')+"</label>"
    css_form_for(:post, @post) do |f|
      assert_dom_equal expected, f.radio_button(:secret,'V')
    end
  end
  
  def test_date_select
    _erbout = ''
    expected = "<label>Written on:"+date_select(:post,:written_on)+"</label>"
    css_form_for(:post, @post) do |f|
      assert_dom_equal expected, f.date_select(:written_on)
    end
  end
  
end
