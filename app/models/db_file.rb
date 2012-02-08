class DbFile < ActiveRecord::Base

  def data_as_string
    if data.respond_to?(:rewind) 
       data.rewind 
       data.read 
    else 
      data 
    end
  end
end