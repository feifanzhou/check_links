require "http/client"
require "xml"

class URI
  def absolute_with_host?
    !self.host.nil?
  end

  def absolute?
    self.full_path.char_at(0) == '/'
  end

  def relative?
    !absolute?
  end

  def at_root?
    self.full_path == "/"
  end

  def resolve_to(target_url)
    clone = self.dup
    if target_url.absolute_with_host?
      return target_url
    elsif clone.at_root? && target_url.relative?
      clone.path = "/#{target_url.full_path}"
    elsif target_url.absolute?
      clone_host = clone.host || ""
      clone.path = target_url.to_s
    elsif target_url.relative?
      appendable_target = clone.full_path.char_at(-1) == '/' ? target_url.to_s : "/#{target_url}"
      clone.path = "#{clone.full_path}#{appendable_target}"
    else
      raise Exception.new("Unknown condition resolving #{clone.to_s} to #{target_url.to_s}")
    end
    clone
  end
end

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
      @url = URI.parse(target_url)
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
      if @url.host == @source_url.host
        @links = outbound_links(xml_doc)
      else
        @links = [] of String
      end
      @loaded = true
    end

    private def page_exists?(response)
      response.status_code >= 200 && response.status_code < 300
    end

    private def available_hashes(xml_doc)
      attribute_values(xml_doc, "//@id")
    end

    private def outbound_links(xml_doc)
      raw_links = attribute_values(xml_doc, "//@href")
      raw_links.map { |link| @source_url.resolve_to(URI.parse(link)).to_s }
    end

    private def attribute_values(xml_doc, xpath)
      xml_doc.xpath_nodes(xpath).map{ |n| n.text || ""}.select{ |h| h.size > 0}
    end
  end
end