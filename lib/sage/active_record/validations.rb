Dir.glob(File.join(File.dirname(__FILE__), 'validations/*.rb')).each {|f| require f }