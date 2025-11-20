# BankID Documentation Scraper Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Ruby script that downloads complete BankID developer documentation using Playwright browser automation and outputs organized markdown files.

**Architecture:** Five core classes (BrowserController, ContentCrawler, ContentExtractor, MarkdownConverter, FileOrganizer) orchestrated by a main CLI script. Uses Playwright for JavaScript rendering, reverse_markdown for HTML-to-markdown conversion, and breadth-first crawling to discover all pages.

**Tech Stack:** Ruby 3.3, playwright-ruby-client, reverse_markdown, nokogiri, optparse (CLI)

---

## Task 1: Project Setup

**Files:**
- Create: `Gemfile`
- Create: `.ruby-version`
- Create: `README.md`
- Create: `.gitignore` (worktree-specific)

**Step 1: Create Gemfile**

```ruby
# Gemfile
source 'https://rubygems.org'

ruby '~> 3.3'

gem 'playwright-ruby-client', '~> 1.44'
gem 'reverse_markdown', '~> 2.1'
gem 'nokogiri', '~> 1.15'

group :development, :test do
  gem 'rspec', '~> 3.12'
  gem 'pry', '~> 0.14'
end
```

**Step 2: Create .ruby-version**

```
3.3.0
```

**Step 3: Create README.md**

```markdown
# BankID Documentation Scraper

Downloads complete BankID developer documentation from https://developers.bankid.com/

## Prerequisites

- Ruby 3.3+
- Node.js (for Playwright)

## Setup

```bash
bundle install --path vendor/bundle
npx playwright install chromium
```

## Usage

```bash
ruby bankid_scraper.rb
```

## Options

- `--headless` / `--headed` - Show browser (default: headless)
- `--output-dir PATH` - Output directory (default: ./bankid_docs)
- `--base-url URL` - Starting URL (default: https://developers.bankid.com/)
- `--max-pages N` - Limit pages for testing (default: unlimited)
```

**Step 4: Create .gitignore**

```
vendor/
.bundle/
```

**Step 5: Install dependencies**

Run: `bundle install --path vendor/bundle`
Expected: Gems installed to vendor/bundle successfully

**Step 6: Install Playwright browsers**

Run: `npx playwright install chromium`
Expected: Chromium downloaded

**Step 7: Commit**

```bash
git add Gemfile Gemfile.lock .ruby-version README.md .gitignore
git commit -m "Initial project setup with dependencies"
```

---

## Task 2: BrowserController Class with Tests

**Files:**
- Create: `spec/spec_helper.rb`
- Create: `spec/browser_controller_spec.rb`
- Create: `lib/browser_controller.rb`

**Step 1: Create RSpec configuration**

```ruby
# spec/spec_helper.rb
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.warnings = true
  config.default_formatter = "doc" if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed
end
```

**Step 2: Write failing test for BrowserController initialization**

```ruby
# spec/browser_controller_spec.rb
require_relative '../lib/browser_controller'

RSpec.describe BrowserController do
  describe '#initialize' do
    it 'creates a browser controller with headless mode by default' do
      controller = BrowserController.new
      expect(controller).to be_a(BrowserController)
    end

    it 'accepts headless option' do
      controller = BrowserController.new(headless: false)
      expect(controller).to be_a(BrowserController)
    end
  end

  describe '#navigate_and_wait' do
    let(:controller) { BrowserController.new(headless: true) }

    after { controller.cleanup }

    it 'navigates to URL and waits for content' do
      # Use a simple static page for testing
      expect { controller.navigate_and_wait('https://example.com') }.not_to raise_error
    end
  end

  describe '#cleanup' do
    it 'closes browser and stops playwright' do
      controller = BrowserController.new
      expect { controller.cleanup }.not_to raise_error
    end
  end
end
```

**Step 3: Run test to verify it fails**

Run: `bundle exec rspec spec/browser_controller_spec.rb`
Expected: FAIL with "cannot load such file -- browser_controller"

**Step 4: Write minimal implementation**

```ruby
# lib/browser_controller.rb
require 'playwright'

class BrowserController
  attr_reader :page

  def initialize(headless: true)
    @playwright = Playwright.create(playwright_cli_executable_path: 'npx playwright')
    @browser = @playwright.chromium.launch(headless: headless)
    @context = @browser.new_context
    @page = @context.new_page
  end

  def navigate_and_wait(url, selector: 'main, article, .content, body')
    @page.goto(url, wait_until: 'domcontentloaded')
    @page.wait_for_selector(selector, state: 'visible', timeout: 10_000)
  rescue Playwright::TimeoutError => e
    # Fallback to body if specific selectors not found
    @page.wait_for_selector('body', state: 'visible', timeout: 5_000)
  end

  def cleanup
    @browser&.close
    @playwright&.stop
  end
end
```

