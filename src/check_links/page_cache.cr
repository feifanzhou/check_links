module CheckLinks
  class PageCache
    def initialize
      @cache = {} of String => Page
    end

    def add_page_for_url(page : Page, url : String)
      @cache[full_url_without_hash(url)] = page
    end

    def page_for_url(url : String)
      @cache[full_url_without_hash(url)]?
    end

    private def full_url_without_hash(url : String)
      uri = URI.parse(url)
      host = uri.host
      path = uri.full_path
      if host.nil? 
        raise ArgumentError.new("Cannot parse host from URL #{url}")
      elsif path.nil?
        raise ArgumentError.new("Cannot parse full path from URL #{url}")
      else
        return host + path
      end
    end
  end
end