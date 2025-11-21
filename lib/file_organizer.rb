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
    path = path[1..] if path.start_with?('/')

    # Add .md extension if not present
    path += '.md' unless path.end_with?('.md')

    path
  end
end