**Step 5: Run test to verify it passes**

Run: `bundle exec rspec spec/browser_controller_spec.rb`
Expected: PASS (3 examples, 0 failures)

**Step 6: Commit**

```bash
git add spec/spec_helper.rb spec/browser_controller_spec.rb lib/browser_controller.rb
git commit -m "Add BrowserController with Playwright integration"
```

---

## Task 3: ContentExtractor Class with Tests

**Files:**
- Create: `spec/content_extractor_spec.rb`
- Create: `lib/content_extractor.rb`

**Step 1: Write failing test for ContentExtractor**

```ruby
# spec/content_extractor_spec.rb
require_relative '../lib/content_extractor'
require 'nokogiri'

RSpec.describe ContentExtractor do
  let(:extractor) { ContentExtractor.new }

  describe '#extract_content' do
    it 'extracts content from main tag' do
      html = '<html><body><nav>Skip</nav><main><h1>Title</h1><p>Content</p></main></body></html>'
      doc = Nokogiri::HTML(html)

      result = extractor.extract_content(doc)

      expect(result).to include('<h1>Title</h1>')
      expect(result).to include('<p>Content</p>')
      expect(result).not_to include('<nav>')
    end

    it 'extracts content from article tag' do
      html = '<html><body><header>Skip</header><article><h2>Article</h2></article></body></html>'
      doc = Nokogiri::HTML(html)

      result = extractor.extract_content(doc)

      expect(result).to include('<h2>Article</h2>')
      expect(result).not_to include('<header>')
    end

    it 'strips navigation elements' do
      html = '<html><body><main><nav>Nav</nav><p>Keep this</p><footer>Footer</footer></main></body></html>'
      doc = Nokogiri::HTML(html)

      result = extractor.extract_content(doc)

      expect(result).to include('<p>Keep this</p>')
      expect(result).not_to include('Nav')
      expect(result).not_to include('Footer')
    end
  end

  describe '#extract_links' do
    it 'extracts all links from page' do
      html = '<html><body><a href="/docs/api">API</a><a href="/docs/guide">Guide</a></body></html>'
      doc = Nokogiri::HTML(html)

      links = extractor.extract_links(doc, 'https://developers.bankid.com')

      expect(links).to include('https://developers.bankid.com/docs/api')
      expect(links).to include('https://developers.bankid.com/docs/guide')
    end

    it 'filters out external links' do
      html = '<html><body><a href="/internal">Internal</a><a href="https://google.com">External</a></body></html>'
      doc = Nokogiri::HTML(html)

      links = extractor.extract_links(doc, 'https://developers.bankid.com')

      expect(links).to include('https://developers.bankid.com/internal')
      expect(links).not_to include('https://google.com')
    end

    it 'filters out asset files' do
      html = '<html><body><a href="/doc.pdf">PDF</a><a href="/style.css">CSS</a><a href="/page">Page</a></body></html>'
      doc = Nokogiri::HTML(html)

      links = extractor.extract_links(doc, 'https://developers.bankid.com')

      expect(links).to include('https://developers.bankid.com/page')
      expect(links).not_to include(a_string_matching(/\.pdf/))
      expect(links).not_to include(a_string_matching(/\.css/))
    end
  end

  describe '#validate_content' do
    it 'returns true for valid content' do
      content = '<h1>Title</h1><p>' + 'x' * 150 + '</p>'
      expect(extractor.validate_content(content)).to be true
    end

    it 'returns false for content too short' do
      content = '<p>Short</p>'
      expect(extractor.validate_content(content)).to be false
    end

    it 'returns false for content without headings' do
      content = '<p>' + 'x' * 150 + '</p>'
      expect(extractor.validate_content(content)).to be false
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/content_extractor_spec.rb`
Expected: FAIL with "cannot load such file -- content_extractor"

**Step 3: Write minimal implementation**

