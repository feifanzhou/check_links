module CheckLinks
  class PageCache
    def initialize
      @cache = {} of String => Page
    end

    def add_page_for_url(page : Page, url : String)
      @cache[full_url_without_hash(url)] = page
    end
    def add_page_for_url(page : Page, uri : URI)
      @cache[full_url_without_hash(uri)] = page
    end

    def page_for_url(url : String)
      @cache[full_url_without_hash(url)]?
    end
    def page_for_url(uri : URI)
      @cache[full_url_without_hash(uri)]?
    end

    def size
      @cache.size
    end

    def _cache
      @cache
    end

    private def full_url_without_hash(url : String)
      full_url_without_hash(URI.parse(url))
    end

    private def full_url_without_hash(uri : URI)
      scheme = uri.scheme
      host = uri.host
      port = uri.port
      path = uri.full_path
      if host.nil?
        raise ArgumentError.new("Cannot parse host from URL #{uri}")
      elsif path.nil?
        raise ArgumentError.new("Cannot parse full path from URL #{uri}")
      else
        return (scheme ? "#{scheme}://" : "") + host + (port ? ":#{port}" : "") + path
      end
    end
  end
end