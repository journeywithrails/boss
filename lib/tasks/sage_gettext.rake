require 'gettext/utils'

namespace :sage do
  desc "i8n Update pot/po files."
  task :updatepo do
    GetText.update_pofiles("billingboss", Dir.glob("{{app,lib}/**/*.{rb,erb,rjs},vendor/plugins/state_select/lib/state_select.rb}"), "billingboss 2.0", "po/templates")
  end

  desc "Create mo-files for L10n" 
  task :makemo do
    GetText.create_mofiles(true, "po", "locale")
  end
end