```ruby
# lib/content_extractor.rb
require 'nokogiri'
require 'uri'

class ContentExtractor
  CONTENT_SELECTORS = [
    'article',
    'main',
    '[role="main"]',
    '.documentation-content',
    '.doc-content',
    '.markdown-body',
    '#content'
  ].freeze

  STRIP_SELECTORS = [
    'nav',
    'header',
    'footer',
    '.sidebar',
    '.navigation',
    'button',
    '.cookie-banner'
  ].freeze

  ASSET_EXTENSIONS = %w[.png .jpg .jpeg .gif .svg .pdf .css .js .woff .woff2 .ttf].freeze

  def extract_content(doc)
    # Try each selector until we find content
    content_node = nil
    CONTENT_SELECTORS.each do |selector|
      content_node = doc.at_css(selector)
      break if content_node
    end

    return '' unless content_node

    # Clone to avoid modifying original
    content_node = content_node.dup

    # Strip unwanted elements
    STRIP_SELECTORS.each do |selector|
      content_node.css(selector).remove
    end

    content_node.to_html
  end

  def extract_links(doc, base_url)
    base_uri = URI.parse(base_url)
    links = []

    doc.css('a[href]').each do |link|
      href = link['href']
      next if href.nil? || href.empty? || href.start_with?('#')

      # Convert to absolute URL
      begin
        url = URI.join(base_url, href).to_s
        url_uri = URI.parse(url)

        # Only same domain
        next unless url_uri.host == base_uri.host

        # Skip assets
        next if ASSET_EXTENSIONS.any? { |ext| url.downcase.end_with?(ext) }

        # Remove fragment
        url_uri.fragment = nil
        links << url_uri.to_s
      rescue URI::InvalidURIError
        # Skip invalid URLs
        next
      end
    end

    links.uniq
  end

  def validate_content(html)
    # Minimum length check
    return false if html.length < 100

    # Must have headings
    doc = Nokogiri::HTML(html)
    headings = doc.css('h1, h2, h3')
    headings.any?
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/content_extractor_spec.rb`
Expected: PASS (all examples)

**Step 5: Commit**

```bash
git add spec/content_extractor_spec.rb lib/content_extractor.rb
git commit -m "Add ContentExtractor with link discovery and validation"
```

---

## Task 4: MarkdownConverter Class with Tests

**Files:**
- Create: `spec/markdown_converter_spec.rb`
- Create: `lib/markdown_converter.rb`

**Step 1: Write failing test for MarkdownConverter**

```ruby
# spec/markdown_converter_spec.rb
require_relative '../lib/markdown_converter'

RSpec.describe MarkdownConverter do
  let(:converter) { MarkdownConverter.new }

  describe '#convert' do
    it 'converts HTML to markdown' do
      html = '<h1>Title</h1><p>Paragraph</p>'

      result = converter.convert(html, 'https://example.com', Time.now)

      expect(result).to include('# Title')
      expect(result).to include('Paragraph')
    end

    it 'preserves code blocks' do
      html = '<pre><code class="language-ruby">puts "hello"</code></pre>'

      result = converter.convert(html, 'https://example.com', Time.now)

      expect(result).to include('```')
      expect(result).to include('puts "hello"')
    end

    it 'converts tables to markdown' do
      html = '<table><tr><th>Header</th></tr><tr><td>Cell</td></tr></table>'

      result = converter.convert(html, 'https://example.com', Time.now)

      expect(result).to include('Header')
      expect(result).to include('Cell')
    end

    it 'adds metadata header' do
      html = '<p>Content</p>'
      url = 'https://developers.bankid.com/api/auth'
      timestamp = Time.new(2025, 11, 20, 14, 30, 0, '+00:00')

      result = converter.convert(html, url, timestamp)

      expect(result).to include('---')
      expect(result).to include('source: https://developers.bankid.com/api/auth')
      expect(result).to include('downloaded: 2025-11-20 14:30:00 UTC')
    end

    it 'makes relative links absolute' do
      html = '<a href="/docs/api">API Docs</a>'

      result = converter.convert(html, 'https://developers.bankid.com/guide', Time.now)

      expect(result).to include('https://developers.bankid.com/docs/api')
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/markdown_converter_spec.rb`
Expected: FAIL with "cannot load such file -- markdown_converter"

**Step 3: Write minimal implementation**

```ruby
# lib/markdown_converter.rb
require 'reverse_markdown'
require 'uri'

