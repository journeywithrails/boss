class InsertWinnersAdminRole < ActiveRecord::Migration
  def self.up
    ["winners_admin"].each do |i|
      a = Role.new
      a.name = i
      a.save!
    end
  end

  def self.down
    ["winners_admin"].each do |i|
      a = Role.find(:first, :conditions => {:name => i })
      a.destroy
    end    
  end
end