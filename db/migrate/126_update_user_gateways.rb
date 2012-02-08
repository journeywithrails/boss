class UpdateUserGateways < ActiveRecord::Migration
  def self.up
    UserGateway.update_all("currency = 'USD'", "type = 'SageUserGateway'")
    UserGateway.update_all("currency = 'CAD', type = 'SageUserGateway'", "type = 'SageUserGatewayCdn'")
  end

  def self.down
    UserGateway.update_all("type = 'SageUserGatewayCdn'", "currency = 'CAD' and type = 'SageUserGateway'")
  end
end
