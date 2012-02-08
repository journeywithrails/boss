if RUBY_VERSION < '1.9' then
  def Time.today
    file, lineno = Gem.location_of_caller
    t = Time.now
    t - ((t.to_f + t.gmt_offset) % 86400)
  end
end
