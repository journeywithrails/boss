class UpdateDatetimeColumnsToUtc < ActiveRecord::Migration
  def self.up
    tables.each do |table|
      columns(table).each do |column|
        if column.type == :datetime or column.type == :time
          update "UPDATE #{table} SET #{column.name} = CONVERT_TZ(#{column.name}, 'SYSTEM', '+00:00')"
        end
      end
    end
  end

  def self.down
  end
end