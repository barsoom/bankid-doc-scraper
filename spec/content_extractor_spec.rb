# spec/content_extractor_spec.rb
require 'spec_helper'
require_relative '../lib/content_extractor'
require 'nokogiri'

RSpec.describe ContentExtractor do
  let(:extractor) { described_class.new }

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
      content = "<h1>Title</h1><p>#{'x' * 150}</p>"
      expect(extractor.validate_content(content)).to be true
    end

    it 'returns false for content too short' do
      content = '<p>Short</p>'
      expect(extractor.validate_content(content)).to be false
    end

    it 'returns false for content without headings' do
      content = "<p>#{'x' * 150}</p>"
      expect(extractor.validate_content(content)).to be false
    end
  end
end
