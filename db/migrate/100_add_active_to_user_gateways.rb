class AddActiveToUserGateways < ActiveRecord::Migration
  def self.up
    add_column :user_gateways, :active, :boolean, :default=>true
  end

  def self.down
    #Remove all inactive gateways as they will confuse the profile after migrating down
    UserGateway.find(:all, :conditions =>{:active=>false}).each do |g|
      g.destroy
    end
    
    remove_column :user_gateways, :active  
  end
end
