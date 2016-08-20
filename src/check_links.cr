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

  def process_page(url : String, parent_channel, source_url : String)
  end
end

include CheckLinks
process_page("https://docs.layer.com")
count = $cache._cache.reduce(0) { |count, (_, page)| page.exists? ? count + 1 : count }
error_count = $cache._cache.reduce(0) { |count, (_, page)| page.xml_parsing_error? ? count + 1 : count }
print "Found #{$cache.size} pages, #{count} exist, #{error_count} had HTML parsing error"

$cache._cache.each do |url, page|
  next unless page.exists? && page.loaded?
  target_pages = page.links.map { |link| $cache.page_for_url(resolved_uri(link, url)) }
  # not_founds = target_pages.select { |page| page.nil? ? false : page.not_found? }
  # errors = target_pages.select { |page| page.nil? ? false : page.xml_parsing_error? }
  not_founds = [] of CheckLinks::Page
  errors = [] of CheckLinks::Page
  target_pages.each do |page|
    next if page.nil?
    next unless page.loaded?
    not_founds << page if page.not_found?
    errors << page if page.xml_parsing_error?
  end

  next if not_founds.size == 0 && errors.size == 0
  print "\n#{url.colorize.mode(:bold)}\n"
  not_founds.uniq.each { |page| print "| #{page.url}\n" }
  errors.uniq.each { |page| print "| #{page.url} (parsing error)\n".colorize.fore(:red) }
end