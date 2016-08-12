require "./spec_helper"
require "../src/check_links/page_cache"

module CheckLinks
  describe PageCache do
    it "can be created without any parameters" do
      PageCache.new.should be_truthy
    end

    it "associates a page with a URL" do
      url = "https://test.com/page"
      page = Page.new("https://source.com")
      cache = PageCache.new
      cache.add_page_for_url(page, url).should be_truthy
    end

    it "returns a Page object for a cached URL" do
      url = "https://test.com/page"
      page = Page.new("https://source.com")
      cache = PageCache.new
      cache.add_page_for_url(page, url)
      cache.page_for_url(url).should eq(page)
    end

    it "returns Nil for an uncached URL" do
      PageCache.new.page_for_url("https://test.com/page").should be_nil
    end

    it "ignores hashes in URLs" do
      page = Page.new("https://source.com")
      cache = PageCache.new
      cache.add_page_for_url(page, "https://test.com/page#hash")
      cache.page_for_url("https://test.com/page#otherhash").should eq(page)
      cache.page_for_url("https://test.com/page").should eq(page)
    end

    it "raises an ArgumentError if trying to cache unparseable URL" do
      page = Page.new("https://source.com")
      cache = PageCache.new
      expect_raises(ArgumentError) do
        cache.add_page_for_url(page, "")
      end
    end
  end
end