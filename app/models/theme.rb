require 'yaml'
class Theme
  attr_accessor :name
  attr_accessor :description
  attr_accessor :style_path
  attr_accessor :calendar_path
  attr_accessor :ext_path

  def self.load_theme(theme_name)
    if self.valid?(theme_name)
      theme_data = get_theme_data
      theme = Theme.new
      theme.description = theme_data[theme_name]["description"]
      theme.style_path = theme_data[theme_name]["style_path"]
      theme.calendar_path = theme_data[theme_name]["calendar_path"]
      theme.ext_path = theme_data[theme_name]["ext_path"]
      return theme
    else
      return nil
    end
  end
  
  def self.valid?(theme_name)
   theme_data = get_theme_data
   if !theme_name.blank? and !theme_data[theme_name].nil?
     return true
   else
     return false
   end   
 end
 
 def self.theme_list
   theme_data = Theme.get_theme_data
   theme_list = []
   theme_data.each_pair{|name, value| theme_list << name}
   return theme_list
 end
 
 private
 def self.get_theme_data
   theme_data = YAML.load_file("#{RAILS_ROOT}/config/themes.yml")
   return theme_data
 end
end