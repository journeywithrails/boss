require File.dirname(__FILE__) + '/../test_helper'

class CurrencyTest < Test::Unit::TestCase
  
  def test_rounds_amount #TODO round should be an instance method, and there should be a factory
    amt = BigDecimal.new('4.67982')
    assert_equal('4.68', Currency.round(amt).to_s)
  end
  
  def test_valid_currency
    [nil, "", "abcd", "USd", "U SD", "U.S.D", "USDa", "$"].each do |c|
      deny Currency.valid_currency?(c)
    end
    
    ["USD", "CAD", "EUR", "GBP"].each do |c|
      assert Currency.valid_currency?(c)
    end
  end
  
  def test_currency_symbol
    assert_equal "$", Currency.currency_symbol("USD")
    assert_equal "Can$", Currency.currency_symbol("CAD")
    assert_equal "&#8364;", Currency.currency_symbol("EUR")
    assert_equal "&#163;", Currency.currency_symbol("GBP")
  end
  
  def test_default_currency
    assert_equal "USD", Currency.default_currency
  end
  
  def test_currency_for_country
    # Countries have currencies, but not all currencies have just one country,
    # so make sure currency_hash is in agreement with currencies_for_countries.
    Currency.currency_hash.each do |c|
      if !c[1][:country].blank? and c[1][:country] != 'CU' # Cuba has two currencies, ignore
        assert_equal c[1][:currency], Currency.currency_for_country( c[1][:country] ), "Testing #{c[1][:country]}:"
      end
    end
  end
  
  def test_default_currencies_for_countries_are_valid
    # look at every defined country and make sure that the defined currency for that country is valid
    ActionView::Helpers::FormOptionsHelper::COUNTRIES.each do |c|
      assert Currency.valid_currency?( Currency.currency_for_country(c[1])), "Testing #{c[0]} (#{c[1]}):"
    end
  end

  def test_currency_defaults_are_for_valid_countries
    # look at the currencies defined for countries and makes sure those countries are valid
    Currency.currencies_for_countries.each do |c|
      assert !ActionView::Helpers::FormOptionsHelper::COUNTRIES.rassoc(c[0]).nil?, "Testing #{c[0]}:"
    end
  end
end
