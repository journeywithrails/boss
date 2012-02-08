require File.dirname(__FILE__) + '/../test_helper'

class TaxCalculatorTest < Test::Unit::TestCase
  include Sage::BusinessLogic::Exception
  fixtures :invoices
  fixtures :users
  fixtures :customers
  fixtures :configurable_settings

  def setup
    @qst_on_gst = [
      OpenStruct.new(
        :profile_key => 'tax_1',
        :enabled => true,
        :name => 'GST',
        :rate => BigDecimal.new('5.0'),
        :included => false,
        :taxed_on => []
      ),
      OpenStruct.new(
        :profile_key => 'tax_2',
        :enabled => true,
        :name => 'QST',
        :rate => BigDecimal.new('7.5'),
        :included => false,
        :taxed_on => ['tax_1']
      )
    ]
    
    @qst_on_gst_all_included = [
      OpenStruct.new(
        :profile_key => 'tax_1',
        :enabled => true,
        :name => 'GST',
        :rate => BigDecimal.new('5.0'),
        :included => true,
        :taxed_on => []
      ),
      OpenStruct.new(
        :profile_key => 'tax_2',
        :enabled => true,
        :name => 'QST',
        :rate => BigDecimal.new('7.5'),
        :included => true,
        :taxed_on => ['tax_1']
      )
    ]
  end

  def test_should_calculate_zero_tax
    tc = TaxCalculator.new([])
    sum = tc.sum_of.all_taxes(BigDecimal.new('100.0'))
    assert_equal BigDecimal.new('0'), sum
  end
  
  def test_should_calculate_gst
    taxes = [
      OpenStruct.new(
        :enabled => true,
        :name => 'GST',
        :rate => BigDecimal.new('7.0'),
        :included => false,
        :taxed_on => []
      )
    ]
    
    tc = TaxCalculator.new(taxes)
    assert_equal BigDecimal.new('7'), tc.sum_of.not_included_taxes(BigDecimal.new('100.0'))
    assert_equal BigDecimal.new('0'), tc.sum_of.included_taxes(BigDecimal.new('100.0'))
    assert_equal BigDecimal.new('7'), tc.sum_of.all_taxes(BigDecimal.new('100.0'))
  end
  
  def test_should_calculate_gst_included
    taxes = [
      OpenStruct.new(
        :enabled => true,
        :name => 'GST',
        :rate => BigDecimal.new('7.0'),
        :included => true,
        :taxed_on => []
      )
    ]
    
    tc = TaxCalculator.new(taxes)
    assert_equal BigDecimal.new('7'), tc.sum_of.included_taxes(BigDecimal.new('107.0'))
    assert_equal BigDecimal.new('7'), tc.sum_of.all_taxes(BigDecimal.new('107.0'))
  end

  def test_should_calculate_gst_and_pst
    taxes = [
      OpenStruct.new(
        :enabled => true,
        :name => 'GST',
        :rate => BigDecimal.new('6.0'),
        :included => false,
        :taxed_on => []
      ),
      OpenStruct.new(
        :enabled => true,
        :name => 'PST',
        :rate => BigDecimal.new('7.0'),
        :included => false,
        :taxed_on => []
      )
    ]
    
    tc = TaxCalculator.new(taxes)
    assert_equal BigDecimal.new('13'), tc.sum_of.not_included_taxes(BigDecimal.new('100.0'))
    assert_equal BigDecimal.new('13'), tc.sum_of.all_taxes(BigDecimal.new('100.0'))
  end
  
  def test_should_calculate_gst_included_and_pst
    taxes = [
      OpenStruct.new(
        :enabled => true,
        :name => 'GST',
        :rate => BigDecimal.new('6.0'),
        :included => true,
        :taxed_on => []
      ),
      OpenStruct.new(
        :enabled => true,
        :name => 'PST',
        :rate => BigDecimal.new('7.0'),
        :included => false,
        :taxed_on => []
      )
    ]
    
    tc = TaxCalculator.new(taxes)
    assert_equal BigDecimal.new('7'), tc.sum_of.not_included_taxes(BigDecimal.new('106.0'))
    assert_equal BigDecimal.new('6'), tc.sum_of.included_taxes(BigDecimal.new('106.0'))
    assert_equal BigDecimal.new('13'), tc.sum_of.all_taxes(BigDecimal.new('106.0'))
  end
  
  def test_should_calculate_gst_and_pst_all_included
    taxes = [
      OpenStruct.new(
        :enabled => true,
        :name => 'GST',
        :rate => BigDecimal.new('6.0'),
        :included => true,
        :taxed_on => []
      ),
      OpenStruct.new(
        :enabled => true,
        :name => 'PST',
        :rate => BigDecimal.new('7.0'),
        :included => true,
        :taxed_on => []
      )
    ]
    
    tc = TaxCalculator.new(taxes)
    assert_equal BigDecimal.new('13'), tc.sum_of.included_taxes(BigDecimal.new('113.0'))
    assert_equal BigDecimal.new('13'), tc.sum_of.all_taxes(BigDecimal.new('113.0'))
  end

  def test_should_raise_cyclic_tax_on_tax_error
    taxes = [
      OpenStruct.new(
        :profile_key => 'tax_1',
        :enabled => true,
        :name => 'GST',
        :rate => BigDecimal.new('6.0'),
        :included => true,
        :taxed_on => ['tax_2']
      ),
      OpenStruct.new(
        :profile_key => 'tax_2',
        :enabled => true,
        :name => 'PST',
        :rate => BigDecimal.new('7.0'),
        :included => true,
        :taxed_on => ['tax_1']
      )
    ]
    
    assert_raises Sage::BusinessLogic::Exception::Error do
      tc = TaxCalculator.new(taxes)
      tc.sum_of.included_taxes(BigDecimal.new('113.0'))
    end
  end

  def test_should_raise_nonexistent_dependency_error
    taxes = [
      OpenStruct.new(
        :profile_key => 'tax_1',
        :enabled => true,
        :name => 'GST',
        :rate => BigDecimal.new('6.0'),
        :included => false,
        :taxed_on => ['tax_non-existent']
      )
    ]
    
    assert_raises Sage::BusinessLogic::Exception::Error do
      tc = TaxCalculator.new(taxes)
      tc.sum_of.included_taxes(BigDecimal.new('100.0'))
    end
  end

  def test_should_calculate_qst_on_gst
    tc = TaxCalculator.new(@qst_on_gst)
    assert_equal BigDecimal.new('12.88'), tc.sum_of.not_included_taxes(BigDecimal.new('100.0'))
    assert_equal BigDecimal.new('12.88'), tc.sum_of.all_taxes(BigDecimal.new('100.0'))
 end

  def test_should_round_qst_on_gst_sum_but_not_amounts
  end

  def test_should_calculate_qst_on_gst_all_included
    tc = TaxCalculator.new(@qst_on_gst_all_included)
    assert_equal BigDecimal.new('12.88'), tc.sum_of.included_taxes(BigDecimal.new('112.88'))
    assert_equal BigDecimal.new('12.88'), tc.sum_of.all_taxes(BigDecimal.new('112.88'))
  end

  def test_should_round_tax_sum_but_not_amounts
    tc1 = TaxCalculator.new(@qst_on_gst)

    # This also ensures that rounded sum is done like ROUND(a) + ROUND(b) instead of ROUND(a+b)
    assert_equal BigDecimal.new('128.49'), tc1.sum_of.not_included_taxes(BigDecimal.new('997.93'))
    assert_equal BigDecimal.new('49.8965'),     @qst_on_gst[0].amount
    assert_equal BigDecimal.new('78.5869875'),  @qst_on_gst[1].amount

    tc2 = TaxCalculator.new(@qst_on_gst_all_included)
    assert_equal BigDecimal.new('128.49'), tc2.sum_of.included_taxes(BigDecimal.new('1126.42'))
    assert_equal BigDecimal.new('49.89678848').round(8),  @qst_on_gst_all_included[0].amount.round(8)
    assert_equal BigDecimal.new('78.58744186').round(8),  @qst_on_gst_all_included[1].amount.round(8)
  end

  # Documenting Trac #2055
  # http://sagespark-trac.sourcerepo.com/sagespark_tornado/ticket/2055
  def test_should_do_two_stages_calculation
    taxes = [
      OpenStruct.new(
        :profile_key => 'tax_1',
        :enabled => true,
        :name => 'GST',
        :rate => BigDecimal.new('5.0'),
        :included => false,
        :taxed_on => []
      ),
      OpenStruct.new(
        :profile_key => 'tax_2',
        :enabled => true,
        :name => 'QST',
        :rate => BigDecimal.new('7.5'),
        :included => false,
        :taxed_on => ['tax_1']
      )
    ]

    tc = TaxCalculator.new(taxes)
    assert_equal BigDecimal.new('128.48'), tc.sum_of.not_included_taxes( BigDecimal.new('997.90') )
    #and result of "three stages" calculation would be: 128.49


  end

end
