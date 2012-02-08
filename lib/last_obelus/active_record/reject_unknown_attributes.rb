module LastObelus::ActiveRecord::RejectUnknownAttributes
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  def reject_unknown_attributes(params)
    attrs = attribute_names
    params.select do |k,v|
      attrs.include?(k.to_s) || self.respond_to?("#{ k.to_s }=")
    end.inject({}) do |h, (k, v)|
      h[k] = v
      h
    end
  end
  
  module ClassMethods
    def build_rejecting_unknown_attributes(params)
      record = self.new
      good_params = record.reject_unknown_attributes(params)
      record.attributes = good_params
      record
    end
  end
end

ActiveRecord::Base.send(:include, LastObelus::ActiveRecord::RejectUnknownAttributes)
