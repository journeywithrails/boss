require File.dirname(__FILE__) + '/../test_helper'

class SpaccountTest < ActiveSupport::TestCase

  def test_find_by_friendly_id
    @spaccount = Spaccount.find("InactiveSPAccountName")
    assert_not_nil @spaccount
    assert_equal "OneSPFirstName", @spaccount.first_name, "OneSPFirstName should be the first_name of the spaccount found by friendly id"
  end
  
  def test_find_by_id
    id = spaccounts(:inactive_account).id
    @spaccount = Spaccount.find(id)
    assert_not_nil @spaccount
    assert_equal "OneSPFirstName", @spaccount.first_name, "OneSPFirstName should be the first_name of the spaccount found by id"
  end
  
  def test_find_first_by_spaccount_name
    @spaccount = [Spaccount.find(:first, :conditions => {:spaccount_name => "InactiveSPAccountName"})].flatten
    assert_equal 1, @spaccount.size, "There should be 1 elements when find by first"    
    assert_equal "OneSPFirstName", @spaccount[0].first_name, "OneSPFirstName should be the first_name of the spaccount found first by id"
  end
  
  def test_find_first_by_province
    @spaccount = [Spaccount.find(:first, :conditions => {:state_prov => "BC"})].flatten
    assert_equal 1, @spaccount.size, "There should be 1 elements when find by first"  
    assert_equal "BC", @spaccount[0].state_prov, "BC should be the province of the spaccount found first by province BC"
  end  
  
  def test_find_all
    @spaccounts = [Spaccount.find(:all)].flatten
    assert_equal 3, @spaccounts.size, "There should be 3 elements when finding all spaccounts"
  end
  
  def test_add_duplicate_spaccount_name
    spaccount = create_new_account
    spaccount.spaccount_name = "InactiveSPAccountName"
    spaccount.save
    assert_equal 1, spaccount.errors.size, "The errors array should have 1 message after adding duplicate apaccount name"
  end

#  def test_invalid_credentials
#    spaccount = create_new_account("wrong", "wrong")
#    spaccount.save
#    assert spaccount.errors.size > 0, "The errors array should at least 1 message after attempting to add without credentials"    
#  end
#  
#  def test_valid_credentials
#    spaccount = create_new_account
#    spaccount.save
#    assert_equal 0, spaccount.errors.size, "The errors array should be empty when adding with correct credentials"    
#  end
  
  def test_duplicate_transaction_id
    spaccount = create_new_account(:transaction_id => 1)
    spaccount.save
    assert_equal 1, spaccount.errors.size, "The errors array should have one error when adding with a duplicate transaction id"    
  end
  
  def test_should_create_new_user_from_spaccount_params
    p =  Spaccount.new_user_params(new_account_params(:spaccount_name => 'NewAccount', :email =>'email@test.com'))
    u = User.new(p)
    u.crypted_password = '*'
    u.signup_type = 'pe'
    assert_difference('User.count', 1) do   
      u.save
    end
    u.reload
    assert_equal 'NewAccount', u.sage_username
    assert_equal 'email@test.com', u.email
  end
  
  def test_should_create_profile_params_from_spaccount_params
    params = new_account_params(:spaccount_name => 'NewAccount', :company => 'Company Name', :first_name => 'First', :last_name => 'Last',
        :address => '1234 Some Street', :city => 'AnyTown', :state_prov => 'WA', :country => 'United States',
        :zip_postal => '1234567', :phone => '555-555-5555', :email => 'email@test.com')
    u = User.new(Spaccount.new_user_params(params))
    u.crypted_password = '*'
    u.signup_type = 'pe'
    assert_difference('User.count', 1) do    
      u.save
    end
    
    spaccount = Spaccount.new(params)
    spaccount.user = u
    u.populate_profile(spaccount.new_profile_params)
    u.reload
    
    assert_equal "Company Name", u.profile.company_name
    assert_equal "First Last", u.profile.contact_name
    assert_equal '1234 Some Street', u.profile.company_address1
    assert_equal 'AnyTown', u.profile.company_city
    assert_equal 'WA', u.profile.company_state
    assert_equal 'United States', u.profile.company_country
    assert_equal '1234567', u.profile.company_postalcode
    assert_equal '555-555-5555', u.profile.company_phone
  end
  
  private
    def new_account_params(params={})
      params[:transaction_id] ||= UUIDTools::UUID.timestamp_create().to_s
      params
    end
    
    def create_new_account(params={})
      Spaccount.new(new_account_params(params))
    end
  
end


