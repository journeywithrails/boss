require File.dirname(__FILE__) + '/../test_helper'

class AdminManagerTest < ActiveSupport::TestCase
  fixtures :users, :roles, :roles_users
  
  def test_admin_users_count
    num = AdminManager.admin_users.count
    assert_equal num, 3
  end
  
  def test_admin_roles_count
    num = AdminManager.admin_roles.count
    assert_equal num, 3
  end
    
end
