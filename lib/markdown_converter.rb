# lib/markdown_converter.rb
require 'reverse_markdown'
require 'nokogiri'
require 'uri'

class MarkdownConverter
  def initialize(image_downloader: nil)
    @image_downloader = image_downloader
  end

  def convert(html, source_url, timestamp)
    # Make links absolute
    html = make_links_absolute(html, source_url)

    # Download and update image references
    html = download_images(html, source_url) if @image_downloader

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

  def download_images(html, source_url)
    doc = Nokogiri::HTML(html)

    doc.css('img[src]').each do |img|
      src = img['src']
      next if src.nil? || src.empty?

      # Download image and get local path
      local_path = @image_downloader.download_and_get_local_path(src, source_url)

      # Update src to local path if download succeeded
      img['src'] = "../#{local_path}" if local_path
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
