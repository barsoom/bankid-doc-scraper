# spec/image_downloader_spec.rb
require 'spec_helper'
require_relative '../lib/image_downloader'
require 'tmpdir'
require 'webmock/rspec'

RSpec.describe ImageDownloader do
  let(:base_url) { 'https://developers.bankid.com' }
  let(:output_dir) { Dir.mktmpdir }
  let(:downloader) { described_class.new(base_url, output_dir) }

  after do
    FileUtils.rm_rf(output_dir)
  end

  describe '#initialize' do
    it 'creates images directory' do
      downloader # Force lazy-evaluation
      expect(File.directory?(File.join(output_dir, 'images'))).to be true
    end

    it 'initializes empty cache' do
      expect(downloader.stats[:total]).to eq(0)
    end
  end

  describe '#download_and_get_local_path' do
    it 'makes relative URLs absolute' do
      stub_request(:get, 'https://developers.bankid.com/assets/logo.png')
        .to_return(status: 200, body: 'fake image data')

      result = downloader.download_and_get_local_path('/assets/logo.png', base_url)

      expect(result).not_to be_nil
      expect(result).to match(%r{^images/.*\.png$})
    end

    it 'downloads image and returns local path' do
      image_url = 'https://developers.bankid.com/assets/logo.png'
      stub_request(:get, image_url)
        .to_return(status: 200, body: 'fake image data')

      result = downloader.download_and_get_local_path(image_url, base_url)

      expect(result).not_to be_nil
      expect(result).to start_with('images/')
      expect(result).to end_with('.png')
      expect(File.exist?(File.join(output_dir, result))).to be true
    end

    it 'caches downloaded images' do
      image_url = 'https://developers.bankid.com/assets/logo.png'
      stub_request(:get, image_url)
        .to_return(status: 200, body: 'fake image data')

      result1 = downloader.download_and_get_local_path(image_url, base_url)
      result2 = downloader.download_and_get_local_path(image_url, base_url)

      expect(result1).to eq(result2)
      # Should only request once due to caching
      expect(WebMock).to have_requested(:get, image_url).once
    end

    it 'returns nil for non-image URLs' do
      result = downloader.download_and_get_local_path('https://example.com/page.html', base_url)
      expect(result).to be_nil
    end

    it 'handles download failures gracefully' do
      image_url = 'https://developers.bankid.com/assets/missing.png'
      stub_request(:get, image_url)
        .to_return(status: 404)

      result = downloader.download_and_get_local_path(image_url, base_url)

      expect(result).to be_nil
    end

    it 'supports SVG images' do
      image_url = 'https://developers.bankid.com/assets/icon.svg'
      stub_request(:get, image_url)
        .to_return(status: 200, body: '<svg></svg>')

      result = downloader.download_and_get_local_path(image_url, base_url)

      expect(result).not_to be_nil
      expect(result).to end_with('.svg')
    end

    it 'detects images in /assets/ path' do
      # Even without .png extension, should be detected as image
      image_url = 'https://developers.bankid.com/assets/logo-bank-id'
      stub_request(:get, image_url)
        .to_return(status: 200, body: 'image data')

      downloader.download_and_get_local_path(image_url, base_url)

      # Should at least attempt to download
      expect(WebMock).to have_requested(:get, image_url)
    end
  end

  describe '#stats' do
    it 'tracks number of downloaded images' do
      stub_request(:get, 'https://developers.bankid.com/img1.png')
        .to_return(status: 200, body: 'data1')
      stub_request(:get, 'https://developers.bankid.com/img2.png')
        .to_return(status: 200, body: 'data2')

      downloader.download_and_get_local_path('https://developers.bankid.com/img1.png', base_url)
      downloader.download_and_get_local_path('https://developers.bankid.com/img2.png', base_url)

      expect(downloader.stats[:total]).to eq(2)
    end

    it 'does not count failed downloads' do
      stub_request(:get, 'https://developers.bankid.com/img1.png')
        .to_return(status: 404)

      downloader.download_and_get_local_path('https://developers.bankid.com/img1.png', base_url)

      expect(downloader.stats[:total]).to eq(0)
    end
  end

  describe 'filename generation' do
    it 'generates unique hash-prefixed filenames' do
      stub_request(:get, 'https://developers.bankid.com/logo.png')
        .to_return(status: 200, body: 'data')

      result = downloader.download_and_get_local_path('https://developers.bankid.com/logo.png', base_url)

      # Should have format: images/[hash]-logo.png
      expect(result).to match(%r{^images/[a-f0-9]{12}-logo\.png$})
    end

    it 'generates different filenames for different URLs' do
      stub_request(:get, 'https://developers.bankid.com/logo1.png')
        .to_return(status: 200, body: 'data1')
      stub_request(:get, 'https://developers.bankid.com/logo2.png')
        .to_return(status: 200, body: 'data2')

      result1 = downloader.download_and_get_local_path('https://developers.bankid.com/logo1.png', base_url)
      result2 = downloader.download_and_get_local_path('https://developers.bankid.com/logo2.png', base_url)

      expect(result1).not_to eq(result2)
    end
  end
end
