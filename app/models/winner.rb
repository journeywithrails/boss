class Winner < ActiveRecord::Base
  validates_presence_of :draw_date
  validates_presence_of :prize
  validates_presence_of :winner_name
end