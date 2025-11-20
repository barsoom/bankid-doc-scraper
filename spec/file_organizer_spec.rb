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
