# lib/markdown_converter.rb
require 'reverse_markdown'
require 'nokogiri'
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
