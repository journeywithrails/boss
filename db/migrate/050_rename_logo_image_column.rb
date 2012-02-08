class RenameLogoImageColumn < ActiveRecord::Migration
  def self.up
    rename_column :logos, :filename, :logo
    #File.rename File.join(RAILS_ROOT, "public", "logo", "filename"), File.join(RAILS_ROOT, "public", "logo", "logo")
  end

  def self.down
    rename_column :logos, :logo, :filename
    #File.rename File.join(RAILS_ROOT, "public", "logo", "logo"), File.join(RAILS_ROOT, "public", "logo", "filename")
  end
end