class MarkdownConverter
  def convert(html, source_url, timestamp)
    # Make links absolute
    html = make_links_absolute(html, source_url)

    # Convert to markdown
    markdown = ReverseMarkdown.convert(html, unknown_tags: :bypass, github_flavored: true)

    # Clean up excessive whitespace
    markdown = markdown.gsub(/\n{3,}/, "\n\n").strip

    # Add metadata header
    add_metadata_header(markdown, source_url, timestamp)
  end

  private

  def make_links_absolute(html, base_url)
    doc = Nokogiri::HTML(html)

    doc.css('a[href]').each do |link|
      href = link['href']
      next if href.nil? || href.start_with?('http://', 'https://', '#', 'mailto:')

      begin
        absolute_url = URI.join(base_url, href).to_s
        link['href'] = absolute_url
      rescue URI::InvalidURIError
        # Keep original if can't parse
      end
    end

    doc.to_html
  end

  def add_metadata_header(markdown, source_url, timestamp)
    header = <<~HEADER
      ---
      source: #{source_url}
      downloaded: #{timestamp.utc.strftime('%Y-%m-%d %H:%M:%S UTC')}
      ---

    HEADER

    header + markdown
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/markdown_converter_spec.rb`
Expected: PASS (all examples)

**Step 5: Commit**

```bash
git add spec/markdown_converter_spec.rb lib/markdown_converter.rb
git commit -m "Add MarkdownConverter with metadata headers"
```

---

## Task 5: FileOrganizer Class with Tests

**Files:**
- Create: `spec/file_organizer_spec.rb`
- Create: `lib/file_organizer.rb`

**Step 1: Write failing test for FileOrganizer**

```ruby
# spec/file_organizer_spec.rb
require_relative '../lib/file_organizer'
require 'tmpdir'
require 'fileutils'

RSpec.describe FileOrganizer do
  let(:output_dir) { Dir.mktmpdir }
  let(:organizer) { FileOrganizer.new(output_dir) }

  after { FileUtils.rm_rf(output_dir) }

  describe '#save_page' do
    it 'saves markdown to file based on URL path' do
      url = 'https://developers.bankid.com/api/authentication'
      content = '# Authentication'

      organizer.save_page(url, content)

      expected_path = File.join(output_dir, 'api', 'authentication.md')
      expect(File.exist?(expected_path)).to be true
      expect(File.read(expected_path)).to eq(content)
    end

    it 'handles root URL' do
      url = 'https://developers.bankid.com/'
      content = '# Home'

      organizer.save_page(url, content)

      expected_path = File.join(output_dir, 'index.md')
      expect(File.exist?(expected_path)).to be true
    end

    it 'creates nested directories' do
      url = 'https://developers.bankid.com/api/v1/authentication'
      content = '# Auth'

      organizer.save_page(url, content)

      expected_path = File.join(output_dir, 'api', 'v1', 'authentication.md')
      expect(File.exist?(expected_path)).to be true
    end
  end

  describe '#save_failed_url' do
    it 'appends failed URL to file' do
      organizer.save_failed_url('https://example.com/failed', 'Timeout error')
      organizer.save_failed_url('https://example.com/failed2', 'Not found')

      failed_file = File.join(output_dir, 'failed_urls.txt')
      expect(File.exist?(failed_file)).to be true

      content = File.read(failed_file)
      expect(content).to include('https://example.com/failed')
      expect(content).to include('Timeout error')
      expect(content).to include('https://example.com/failed2')
    end
  end

  describe '#generate_index' do
    it 'creates index file with all saved pages' do
      organizer.save_page('https://developers.bankid.com/api/auth', '# Auth')
      organizer.save_page('https://developers.bankid.com/api/signing', '# Signing')
      organizer.save_page('https://developers.bankid.com/guide', '# Guide')

      organizer.generate_index

      index_path = File.join(output_dir, 'INDEX.md')
      expect(File.exist?(index_path)).to be true

      content = File.read(index_path)
      expect(content).to include('# BankID Documentation Index')
      expect(content).to include('api/auth.md')
      expect(content).to include('api/signing.md')
      expect(content).to include('guide.md')
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/file_organizer_spec.rb`
Expected: FAIL with "cannot load such file -- file_organizer"

**Step 3: Write minimal implementation**

```ruby
# lib/file_organizer.rb
require 'fileutils'
require 'uri'

