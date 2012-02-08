class ChangeGatewayCodesToNames < ActiveRecord::Migration
  def self.up
    begin
      create_table :user_gateways do |t|
        t.string :type
        t.integer :user_id
        t.string :gateway_name
        t.string :merchant_id
        t.string :merchant_key
        t.string :login
        t.string :password
        t.string :email
      end 
      add_index :user_gateways, :user_id
      add_index :user_gateways, [:user_id, :gateway_name]
    rescue 
    end

    User.find(:all).each do |user|
      profile = user.profile
      params = 
        case profile.payment_method
        when '1'
          { :gateway_name => 'beanstream',
            :merchant_id => profile.beanstream_API_key,
            :login => profile.beanstream_user_id,
            :password => profile.beanstream_password }
        when '2'
          { :gateway_name => 'paypal',
            :email => profile.paypal_email_address }
        when '3'
          { :gateway_name => 'sage_vcheck',
            :merchant_id => profile.sage_merchant_id,
            :merchant_key => profile.sage_merchant_key }
        end
      if params
        ug = UserGateway.new_polymorphic(params)
        if ug
          user.user_gateways << ug
          user.save!
        end
      end
    end
  end

  def self.down
    drop_table :user_gateways
  end
end
