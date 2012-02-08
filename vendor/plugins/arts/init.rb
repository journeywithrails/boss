# Give testing some culture
if RAILS_ENV == 'test'
  require 'test/unit/testcase'
  Test::Unit::TestCase.send :include, Arts
end