class FileOrganizer
  def initialize(output_dir)
    @output_dir = output_dir
    @saved_pages = []
    FileUtils.mkdir_p(@output_dir)
  end

  def save_page(url, content)
    file_path = url_to_filepath(url)
    full_path = File.join(@output_dir, file_path)

    # Create parent directories
    FileUtils.mkdir_p(File.dirname(full_path))

    # Write content
    File.write(full_path, content)

    # Track for index generation
    @saved_pages << file_path
  end

  def save_failed_url(url, error)
    failed_file = File.join(@output_dir, 'failed_urls.txt')
    File.open(failed_file, 'a') do |f|
      f.puts "#{url} - #{error}"
    end
  end

  def generate_index
    index_path = File.join(@output_dir, 'INDEX.md')

    content = "# BankID Documentation Index\n\n"
    content += "Total pages: #{@saved_pages.length}\n\n"
    content += "## Pages\n\n"

    @saved_pages.sort.each do |page_path|
      # Create relative link
      content += "- [#{page_path}](#{page_path})\n"
    end

    File.write(index_path, content)
  end

  private

  def url_to_filepath(url)
    uri = URI.parse(url)
    path = uri.path

    # Handle root
    return 'index.md' if path == '/' || path.empty?

    # Remove leading slash
    path = path[1..-1] if path.start_with?('/')

    # Add .md extension if not present
    path += '.md' unless path.end_with?('.md')

    path
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/file_organizer_spec.rb`
Expected: PASS (all examples)

**Step 5: Commit**

```bash
git add spec/file_organizer_spec.rb lib/file_organizer.rb
git commit -m "Add FileOrganizer with URL-to-path mapping"
```

---

## Task 6: ContentCrawler Class with Tests

**Files:**
- Create: `spec/content_crawler_spec.rb`
- Create: `lib/content_crawler.rb`

**Step 1: Write failing test for ContentCrawler**

```ruby
# spec/content_crawler_spec.rb
require_relative '../lib/content_crawler'

RSpec.describe ContentCrawler do
  let(:base_url) { 'https://developers.bankid.com' }
  let(:crawler) { ContentCrawler.new(base_url) }

  describe '#initialize' do
    it 'creates crawler with base URL' do
      expect(crawler).to be_a(ContentCrawler)
    end
  end

  describe '#add_url' do
    it 'adds URL to queue if not visited' do
      url = 'https://developers.bankid.com/api'
      expect(crawler.add_url(url)).to be true
    end

    it 'does not add duplicate URLs' do
      url = 'https://developers.bankid.com/api'
      crawler.add_url(url)
      expect(crawler.add_url(url)).to be false
    end

    it 'does not add external URLs' do
      url = 'https://google.com'
      expect(crawler.add_url(url)).to be false
    end
  end

  describe '#next_url' do
    it 'returns next URL from queue' do
      crawler.add_url('https://developers.bankid.com/api')
      crawler.add_url('https://developers.bankid.com/guide')

      expect(crawler.next_url).to eq('https://developers.bankid.com/api')
      expect(crawler.next_url).to eq('https://developers.bankid.com/guide')
    end

    it 'returns nil when queue is empty' do
      expect(crawler.next_url).to be_nil
    end
  end

  describe '#mark_visited' do
    it 'marks URL as visited' do
      url = 'https://developers.bankid.com/api'
      crawler.mark_visited(url)

      expect(crawler.add_url(url)).to be false
    end
  end

  describe '#stats' do
    it 'returns crawling statistics' do
      crawler.add_url('https://developers.bankid.com/api')
      crawler.mark_visited('https://developers.bankid.com/api')

      stats = crawler.stats
      expect(stats[:visited]).to eq(1)
      expect(stats[:queued]).to eq(0)
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/content_crawler_spec.rb`
Expected: FAIL with "cannot load such file -- content_crawler"

**Step 3: Write minimal implementation**

```ruby
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
```

**Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/content_crawler_spec.rb`
Expected: PASS (all examples)

**Step 5: Commit**

```bash
git add spec/content_crawler_spec.rb lib/content_crawler.rb
git commit -m "Add ContentCrawler with BFS queue management"
```

---

## Task 7: Main Orchestrator Script

**Files:**
- Create: `bankid_scraper.rb`

**Step 1: Write main script with CLI**

```ruby
#!/usr/bin/env ruby
# bankid_scraper.rb

require 'optparse'
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

    @browser.cleanup
  end

  private

  def process_page(url)
    stats = @crawler.stats
    puts "[#{stats[:visited] + 1}/#{stats[:total]}] Processing: #{url}"

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
```

**Step 2: Make script executable**

Run: `chmod +x bankid_scraper.rb`
Expected: File permissions updated

**Step 3: Test help output**

Run: `ruby bankid_scraper.rb --help`
Expected: Shows usage information

**Step 4: Commit**

