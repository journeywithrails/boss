class BirthDate < ActiveRecord::BaseWithoutTable
  Fields = [:birth_date]

  Fields.each do |name|
    column name
  end

  validates_presence_of(*Fields)
  validate :valid_age

  def birth_date=(date)
    self['birth_date'] = 
      case date
      when String
        Time.parse(date)
      when Date
        date.to_time
      when Time
        date
      when DateTime
        date.to_time
      end
  end

  def valid_age
    if birth_date
      if birth_date > 18.years.ago
        errors.add('birth_date', 'is too young')
      elsif birth_date < 100.years.ago
        errors.add('birth_date', 'is not valid')
      end
    end
  end
end
