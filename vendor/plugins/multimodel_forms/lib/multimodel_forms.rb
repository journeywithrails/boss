# NOTE: Depends on the association name matching the association class
module ActiveRecord #:nodoc:
  module Acts
    module VirtualAttributes
      def self.included(base) # :nodoc:
        base.extend ClassMethods
      end

      module ClassMethods
        # has_many_with_attributes(:items, {:push => :user_id}, has_many args)
        def has_many_with_attributes(association_name, attr_options = {}, options = {}, &extension)
          # This is called when a form is submited.
          define_method "#{association_name}_attributes=" do |in_params|
            in_params.each do |params|
              if params[:id].blank?
                single = self.send("#{association_name}").build(params)
                unless attr_options[:push].blank?
                  inc = attr_options[:push]
                  inc = [inc] unless inc.instance_of?(Array)
                  inc.each do |i|
                    self.send(association_name).each do |x|
                      x.send("#{i}=", self.send(i))
                    end
                  end
                end
               else
                 single = self.send("#{association_name}").detect { |e| e.id == params[:id].to_i }
                 e_klass = attr_options[:not_found_exception]
                 e_klass ||= StandardError
                 raise e_klass.new("#{association_name.to_s.classify} (#{params[:id]}) requested for #{self.class.name} (#{self.id})") if single.nil?
                 params.delete(:id)
                 single.attributes = params
               end
            end
          end
          
          define_method "#{association_name}_attributes" do
            self.send(association_name).build
          end
    
          # class methods
          class_eval "after_update :save_#{association_name}"    
          if options.empty?
            class_eval "has_many(:#{association_name})"
          else
            class_eval "has_many(:#{association_name}, #{options.inspect})"
          end
    
          # this will destroy/save the through relation models after self is updated
          define_method "save_#{association_name}" do
            self.send(association_name).each do |x|
              unless x.frozen?
                x.should_destroy? ? x.destroy : x.save(false)
              end
            end
            self.send(association_name).delete_if{|x| x.should_destroy?} # so we don't have to reload the child association
          end

          # Through methods
          through = association_name.to_s.singularize.camelize.constantize
          through.class_eval "def should_destroy?; should_destroy.to_i == 1; end"
          through.class_eval "def should_destroy; @should_destroy ||= 0; end" # always have a value to avoid holes in array params in forms
          through.class_eval "attr_writer :should_destroy"
        end

        def belongs_to_with_attributes(association_name, attr_options = {}, options = {}, &extension)
          to_one_with_attributes("belongs_to", association_name, attr_options, options, &extension)
        end
        def has_one_with_attributes(association_name, attr_options = {}, options = {}, &extension)
          to_one_with_attributes("has_one", association_name, attr_options, options, &extension)
        end

        def to_one_with_attributes(to_name, association_name, attr_options = {}, options = {}, &extension)
          # This is called when a form is submited.
          define_method "#{association_name}_attributes=" do |in_params|
            in_params.delete(:id)
            if self.send("#{association_name}").nil?
              single = self.send("build_#{association_name}")
            else
              single = self.send("#{association_name}")
            end
            single.attributes = in_params
            unless attr_options[:push].blank?
              inc = attr_options[:push]
              inc = [inc] unless inc.instance_of?(Array)
              inc.each do |i|
                single.send("#{i}=", self.send(i))
              end
            end
          end

          through = association_name.to_s.singularize.camelize.constantize
          
          define_method "#{association_name}_attributes" do
            #self.send("build_#{association_name}") #RADAR don't do this results in current has-one association having it's fk set to null !!!
            through.new
          end
    
          # class methods
          class_eval "after_update :save_#{association_name}"    
          if options.empty?
            class_eval "#{to_name}(:#{association_name})"
          else
            class_eval "#{to_name}(:#{association_name}, #{options.inspect})"
          end
    
          # this will destroy/save the through relation models after self is updated
          define_method "save_#{association_name}" do
            x = self.send(association_name)
            return if x.nil? or x.frozen?
            if x.should_destroy?
              x.destroy
              self.send("#{association_name}=", nil)
            else
              #RADAR requires back relationship (belongs_to) to be canonical
              x.send("#{self.class.base_class.name.underscore}=", self) if (to_name == 'has_one')
              x.save(false)
            end
          end

          # Through methods
          RAILS_DEFAULT_LOGGER.error("2.   through: #{through.inspect}")
          through.class_eval "def should_destroy?; should_destroy.to_i == 1; end"
          through.class_eval "def should_destroy; @should_destroy ||= 0; end" # always have a value to avoid holes in array params in forms
          through.class_eval "attr_writer :should_destroy"
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, ActiveRecord::Acts::VirtualAttributes