require "./check_links/*"

$cache = PageCache.new

module CheckLinks
  def resolved_uri(url : String, source_url : String)
    URI.parse(source_url).resolve_to(URI.parse(url))
  end

  def create_and_cache_page(url : String, source_url : String)
    page = Page.new(url, source_url)
    $cache.add_page_for_url(page, resolved_uri(url, source_url))
    page
  end

  def process_page(url : String)
    process_page(url, url)
  end

  def process_page(url : String, source_url : String)
    # p "Processing page #{url}"
    page = $cache.page_for_url(resolved_uri(url, source_url))
    if page.nil?
      page = create_and_cache_page(url, source_url)
      page.links.each { |link| p "Found #{link} from #{source_url}"; process_page(link, url) }
    end
  end

  def process_page(url : String, parent_channel, source_url : String)
  end
end

include CheckLinks
# process_page("https://docs.layer.com")