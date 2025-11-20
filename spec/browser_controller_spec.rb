require_relative '../lib/browser_controller'

RSpec.describe BrowserController do
  describe '#initialize' do
    it 'creates a browser controller with headless mode by default' do
      controller = BrowserController.new
      expect(controller).to be_a(BrowserController)
      controller.cleanup
    end

    it 'accepts headless option' do
      # Note: headed mode requires X server, so we just test it accepts the param
      controller = BrowserController.new(headless: true)
      expect(controller).to be_a(BrowserController)
      controller.cleanup
    end
  end

  describe '#navigate_and_wait' do
    let(:controller) { BrowserController.new(headless: true) }

    after { controller.cleanup }

    it 'navigates to URL and waits for content' do
      # Use a simple static page for testing
      expect { controller.navigate_and_wait('https://example.com') }.not_to raise_error
    end
  end

  describe '#cleanup' do
    it 'closes browser and stops playwright' do
      controller = BrowserController.new
      expect { controller.cleanup }.not_to raise_error
    end
  end
end
