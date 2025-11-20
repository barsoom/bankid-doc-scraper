#!/usr/bin/env ruby
# bankid_scraper.rb

require 'optparse'
require 'nokogiri'
require_relative 'lib/browser_controller'
require_relative 'lib/content_crawler'
require_relative 'lib/content_extractor'
require_relative 'lib/markdown_converter'
require_relative 'lib/file_organizer'

class BankIDScraper
  DEFAULT_BASE_URL = 'https://developers.bankid.com/'
  DEFAULT_OUTPUT_DIR = './bankid_docs'

  def initialize(options = {})
    @base_url = options[:base_url] || DEFAULT_BASE_URL
    @output_dir = options[:output_dir] || DEFAULT_OUTPUT_DIR
    @headless = options.fetch(:headless, true)
    @max_pages = options[:max_pages]

    @browser = BrowserController.new(headless: @headless)
    @crawler = ContentCrawler.new(@base_url, max_pages: @max_pages)
    @extractor = ContentExtractor.new
    @converter = MarkdownConverter.new
    @organizer = FileOrganizer.new(@output_dir)

    @success_count = 0
    @failure_count = 0
    @start_time = Time.now
  end

  def run
    puts "Starting BankID documentation scraper..."
    puts "Base URL: #{@base_url}"
    puts "Output: #{@output_dir}"
    puts "Mode: #{@headless ? 'headless' : 'headed'}"
    puts "Max pages: #{@max_pages || 'unlimited'}"
    puts

    # Start with base URL
    @crawler.add_url(@base_url)

    # Process queue
    while (url = @crawler.next_url)
      process_page(url)
    end

    # Generate index
    @organizer.generate_index

    # Print summary
    print_summary
  ensure
    @browser&.cleanup
  end

  private

  def process_page(url)
    stats = @crawler.stats
    puts "[#{stats[:visited] + 1}/#{stats[:total]}] Processing: #{url}"

    max_retries = 3
    retry_count = 0

    begin
      # Navigate and wait for content
      @browser.navigate_and_wait(url)

      # Get page HTML
      html = @browser.page.content

      # Parse with Nokogiri
      doc = Nokogiri::HTML(html)

      # Extract content
      content_html = @extractor.extract_content(doc)

      # Validate content
      unless @extractor.validate_content(content_html)
        puts "  ⚠️  Warning: Content validation failed, saving anyway"
      end

      # Convert to markdown
      markdown = @converter.convert(content_html, url, Time.now)

      # Save to file
      @organizer.save_page(url, markdown)

      # Extract new links
      links = @extractor.extract_links(doc, @base_url)
      new_links = 0
      links.each do |link|
        new_links += 1 if @crawler.add_url(link)
      end

      puts "  ✓ Saved (found #{new_links} new links)"
      @success_count += 1
      @crawler.mark_visited(url)

    rescue Playwright::TimeoutError, Playwright::Error => e
      retry_count += 1
      if retry_count <= max_retries
        wait_time = 2 ** (retry_count - 1)
        puts "  ⚠️  Retry #{retry_count}/#{max_retries} after #{wait_time}s..."
        sleep wait_time
        retry
      else
        puts "  ✗ Failed after #{max_retries} retries: #{e.message}"
        @organizer.save_failed_url(url, "#{e.class}: #{e.message}")
        @failure_count += 1
        @crawler.mark_visited(url)
      end
    rescue StandardError => e
      puts "  ✗ Error: #{e.message}"
      @organizer.save_failed_url(url, e.message)
      @failure_count += 1
      @crawler.mark_visited(url)
    end
  end

  def print_summary
    duration = Time.now - @start_time
    minutes = (duration / 60).to_i
    seconds = (duration % 60).to_i

    puts
    puts "=" * 60
    puts "Download Complete!"
    puts "=" * 60
    puts "Total pages: #{@success_count + @failure_count}"
    puts "Successful: #{@success_count}"
    puts "Failed: #{@failure_count}"
    if @failure_count > 0
      puts "  (see #{File.join(@output_dir, 'failed_urls.txt')})"
    end
    puts "Duration: #{minutes}m #{seconds}s"
    puts "Output: #{@output_dir}"
    puts "=" * 60
  end
end

# CLI
if __FILE__ == $0
  options = {}

  OptionParser.new do |opts|
    opts.banner = "Usage: ruby bankid_scraper.rb [options]"

    opts.on("--[no-]headless", "Run browser in headless mode (default: true)") do |v|
      options[:headless] = v
    end

    opts.on("--output-dir DIR", "Output directory (default: ./bankid_docs)") do |v|
      options[:output_dir] = v
    end

    opts.on("--base-url URL", "Starting URL (default: https://developers.bankid.com/)") do |v|
      options[:base_url] = v
    end

    opts.on("--max-pages N", Integer, "Maximum pages to download") do |v|
      options[:max_pages] = v
    end

    opts.on("-h", "--help", "Show this help") do
      puts opts
      exit
    end
  end.parse!

  scraper = BankIDScraper.new(options)
  scraper.run
end
