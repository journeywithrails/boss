# this is the base class of all keyable settings
class AccessKey < ActiveRecord::Base
  belongs_to :keyable, :polymorphic => true

  # ==For migration up
  # in your migration self.up method:
  #   <tt>ConfigurableSetting.create_table</tt>
  def self.create_table
    self.connection.create_table :access_keys, :options => 'ENGINE=InnoDB' do |t|
      t.column :keyable_id,      :integer, :null => false
      t.column :keyable_type,    :string, :null => false
      t.column :created_at,      :datetime
      t.column :valid_until,     :datetime
      t.column :uses,            :integer, :default => 99999
      t.column :used,            :integer, :default => 0
      t.column :key,             :string, :null => false
    end
    self.connection.add_index :access_keys, :key
  end
  
  attr_accessible :uses, :valid_until
  
  # ==For migration down
  # in your migration self.down method:
  #   <tt>ConfigurableSetting.drop_table</tt>
  def self.drop_table
    self.connection.remove_index :keyable_settings, :name
    self.connection.drop_table :keyable_settings
  end
  
  # returns a string with the classname of keyable
  def self.keyable_class(keyable) # :nodoc:
    ActiveRecord::Base.send(:class_name_of_active_record_descendant, keyable.class).to_s
  end
  
  # returns the instance of the "owner" of the key
  def self.find_keyable(key)
    ak = AccessKey.find_by_key(key)
    ak.use? ? ak.keyable : nil
  end
  
  def make_key
    require 'uuidtools'
#    UUIDTools::UUID.sha1_create(UUID_OID_NAMESPACE, "#{self.keyable_type} #{self.keyable_id}").hexdigest
    UUIDTools::UUID.random_create.hexdigest   
  end
  
  def before_create
    self.key = self.make_key
  end
  
  def toggle_uses!
    self.uses>0 ? self.update_attribute(:uses, 0) : self.update_attribute(:uses, 99999)
  end
  
  def use?
    return false unless self.used < self.uses
    return false unless self.valid_until.nil? or self.valid_until > Time.now
    self.reload
    self.update_attribute(:used, (self.used + 1))
    true
  end
  
  def unuse!
    self.update_attribute(:used, (self.used - 1))
  end
  def to_s
    return self.key
  end
end