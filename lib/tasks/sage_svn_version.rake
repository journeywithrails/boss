namespace :sage do
  # not used in production because the deployed directory has no SVN info;
  # there it is done with a Rightscript ("SAGE-BB rails svn code update & db config v2" r5).
  desc "Writes latest svn update number to config/svn_version for use as asset tag id"
  task(:svn_version => :environment) do
    lines = `svn info \`svn info | grep "URL" | sed 's/^.* //'\`| grep "Revision:" | sed 's/^.* //'`
    if lines =~ /(\d+)/
      f = File.open("config/svn_version", "w")
      f.write($1)
      f.close
    end
  end
end
