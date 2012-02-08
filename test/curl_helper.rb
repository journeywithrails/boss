class Test::Unit::TestCase
  
  def curl(curl_cmd, http_verb, url)
    `#{curl_cmd} -s -X #{http_verb} #{url}`
  end
  
  def curl_add(curl_cmd, xml, url)
    `#{curl_cmd} -s -H "Content-Type: application/xml; charset=utf-8" --data-ascii "#{xml}" "#{url}"`
  end
  
end