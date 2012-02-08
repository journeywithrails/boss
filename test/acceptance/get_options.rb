require 'getoptlong'

$tu_level = Test::Unit::UI::NORMAL

opts = GetoptLong.new(
  ['--verbose', '-v', GetoptLong::NO_ARGUMENT]
)
opts.each { |opt, arg|
  case opt
  when '--verbose'
    $tu_level = Test::Unit::UI::VERBOSE
  end
}