class SetExistingBeanStreamUserGatewaysToCad < ActiveRecord::Migration
  def self.up
    UserGateway
    # All existing beanstream gateways implicitly supported only CAD. This is
    # required for USD support:
    BeanStreamUserGateway.update_all("currency = 'CAD'", "currency is null")
  end

  def self.down
  end
end
