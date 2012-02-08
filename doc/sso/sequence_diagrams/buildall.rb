#!/usr/bin/env ruby
unless `which epstopdf` == ""
  ps_convertor = "epstopdf --filter"
else
  puts "using pstopdf. For better results, sudo port install tetex"
  ps_convertor = "pstopdf -i"
end

Dir.glob("**/*.pic").each do |path|
  name = File.basename(path, '.pic')
  pdf = path.sub(/.pic$/, '.pdf')
  unless name == 'sequence'
    puts "converting #{path}..."
    cmd = "pic2plot -FHelvetica-Narrow -Tps #{path} | #{ps_convertor} > #{pdf}"
    puts cmd
    `#{cmd}`
  end
end