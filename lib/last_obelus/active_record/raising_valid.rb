module LastObelus::ActiveRecord::RaisingValid
  def validate!
    raise ActiveRecord::RecordInvalid.new(self) unless self.valid?
  end
end
ActiveRecord::Base.send(:include, LastObelus::ActiveRecord::RaisingValid)