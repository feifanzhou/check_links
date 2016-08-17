require "./spec_helper"
require "../src/check_links/page"

module CheckLinks 

  NONEXISTENT_URL = "/404"
  NO_LINKS_OR_HASHES_PATH = "spec/example_html/no_links_or_hashes.html"
  LINK_PATH = "spec/example_html/links.html"
  HASH_PATH = "spec/example_html/hashes.html"
  LINKS_AND_HASHES_PATH = "spec/example_html/links_and_hashes.html"

  describe Page do
    it "is not loaded if only initialized with only a source URL" do
      Page.new("source.com").loaded?.should be_false
    end

    it "is loaded if initialized with a URL" do
      target_url = "http://localhost:9999/#{NO_LINKS_OR_HASHES_PATH}"
      Page.new(target_url, "http://localhost").loaded?.should be_true
    end

    it "exists if status code is 2xx" do
      target_url = "http://localhost:9999/#{NO_LINKS_OR_HASHES_PATH}"
      Page.new(target_url, "http://localhost").exists?.should be_true
    end

    it "does not exist if status code isn't 2xx" do
      target_url = "http://localhost:9999/404"
      Page.new(target_url, "http://localhost").exists?.should be_false
    end

    it "extracts links from every anchor" do
      target_url = "http://localhost:9999/#{LINK_PATH}"
      page = Page.new(target_url, "http://localhost")
      page.links.size.should eq(3)
    end

    it "extracts correct, absolute links" do
      target_url = "http://localhost:9999/#{LINK_PATH}"
      links = Page.new(target_url, "http://localhost/page").links
      links.includes?("http://localhost/1").should be_true
      links.includes?("http://localhost/page/2").should be_true
      links.includes?("http://localhost/3").should be_true
      links.includes?("http://localhost/4").should be_false
    end

    it "extracts hashes from every id attribute" do
      target_url = "http://localhost:9999/#{HASH_PATH}"
      page = Page.new(target_url, "http://localhost")
      page.hashes.size.should eq(3)
    end

    it "extracts the correct hashes" do
      target_url = "http://localhost:9999/#{HASH_PATH}"
      hashes = Page.new(target_url, "http://localhost").hashes
      hashes.includes?("id1").should be_true
      hashes.includes?("id_2").should be_true
      hashes.includes?("id-3").should be_true
      hashes.includes?("id|4").should be_false
    end

    it "extracts the correct links and hashes from a mixed page" do
      target_url = "http://localhost:9999/#{LINKS_AND_HASHES_PATH}"
      page = Page.new(target_url, "http://localhost")
      links = page.links
      hashes = page.hashes
      links.size.should eq(3)
      hashes.size.should eq(3)
      links.includes?("http://localhost/2").should be_true
      links.includes?("/nope").should be_false
      hashes.includes?("id-3").should be_true
      hashes.includes?("nonexistent").should be_false
    end

    it "does not find links on pages not part of the source domain" do
      target_url = "http://localhost:9999/#{LINKS_AND_HASHES_PATH}"
      page = Page.new(target_url, "http://example.com")
      page.links.size.should eq(0)
    end

    it "finds hashes on pages not part of the source domain" do
      target_url = "http://localhost:9999/#{LINKS_AND_HASHES_PATH}"
      page = Page.new(target_url, "http://example.com")
      page.hashes.size.should eq(3)
    end
  end
end