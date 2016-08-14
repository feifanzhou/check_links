require "http/client"

module CheckLinks
  struct Page
    getter :url, :source_url, :hashes, :links

    def initialize(source_url : String)
      @source_url = URI.parse(source_url)
      @url = URI.parse(source_url)
      @loaded = false
      @exists = false
      @hashes = [] of String
      @links = [] of String
    end

    def initialize(target_url : String, source_url : String)
      initialize(source_url)
      process_page(target_url)
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

    private def available_hashes(xml_doc)
      attribute_values(xml_doc, "//@id")
    end

    private def outbound_links(xml_doc)
      attribute_values(xml_doc, "//@href")
    end

    private def attribute_values(xml_doc, xpath)
      xml_doc.xpath_nodes(xpath).map{ |n| n.text || ""}.select{ |h| h.size > 0}
    end
  end
end