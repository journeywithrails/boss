$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__

# acceptance test for user story 87
# accept bookkeeper invitation
# an invitation will be generated from code
# the key will be used to navigate to the acceptance link rather
# than click a link in an email that would be the normal procedure

# the test cases will be:
#   a) the invited bookkeeper creates an account
#   b) the invited bookkeeper has an account and signs on
#   c) the invited bookkeeper is already signed on

# this uses test/acceptance/87_accept_invitation_test, and just overrides stubbing_cas? 
# to return true. That test tucks away all the stubbed sso or real sso parts. 

require File.dirname(__FILE__) + '/../acceptance/87_accept_invitation_test'

require File.dirname(__FILE__) + '/sso_test_helper'
require File.dirname(__FILE__) + '/sso'
# reload acceptance_test_helper, because loading sso_test_helper will
# re-require test_helper because it's load path will look different
# and that means we need to re-set use_transactional_fixtures to false.
require File.dirname(__FILE__) + '/../acceptance/acceptance_test_helper'


class AcceptBookkeepingInvitation
  def stubbing_cas?
    false
  end
end
