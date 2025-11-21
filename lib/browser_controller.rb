require 'playwright'

class BrowserController
  attr_reader :page

  def initialize(headless: true)
    @driver = Playwright.create(playwright_cli_executable_path: 'npx playwright')
    @playwright = @driver.playwright

    # Launch with args to appear more like a real browser
    @browser = @playwright.chromium.launch(
      headless: headless,
      args: [
        '--disable-blink-features=AutomationControlled',
        '--disable-dev-shm-usage',
        '--no-sandbox'
      ]
    )

    # Create context with realistic User-Agent and extra headers
    @context = @browser.new_context(
      userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
      viewport: { width: 1920, height: 1080 },
      locale: 'en-US',
      timezoneId: 'Europe/Stockholm',
      extraHTTPHeaders: {
        'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
        'Accept-Language' => 'en-US,en;q=0.9,sv;q=0.8',
        'Accept-Encoding' => 'gzip, deflate, br',
        'DNT' => '1',
        'Connection' => 'keep-alive',
        'Upgrade-Insecure-Requests' => '1',
        'Sec-Fetch-Dest' => 'document',
        'Sec-Fetch-Mode' => 'navigate',
        'Sec-Fetch-Site' => 'none',
        'Sec-Fetch-User' => '?1',
        'Cache-Control' => 'max-age=0'
      }
    )

    @page = @context.new_page

    # Override navigator.webdriver property to hide automation
    @page.add_init_script(path: File.join(__dir__, 'stealth.js'))
  end

  def navigate_and_wait(url, selector: 'main, article, .content, body')
    # Wait for network to be idle (JavaScript finished loading content)
    @page.goto(url, waitUntil: 'networkidle')

    # Then wait for actual content to be visible
    @page.wait_for_selector(selector, state: 'visible', timeout: 15_000)
  rescue Playwright::TimeoutError
    # Fallback: wait a bit more and try body
    sleep 2
    @page.wait_for_selector('body', state: 'visible', timeout: 5_000)
  end

  def cleanup
    @browser&.close
    @driver&.stop
  end
end
