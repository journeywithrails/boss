module LastObelus::ActiveRecord::ValidForAttributes
  def valid_for_attributes?( *attributes )
    attributes.flatten!
    attributes = attributes.collect(&:to_sym)
    unless self.valid?
      our_errors = Array.new
      self.errors.each do |attr,error|
        our_errors << [attr,error] if attributes.include?(attr.to_sym)
      end
      self.errors.clear
      our_errors.each { |attr,error| self.errors.add(attr,error) }
    end
    return self.errors.empty?
  end
end

ActiveRecord::Base.send(:include, LastObelus::ActiveRecord::ValidForAttributes)