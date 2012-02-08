class SocialSecurityNumber < ActiveRecord::BaseWithoutTable
  Fields = [:number]

  Fields.each do |name|
    column name
  end

  validates_presence_of(*Fields)
end

