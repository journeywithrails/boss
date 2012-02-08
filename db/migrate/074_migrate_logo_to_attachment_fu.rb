require 'logo'
class MigrateLogoToAttachmentFu < ActiveRecord::Migration
  def self.up
    $MAGIC_SUX = true
    add_column :logos, :filename, :string
    Logo.find(:all).each do |logo|
      unless logo.logo.blank?
        segmented_id = File.join(*("%08d" % logo.id).scan(/..../))
        image_path = RAILS_ROOT + "/public/logo/logo/#{segmented_id}/#{logo.logo}" 
        puts image_path
        image_file = File.open(image_path, 'r')
        logo.set_from_file(image_file)
        unless logo.save
          puts "can't migrate logo #{logo.id} (#{logo.created_by.email})"
          logo.destroy
        end
      end
    end
  end
  
  def self.down
    # raise ActiveRecord::IrreversibleMigration, "Can't go back to file_column! You will lose the logo information if you run this! But the logo files will still be on s3."
    remove_column :logos, :filename    
  end
end
