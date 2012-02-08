require 'yaml'
require 'ostruct'
require 'last_obelus/open_struct/extensions'
require 'last_obelus/hash/extensions'

module LastObelus
  module YAML
    module OYAML
      def self.included base
        base.extend ClassMethods    
      end
    
      def OYAML.load_file (filepath)
        ::YAML.use_ostruct
        out = ::YAML.load_file filepath
        ::YAML.dont_use_ostruct
        out
      end

      # loads a config file in which the top level keys are named 'common', 'test', 'development', 'production' etc
      # and returns an openStruct version in which the specified environment has been merged with 'common'
      def OYAML.load_scoped_config(filepath, environment)
        if File.exist?(filepath)
          config_all = OYAML.load_file(filepath)
          common = config_all.common
          with_env = config_all.send(environment)
          common.deep_merge!(with_env)
        else
          raise "Could not find #{filepath}"
        end
      end
    
      module ClassMethods
        @@use_ostruct = false
        def use_ostruct; @@use_ostruct = true; end
        def dont_use_ostruct; @@use_ostruct = false; end
        def use_ostruct?; @@use_ostruct; end
        class << ::YAML::DefaultResolver
          alias_method :_node_import, :node_import
    
          # RADAR: if the other module LastObelus::Hash::Extensions is going to be loaded first, have to use ::Hash here not just Hash
          def node_import(node)
            o = _node_import(node)
            (o.kind_of?(::Hash) and ::YAML.use_ostruct?) ? ::OpenStruct.new(o) : o
          end
        end
      end
      
    end    
  end
end
       
YAML.send :include, LastObelus::YAML::OYAML
