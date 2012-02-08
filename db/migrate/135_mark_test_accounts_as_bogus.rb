class MarkTestAccountsAsBogus < ActiveRecord::Migration
  def self.up
    execute "update users set bogus = 1 where login like '%@sage%' or login like '%@_.com' or login like '%test%' or login like 'richardzhouca%' or login like 'lori_farrow%' or login like 'elee%' or login like 'celeduc%' or login like 'cleduc%'"
  end

  def self.down
  end
end