```bash
git add bankid_scraper.rb
git commit -m "Add main orchestrator script with CLI"
```

---

## Task 8: Integration Test (Manual)

**Manual test steps:**

**Step 1: Run with max pages limit to test**

Run: `ruby bankid_scraper.rb --headless --max-pages 5 --output-dir ./test_output`
Expected: Downloads 5 pages, creates test_output directory

**Step 2: Verify output structure**

Run: `ls -R test_output/`
Expected: See markdown files organized by URL structure, INDEX.md file

**Step 3: Inspect markdown file**

Run: `head -20 test_output/index.md`
Expected: See metadata header with source URL and timestamp, followed by markdown content

**Step 4: Check INDEX file**

Run: `cat test_output/INDEX.md`
Expected: See list of all downloaded pages

**Step 5: Clean up test output**

Run: `rm -rf test_output`

---

## Task 9: Add Error Retry Logic

**Files:**
- Modify: `bankid_scraper.rb:58-85`

**Step 1: Add retry logic to process_page method**

Replace the `process_page` method with retry logic:

```ruby
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
```

**Step 2: Commit**

```bash
git add bankid_scraper.rb
git commit -m "Add exponential backoff retry logic for network errors"
```

---

## Task 10: Add .gitignore for Output

**Files:**
- Modify: `.gitignore`

**Step 1: Add output directories to .gitignore**

```
.worktrees/
bankid_docs/
test_output/
```

**Step 2: Commit**

```bash
git add .gitignore
git commit -m "Ignore scraper output directories"
```

---

## Task 11: Final Integration Test & Documentation

**Step 1: Run full scraper**

Run: `ruby bankid_scraper.rb --headless --output-dir ./bankid_docs`
Expected: Downloads complete BankID documentation

**Step 2: Verify output quality**

Run: `wc -l bankid_docs/INDEX.md`
Expected: Shows number of downloaded pages

Run: `head -30 bankid_docs/index.md`
Expected: See well-formatted markdown with metadata

**Step 3: Update README with example output**

Add to README.md:

```markdown
## Example Output

```
Starting BankID documentation scraper...
Base URL: https://developers.bankid.com/
Output: ./bankid_docs
Mode: headless
Max pages: unlimited

[1/1] Processing: https://developers.bankid.com/
  ✓ Saved (found 15 new links)
[2/16] Processing: https://developers.bankid.com/api
  ✓ Saved (found 3 new links)
...
==============================================================
Download Complete!
==============================================================
Total pages: 47
Successful: 45
Failed: 2
  (see ./bankid_docs/failed_urls.txt)
Duration: 3m 42s
Output: ./bankid_docs
==============================================================
```
```

**Step 4: Commit**

```bash
git add README.md
git commit -m "Add example output to README"
```

---

## Testing Guidelines

**Before each commit:**
- Run relevant tests: `bundle exec rspec spec/<file>_spec.rb`
- Ensure all tests pass

**TDD workflow reminder:**
- RED: Write failing test first
- GREEN: Write minimal code to pass
- REFACTOR: Clean up if needed
- COMMIT: Small, focused commits

**Integration testing:**
- Test with `--max-pages 5` first
- Verify output structure and content
- Run full scrape only when confident

**Debugging:**
- Use `--headed` flag to see browser
- Add `require 'pry'; binding.pry` for breakpoints
- Check failed_urls.txt for error patterns

---

## Common Issues & Solutions

**Playwright not installed:**
```bash
npx playwright install chromium
```

**Timeout errors:**
- Increase timeout in BrowserController
- Check internet connection
- Verify target site is accessible

**Content validation failures:**
- Inspect HTML structure on target site
- Adjust CONTENT_SELECTORS if needed
- Check if site uses different selectors

**Memory issues on large scrapes:**
- Use `--max-pages` to limit scope
- Run in batches if needed
- Monitor system resources

---

## Principles Applied

**DRY (Don't Repeat Yourself):**
- Shared selectors in constants
- Reusable components (extractor, converter, etc.)
- Common error handling in retry logic

**YAGNI (You Aren't Gonna Need It):**
- No incremental updates (future enhancement)
- No parallel downloads (future enhancement)
- No screenshot capture (future enhancement)
- Focus on core scraping functionality only

**TDD (Test-Driven Development):**
- Every component has tests first
- RED-GREEN-REFACTOR cycle
- Tests document expected behavior

**Frequent Commits:**
- One logical change per commit
- Clear commit messages
- Easy to revert if needed
