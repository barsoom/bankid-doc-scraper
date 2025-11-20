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
