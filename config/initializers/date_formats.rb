# Custom date formats for the application.
# Now any_date can be formatted by:
#   any_date.to_s(:MMDDYYYY)
# See Date::strftime() for an description of the string.
my_formats = {
  :MMDDYYYY => "%m-%d-%Y",
  :YYYYMMDD => "%Y-%m-%d",
  :DDMMYYYY => "%d-%m-%Y",
  :history => '%I:%M %P | %A %B %d, %Y',
  :comment  => '%I:%M %P | %d.%m.%Y',
  :listing =>  '%I:%M %p | %d.%m.%Y'
}

ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(my_formats)
