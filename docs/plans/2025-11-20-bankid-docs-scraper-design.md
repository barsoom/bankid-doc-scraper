# BankID Documentation Scraper Design

**Date:** 2025-11-20
**Purpose:** Download complete BankID developer documentation for use as Claude context
**Technology:** Ruby with Playwright browser automation

## Overview

A Ruby script to download the complete BankID developer documentation from https://developers.bankid.com/, handling JavaScript-rendered content and outputting organized markdown files suitable for providing as context to Claude.

## Requirements

- **Goal:** Download full documentation site including all sections
- **Output Format:** Multiple organized markdown files (preserves structure, allows selective context)
- **Technology Stack:** Ruby with Playwright for browser automation
- **Key Challenge:** Site is heavily JavaScript-rendered, requiring browser automation

## Architecture

### Core Components

1. **Browser Controller** - Manages Playwright browser instance, handles navigation and wait conditions
2. **Content Crawler** - Discovers all documentation pages by following links within the docs domain
3. **Content Extractor** - Pulls rendered content from each page, strips navigation/UI chrome
4. **Markdown Converter** - Transforms HTML content to clean markdown using `reverse_markdown` gem
5. **File Organizer** - Saves markdown files with structure mirroring the site's URL hierarchy

### Workflow

```
Start
  ↓
Initialize Browser (Playwright + Chrome)
  ↓
Load Base URL (https://developers.bankid.com/)
  ↓
Wait for JS Rendering
  ↓
Extract All Documentation Links
  ↓
Build URL Queue
  ↓
For Each URL:
  - Navigate to page
  - Wait for content visibility
  - Extract main documentation area
  - Convert HTML to Markdown
  - Save to organized file structure
  - Extract any new links → Add to queue
  ↓
Generate INDEX.md (table of contents)
  ↓
Cleanup & Close Browser
  ↓
Done
```

### Key Decisions

- **Browser:** Headless Chrome for speed (can enable headed mode for debugging)
- **Wait Strategy:** Playwright's built-in selectors waiting for content visibility
- **File Structure:** URL-to-filepath mapping preserves site structure (e.g., `/docs/api/auth` → `docs/api/auth.md`)
- **Deduplication:** Skip duplicate URLs and external links using visited Set
- **Crawling:** Breadth-first traversal to discover all pages

## Component Details

### Browser Controller

```ruby
class BrowserController
  def initialize(headless: true)
    @playwright = Playwright.create(playwright_cli_executable_path: "npx playwright")
    @browser = @playwright.chromium.launch(headless: headless)
    @context = @browser.new_context
    @page = @context.new_page
  end

  def navigate_and_wait(url, selector: "main, article, .content")
    @page.goto(url, wait_until: "domcontentloaded")
    @page.wait_for_selector(selector, state: "visible", timeout: 10_000)
  end

  def cleanup
    @browser.close
    @playwright.stop
  end
end
```

**Responsibilities:**
- Launch and configure Playwright browser
- Navigate to URLs with proper wait conditions
- Expose page object for content extraction
- Clean shutdown

### Content Crawler

