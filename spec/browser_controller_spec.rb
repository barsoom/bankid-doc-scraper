require_relative '../lib/browser_controller'

RSpec.describe BrowserController do
  describe '#initialize' do
    it 'creates a browser controller with headless mode by default' do
      controller = described_class.new
      expect(controller).to be_a(described_class)
      expect(controller.page).not_to be_nil
      controller.cleanup
    end

    it 'creates a browser controller with explicit headless mode' do
      controller = described_class.new(headless: true)
      expect(controller).to be_a(described_class)
      expect(controller.page).not_to be_nil
      controller.cleanup
    end
  end

  describe '#navigate_and_wait' do
    let(:controller) { described_class.new(headless: true) }

    after { controller.cleanup }

    it 'navigates to URL and waits for content' do
      # Use a simple static page for testing
      expect { controller.navigate_and_wait('https://example.com') }.not_to raise_error
    end
  end

  describe '#cleanup' do
    it 'closes browser and stops playwright' do
      controller = described_class.new
      expect { controller.cleanup }.not_to raise_error
    end
  end
end
