
require 'acts_as_keyed'
ActiveRecord::Base.send(:include, LastObelus::Acts::Keyed)

require 'access_key'