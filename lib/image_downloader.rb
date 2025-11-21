require 'net/http'
require 'uri'
require 'digest'
require 'fileutils'

class ImageDownloader
  IMAGE_EXTENSIONS = %w[.png .jpg .jpeg .gif .svg .webp .ico .avif].freeze
  IMAGES_DIR = 'images'

  def initialize(base_url, output_dir)
    @base_url = base_url
    @output_dir = output_dir
    @images_dir = File.join(@output_dir, IMAGES_DIR)
    @downloaded_images = {}

    FileUtils.mkdir_p(@images_dir)
  end

  def download_and_get_local_path(image_url, page_url)
    # Make URL absolute if relative
    absolute_url = make_absolute_url(image_url, page_url)

    # Return cached path if already downloaded
    return @downloaded_images[absolute_url] if @downloaded_images[absolute_url]

    # Skip if not an image
    return nil unless looks_like_image?(absolute_url)

    # Download image
    begin
      image_data = download_image(absolute_url)
      return nil unless image_data

      # Generate local filename
      local_filename = generate_filename(absolute_url)
      local_path = File.join(IMAGES_DIR, local_filename)
      full_path = File.join(@output_dir, local_path)

      # Save image
      File.binwrite(full_path, image_data)

      # Cache the mapping
      @downloaded_images[absolute_url] = local_path

      local_path
    rescue StandardError => e
      puts "  ⚠️  Failed to download image #{absolute_url}: #{e.message}"
      nil
    end
  end

  def stats
    {
      total: @downloaded_images.size,
      directory: @images_dir
    }
  end

  private

  def make_absolute_url(url, base)
    return url if url.start_with?('http://', 'https://')

    begin
      URI.join(base, url).to_s
    rescue URI::InvalidURIError
      url
    end
  end

  def looks_like_image?(url)
    # Check file extension
    uri = URI.parse(url)
    path = uri.path.downcase

    IMAGE_EXTENSIONS.any? { |ext| path.end_with?(ext) } ||
      path.include?('/assets/') ||
      path.include?('/images/') ||
      path.include?('/img/')
  rescue URI::InvalidURIError
    false
  end

  def download_image(url)
    uri = URI.parse(url)

    # Use the page's browser context if possible, but for now just do HTTP
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', read_timeout: 10) do |http|
      request = Net::HTTP::Get.new(uri.request_uri)
      request['User-Agent'] = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
      http.request(request)
    end

    return nil unless response.code == '200'
    response.body
  rescue StandardError => e
    puts "  ⚠️  Error downloading #{url}: #{e.class} - #{e.message}"
    nil
  end

  def generate_filename(url)
    uri = URI.parse(url)

    # Get original filename
    original_name = File.basename(uri.path)
    extension = File.extname(original_name)
    extension = '.png' if extension.empty?

    # Create hash of full URL for uniqueness
    url_hash = Digest::SHA256.hexdigest(url)[0..11]

    # If we have a good filename, use it with hash prefix
    if original_name.length > 0 && original_name != '/'
      base_name = File.basename(original_name, extension)
      "#{url_hash}-#{base_name}#{extension}"
    else
      "#{url_hash}#{extension}"
    end
  end
end
