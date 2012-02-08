class DriversLicense < ActiveRecord::BaseWithoutTable
  Fields = [:state, :number]

  Fields.each do |name|
    column name
  end

  validates_presence_of(*Fields)
end


