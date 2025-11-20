require 'playwright'

class BrowserController
  attr_reader :page

  def initialize(headless: true)
    @driver = Playwright.create(playwright_cli_executable_path: 'npx playwright')
    @playwright = @driver.playwright
    @browser = @playwright.chromium.launch(headless: headless)

    # Create context with realistic User-Agent
    @context = @browser.new_context(
      userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
      viewport: { width: 1920, height: 1080 }
    )
    @page = @context.new_page
  end

  def navigate_and_wait(url, selector: 'main, article, .content, body')
    @page.goto(url, waitUntil: 'domcontentloaded')
    @page.wait_for_selector(selector, state: 'visible', timeout: 10_000)
  rescue Playwright::TimeoutError => e
    # Fallback to body if specific selectors not found
    @page.wait_for_selector('body', state: 'visible', timeout: 5_000)
  end

  def cleanup
    @browser&.close
    @driver&.stop
  end
end
