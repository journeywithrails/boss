class SplitSageUserGateways < ActiveRecord::Migration
  def self.up
    UserGateway.update_all("type = 'SageVcheckUserGateway'", "type = 'SageUserGateway' and gateway_name = 'sage_vcheck'")
    UserGateway.update_all("type = 'SageSbsUserGateway'", "type = 'SageUserGateway'")
  end

  def self.down
    UserGateway.update_all("type = 'SageUserGateway'", "type = 'SageSbsUserGateway' or type = 'SageVcheckUserGateway'")
  end
end
