require "http/client"

module CheckLinks
  struct Page
    getter :url, :source_url, :hashes

    def initialize(source_url : String)
      @source_url = URI.parse(source_url)
      @url = URI.parse(source_url)
      @loaded = false
    end

    def initialize(target_url : String, source_url : String)
      @source_url = URI.parse(source_url)
      @url = URI.parse(target_url)
      @loaded = false
      self.process_page
    end

    def open(target_url : String)
      @url = URI.parse(target_url)
      process_page(target_url)
    end

    def loaded?
      @loaded
    end

    def exists?
      @exists
    end

    private def process_page(url_string)
      response = HTTP::Client.get(url_string)
      # TODO: Handle redirects
      @exists = page_exists?(response)
      xml_doc = XML.parse_html(response.body)
      @hashes = available_hashes(xml_doc)
      @links = outbound_links(xml_doc)
      @loaded = true
    end

    private def page_exists?(response)
      response.status_code >= 200 && response.status_code < 300
    end

    def available_hashes(xml_doc)
      hash_xpath = "string(//@id)"
      # TODO: Will probably require more work
      xml_doc.xpath_string(hash_xpath)
    end

    def outbound_links(xml_doc)
      link_xpath = "string(//a[@href])"
      # TODO: Will probably require more work
      xml_doc.xpath_string(link_xpath)
    end
  end
end