require File.dirname(__FILE__) + '/../test_helper'
include Sage::BusinessLogic::Exception

class WinnersTest < Test::Unit::TestCase
  def test_disallows_blanks
    w = Winner.new
    deny w.valid?
    w.winner_name = "asdf"
    w.draw_date = Date.today
    deny w.valid?
    w.prize = "asdf"
    w.winner_name = nil
    deny w.valid?
    w.winner_name = "asdf"
    w.draw_date = nil
    deny w.valid?
    w.draw_date = Date.today
    assert w.valid?
  end
end