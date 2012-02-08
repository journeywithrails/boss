require File.dirname(__FILE__) + '/../test_helper'
require 'application'

class PollingForTestController < ApplicationController; def rescue_action(e) raise e end; end

class ApplicationTest < Test::Unit::TestCase
  def xxx_test_polling_for_should_time_out
    c = PollingForTestController.new
    counter = 0
    c.polling_for(:max_time => 0.75) do
      counter += 1
    end
    puts counter
  end
end