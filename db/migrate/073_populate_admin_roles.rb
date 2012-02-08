class PopulateAdminRoles < ActiveRecord::Migration
  def self.up
    ["admin", "master_admin", "feedback_admin"].each do |i|
      a = Role.new
      a.name = i
      a.save!
    end
  end

  def self.down
    ["admin", "master_admin", "feedback_admin"].each do |i|
      a = Role.find(:first, :conditions => {:name => i })
      a.destroy
    end    
  end
end