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
