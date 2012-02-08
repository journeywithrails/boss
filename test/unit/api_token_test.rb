require File.dirname(__FILE__) + '/../test_helper'

class ApiTokenTest < Test::Unit::TestCase
  def test_guid
    t = make_token
    assert_nil t[:guid]
    assert t.guid
    assert_match /\A\w{32}\Z/, t[:guid]
  end

  def test_guid_twice
    t = make_token
    guid = t.guid
    assert_equal guid, t.guid
  end

  def test_make_guid
    t = make_token
    t.expects(:make_guid)
    t.save!
  end

  private

  def make_token
    ApiToken.new
  end
end
