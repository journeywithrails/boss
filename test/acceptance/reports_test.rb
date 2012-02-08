$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'
require File.dirname(__FILE__) + '/acceptance_test_helper'

class ReportsTest < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :users, :invoices, :customers
  
  def setup
    @user = watir_session.with(:basic_user)
    @user.logs_in
  end
  
  def test_basic
    @user.recalc_invoices
    @user.goto @user.site_url + '/reports/invoice'
    @user.expects_ajax(1,0)
    
    #TODO: Test filter works with reports.
    sleep 22
    assert_match /Invoice Report.*/, @user.span(:class,'x-panel-header-text').text,
      'The EXT grid should have the expected heading.'
    assert_equal 'Displaying invoices 1 - 10 of 20', @user.div(:class,'x-paging-info').text,
      'The EXT grid should show the expected paging info.'
    
    # The total of totals is in the fifth total in the summary row.
    totalsFound = 0
    totalOfTotals = 0
    @user.spans.each do |s|
      if s.class_name == 'report_summary positive'
        totalsFound += 1
        if totalsFound == 5
          totalOfTotals = s.text.gsub(/,/, '').to_f
          break
        end
      end
    end
    
    total = 0
    @user.links.each do |link|
      if link.id =~ /link-8/
        total += link.text.gsub(/,/, '').to_f
      end
    end

    # click the next button
    @user.expects_ajax(1) do
      @user.button(:class, "x-btn-text x-tbar-page-next").click
    end    
    
    assert_equal 'Displaying invoices 11 - 20 of 20', @user.div(:class,'x-paging-info').text,
      'The EXT grid should show the expected paging info.'
      
    @user.links.each do |link|
      if link.id =~ /link-8/
        total += link.text.gsub(/,/, '').to_f
      end
    end

    assert_equal total, totalOfTotals,
      "Report total should be #{total} and was #{totalOfTotals}."
  end
  
  def teardown
   @user.teardown
  end

  
end