**Responsibilities:**
- Start from base URL (https://developers.bankid.com/)
- Extract all links matching the docs domain
- Maintain visited Set to avoid duplicates
- Breadth-first traversal to discover all pages
- Filter out assets (images, CSS, JS files)

**Implementation Notes:**
- Use queue data structure for BFS
- Check URLs against visited set before adding
- Only follow links within developers.bankid.com domain
- Skip anchor links (#fragments) to same page
- Skip file extensions: .png, .jpg, .pdf, .css, .js

### Content Extractor

**Content Selector Priority:**
```ruby
CONTENT_SELECTORS = [
  'article',                    # Semantic HTML5 article
  'main',                       # Main content area
  '[role="main"]',              # ARIA main role
  '.documentation-content',     # Common class names
  '.doc-content',
  '.markdown-body',
  '#content'
]
```

**Elements to Strip:**
```ruby
STRIP_SELECTORS = [
  'nav', 'header', 'footer',
  '.sidebar', '.navigation',
  '.table-of-contents',
  'button', '.cookie-banner'
]
```

**Process:**
1. Try each content selector in priority order
2. If found, extract HTML
3. Remove elements matching strip selectors
4. Preserve code blocks, headings, lists, links
5. Validate extraction (minimum length, meaningful headings)
6. If validation fails, save both cleaned markdown AND raw HTML for manual review

### Markdown Converter

**Tools:** `reverse_markdown` gem

**Configuration:**
- Preserve code blocks with language hints
- Convert tables to markdown tables
- Keep link URLs absolute (prepend base URL to relative links)
- Clean up excessive whitespace/newlines
- Handle special characters properly

**Metadata Header:**
```markdown
---
source: https://developers.bankid.com/api/authentication
downloaded: 2025-11-20 14:32:15 UTC
---

# Page Title
...content...
```

### File Organizer

**Directory Structure:**
```
bankid_docs/
├── INDEX.md                    # Table of contents
├── api/
│   ├── authentication.md
│   ├── signing.md
│   └── ...
├── guides/
│   ├── getting-started.md
│   └── ...
└── failed_urls.txt            # URLs that failed to download
```

**Mapping Rules:**
- Base output directory: `./bankid_docs` (configurable)
- URL path becomes file path: `/api/authentication` → `bankid_docs/api/authentication.md`
- Create parent directories as needed
- Generate INDEX.md with links to all downloaded pages

## Error Handling

### Network Failures
- Retry up to 3 times with exponential backoff
- Delays: 1s, 2s, 4s

### Timeout on Page Load
- Log warning with URL
- Skip page and continue crawling
- Add to failed_urls.txt

### Missing Content Selector
- Try all fallback selectors in priority order
- If all fail, save raw HTML
- Log warning for manual review

### File Write Errors
- Fail fast on critical errors (disk full, permissions)
- Don't continue with partial download
- Clear error message to user

### Playwright Installation
- Check for playwright binaries on startup
- Provide clear setup instructions if missing:
  ```
  npm install -D playwright
  npx playwright install chromium
  ```

## Progress Tracking

**During Execution:**
```
[12/47] Downloading /api/authentication
[13/47] Downloading /api/signing
...
```

**Summary at End:**
```
Download Complete!
- Total pages: 47
- Successful: 45
- Failed: 2 (see failed_urls.txt)
- Duration: 3m 42s
- Output: ./bankid_docs
```

## Configuration

**Command-Line Options:**
- `--headless` / `--headed` - Show browser during scraping (default: headless)
- `--output-dir PATH` - Where to save markdown files (default: `./bankid_docs`)
- `--base-url URL` - Starting URL (default: `https://developers.bankid.com/`)
- `--max-pages N` - Limit for testing (default: unlimited)

**Example Usage:**
```bash
# Normal usage
ruby bankid_scraper.rb

# Debug mode with visible browser
ruby bankid_scraper.rb --headed --max-pages 5

# Custom output location
ruby bankid_scraper.rb --output-dir ~/Documents/bankid_docs
```

## Dependencies

**Gems Required:**
- `playwright-ruby-client` - Browser automation
- `reverse_markdown` - HTML to Markdown conversion
- `nokogiri` - HTML parsing (dependency of reverse_markdown)

**System Requirements:**
- Ruby 2.7+
- Node.js (for Playwright)
- Chromium browser (installed via Playwright)

**Installation:**
```bash
gem install playwright-ruby-client reverse_markdown
npx playwright install chromium
```

## Content Validation

**Criteria for Valid Page:**
- Minimum content length: 100 characters
- Contains meaningful headings (h1-h3)
- Not a redirect or error page

**If Invalid:**
- Log warning
- Save both cleaned markdown AND raw HTML
- Add to manual review list

## Future Enhancements (YAGNI for v1)

- Incremental updates (only download changed pages)
- Parallel page downloads
- Screenshot capture for visual documentation
- PDF export option
- Watch mode for continuous updates
