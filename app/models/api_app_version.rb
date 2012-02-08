class ApiAppVersion
  def initialize(version_string)
    if version_string.nil?
      @part = []
    else
      @part = version_string.split('-')
    end
  end
  
  def appname
    @part[0]
  end
  
  def country
    @part[1]
  end
  
  def number
    @part[2]
  end
  
  def release_date
    @part[3]
  end
  
  def to_s
     @part.join('-')
  end
  alias to_str to_s
end
