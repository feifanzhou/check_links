require "colorize"
require "./check_links/*"

$cache = PageCache.new

module CheckLinks
  def resolved_uri(url : String, source_url : String)
    URI.parse(source_url).resolve_to(URI.parse(url))
  end
  def resolved_uri(url : String, source_url : URI)
    source_url.resolve_to(URI.parse(url))
  end

  def process_page(url : String)
    process_page(url, url)
  end

  def process_page(url : String, source_url : String)
    cache_key = resolved_uri(url, source_url)
    page = $cache.page_for_url(cache_key)
    if page.nil?
      page = Page.new(source_url)
      $cache.add_page_for_url(page, cache_key)
      page.open(url)
      page.links.each { |link| process_page(link, url) }
    end
  end

  def process_page(url : String, limit : UInt8)
    process_page(url, url, limit)
  end
  def process_page(url : String, source_url : String, limit : UInt8)
    # p "Processing #{url}"
    cache_key = resolved_uri(url, source_url)
    page = $cache.page_for_url(cache_key)
    if page.nil?
      page = Page.new(source_url)
      $cache.add_page_for_url(page, cache_key)
      page.open(url)
      p "Links for #{url}: #{page.links}"
      p "Raw links for #{url}: #{page.raw_links}"
      page.links.each { |link| process_page(link, url, limit - 1) } if limit > 0
    end
  end
end

include CheckLinks
process_page("http://localhost:3000/")
count = $cache._cache.reduce(0) { |count, (_, page)| page.exists? ? count + 1 : count }
error_count = $cache._cache.reduce(0) { |count, (_, page)| page.xml_parsing_error? ? count + 1 : count }
print "Found #{$cache.size} pages, #{count} exist, #{error_count} had HTML parsing error"

$cache._cache.each do |url, page|
  next unless page.exists? && page.loaded?
  target_pages = page.links.map do |link|
    uri = resolved_uri(link, url)
    { uri, $cache.page_for_url(uri) }
  end
  # not_founds = target_pages.select { |page| page.nil? ? false : page.not_found? }
  # errors = target_pages.select { |page| page.nil? ? false : page.xml_parsing_error? }
  not_founds = [] of String
  not_found_hashes = [] of String
  errors = [] of String
  target_pages.each do |uri, page|
    next if page.nil?
    next unless page.loaded?
    not_founds << page.url.to_s if page.not_found?
    not_found_hashes << uri.to_s if uri.fragment && !page.hashes.includes?(uri.fragment)
    errors << page.url.to_s if page.xml_parsing_error?
  end
  uniq_not_founds = not_founds.uniq
  uniq_not_found_hashes = not_found_hashes.uniq - uniq_not_founds
  uniq_errors = errors.uniq

  next if not_founds.size == 0 && errors.size == 0
  print "\n#{url.colorize.mode(:bold)}\n"
  uniq_not_founds.each { |page_url| print "| #{page_url}\n" }
  uniq_not_found_hashes.each { |uri| print "| #{uri.colorize.fore(:yellow)}\n" }
  uniq_errors.each { |page_url| print "| #{page_url} (parsing error)\n".colorize.fore(:red) }
end