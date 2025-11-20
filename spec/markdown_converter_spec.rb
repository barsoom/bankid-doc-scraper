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
