class ModifyActivitiesTable < ActiveRecord::Migration
  def self.up
    add_column :activities, :extra, :string
    
    # update old static strings
    @activities = Activity.find(:all)
    @activities.each do |activity|
      case activity.body
      when /Sent/
        activity.extra = activity.body.gsub("Sent by email to ","")
        activity.body = "sent"
      when /Viewed/
        activity_string_array = activity.body.split(" ")
        activity.body = activity_string_array[0].downcase
        activity.extra = activity_string_array[3]
      when /Created/
        activity.body = "created"
      when /Updated/
        activity.body = "updated"
      when /bounced/ 
        activity.body = "bounced"
      when /applied/
        activity.extra = /\(.*?\)/m.match(activity.body)[0]
        activity.body = "payment_applied"
      when /edited/
        activity.extra = /\(.*?\)/m.match(activity.body)[0]
        activity.body = "payment_edited"
      when /deleted/
        activity.extra = /\(.*?\)/m.match(activity.body)[0]
        activity.body = "payment_deleted"
      end
      activity.save!
    end
    
  end

  def self.down
    remove_column :activities, :extra
  end
end
