class Bounce < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :delivery
  
  def self.create_for(email)
    return unless delivery_match = email.match(/X-Delivery-ID:\s+(\d+)/mi)
    process_bounce(delivery_match, email)
  end
  
  def self.process_bounce(delivery_match, content)
    delivery_id = delivery_match[1]
           
    delivery = Delivery.find(delivery_id)
    user = delivery.created_by
    
    bounce = Bounce.create!(:user => user, :delivery => delivery, :body => content)
    delivery.bounce!
    Activity.log_bounce!(delivery, bounce.id)
    BounceMailer.deliver_forward_bounce(user.email, bounce)
  end
end
