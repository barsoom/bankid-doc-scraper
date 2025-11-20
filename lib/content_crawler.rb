# lib/content_crawler.rb
require 'uri'
require 'set'

class ContentCrawler
  def initialize(base_url, max_pages: nil)
    @base_url = base_url
    @base_uri = URI.parse(base_url)
    @max_pages = max_pages
    @queue = []
    @visited = Set.new
  end

  def add_url(url)
    # Check if external
    uri = URI.parse(url)
    return false unless uri.host == @base_uri.host

    # Check if already visited or queued
    return false if @visited.include?(url)
    return false if @queue.include?(url)

    # Check max pages limit
    return false if @max_pages && (@visited.size + @queue.size) >= @max_pages

    @queue << url
    true
  rescue URI::InvalidURIError
    false
  end

  def next_url
    @queue.shift
  end

  def mark_visited(url)
    @visited.add(url)
    @queue.delete(url)
  end

  def stats
    {
      visited: @visited.size,
      queued: @queue.size,
      total: @visited.size + @queue.size
    }
  end

  def empty?
    @queue.empty?
  end
end
