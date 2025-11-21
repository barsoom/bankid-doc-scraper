# BankID Documentation Scraper

A Ruby-based web scraper that downloads the complete BankID developer documentation from [developers.bankid.com](https://developers.bankid.com/) and converts it to clean, well-organized Markdown files.

Perfect for:
- Creating offline documentation archives
- Using BankID documentation as context for AI assistants like Claude
- Building local documentation mirrors
- Archiving API documentation versions

## Features

- ✅ **Bot Detection Bypass** - Advanced browser fingerprinting evasion to bypass Radware CAPTCHA
- ✅ **JavaScript Rendering** - Full Playwright browser automation for JavaScript-heavy sites
- ✅ **Sitemap-Based Discovery** - Efficient URL discovery using the site's sitemap.xml
- ✅ **Smart Content Extraction** - Removes navigation, sidebars, and other non-content elements
- ✅ **Clean Markdown Output** - Converts HTML to readable Markdown with proper formatting
- ✅ **Image Downloading** - Automatically downloads and embeds images locally
- ✅ **Metadata Headers** - Each file includes source URL and download timestamp
- ✅ **Rate Limiting** - Random delays (2-5s) between requests to be respectful
- ✅ **Automatic Retry** - Exponential backoff retry logic for failed requests
- ✅ **Directory Organization** - Preserves URL structure in output directory
- ✅ **Progress Tracking** - Real-time progress indicators and statistics
- ✅ **Error Handling** - Comprehensive error handling with detailed logging

## Prerequisites

- **Ruby** 3.2 or higher
- **Node.js** and **npm** (for Playwright)
- **Bundler** gem

## Installation

1. **Install Ruby dependencies:**
   ```bash
   bundle install --path vendor/bundle
   ```

2. **Install Node.js dependencies:**
   ```bash
   npm install
   ```

3. **Install Playwright browsers:**
   ```bash
   npx playwright install chromium
   ```

## Quick Start

**Download all documentation (69 pages):**
```bash
bundle exec ruby bankid_scraper.rb
```

**Test with just 5 pages:**
```bash
bundle exec ruby bankid_scraper.rb --max-pages 5
```

**Run with visible browser (debugging):**
```bash
bundle exec ruby bankid_scraper.rb --no-headless
```

## Usage

### Basic Usage

```bash
bundle exec ruby bankid_scraper.rb [options]
```

### Command-Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `--headless` / `--no-headless` | Run browser in headless mode | `true` |
| `--output-dir DIR` | Output directory for markdown files | `./bankid_docs` |
| `--base-url URL` | Starting URL to scrape | `https://developers.bankid.com/` |
| `--max-pages N` | Maximum number of pages to download | unlimited |
| `-h`, `--help` | Show help message | - |

### Examples

**Download to custom directory:**
```bash
bundle exec ruby bankid_scraper.rb --output-dir ~/docs/bankid
```

**Download with visible browser (useful for debugging):**
```bash
bundle exec ruby bankid_scraper.rb --no-headless --max-pages 3
```

**Scrape a different BankID environment:**
```bash
bundle exec ruby bankid_scraper.rb --base-url https://other-url.com/
```

## Output

The scraper creates:

```
bankid_docs/
├── INDEX.md                          # Table of contents with all pages
├── images/                           # Downloaded images
│   ├── a1f618f904c8-logo-bank-id.svg
│   ├── 8e63ea1e92f1-flow-light-app.png
│   └── ...
├── getting-started.md
├── getting-started/
│   ├── introduction.md
│   ├── use-cases.md
│   ├── environments.md
│   └── ...
├── api-references/
│   ├── auth--sign/
│   │   ├── auth.md
│   │   ├── sign.md
│   │   └── ...
│   └── ...
├── resources/
├── test-portal/
└── news/
```

### Markdown Format

Each markdown file includes YAML frontmatter with metadata:

```markdown
---
source: https://developers.bankid.com/getting-started/introduction
downloaded: 2025-11-21 00:30:15 UTC
---

# Introduction

BankID is an eID. We provide secure digital identification...
```

## How It Works

### Architecture

The scraper consists of 6 main components:

1. **BrowserController** (`lib/browser_controller.rb`)
   - Manages Playwright browser instance
   - Implements bot detection evasion techniques
   - Handles JavaScript rendering with proper wait strategies

2. **ContentCrawler** (`lib/content_crawler.rb`)
   - BFS-based URL queue management
   - URL deduplication and filtering
   - Progress tracking

3. **ContentExtractor** (`lib/content_extractor.rb`)
   - Extracts main content from HTML
   - Strips navigation, sidebars, and other noise
   - Discovers internal links
   - Validates content quality

4. **MarkdownConverter** (`lib/markdown_converter.rb`)
   - Converts HTML to Markdown
   - Adds YAML frontmatter metadata
   - Converts relative URLs to absolute

5. **FileOrganizer** (`lib/file_organizer.rb`)
   - Maps URLs to filesystem paths
   - Creates directory structure
   - Generates INDEX.md table of contents
   - Tracks failed URLs

6. **Main Orchestrator** (`bankid_scraper.rb`)
   - Coordinates all components
   - Fetches sitemap for URL discovery
   - Implements rate limiting
   - Handles retries and error recovery

### Bot Detection Evasion

The scraper bypasses Radware bot protection using:

- **Browser Launch Args:**
  - `--disable-blink-features=AutomationControlled`
  - Realistic viewport (1920x1080)
  - Proper timezone and locale settings

- **HTTP Headers:**
  - Realistic User-Agent (Chrome 131 on Linux)
  - Complete Accept headers (HTML, XHTML, XML, WebP, AVIF)
  - Sec-Fetch-* headers for CORS compliance
  - Accept-Language, DNT, Connection headers

- **JavaScript Overrides** (`lib/stealth.js`):
  - Hides `navigator.webdriver` property
  - Adds realistic `navigator.plugins`
  - Sets device memory and hardware concurrency
  - Implements chrome runtime object
  - Overrides permissions API

- **Wait Strategy:**
  - `networkidle` instead of `domcontentloaded`
  - Ensures all JavaScript finishes rendering

## Testing

Run the test suite:

```bash
bundle exec rspec
```

Run specific test file:

```bash
bundle exec rspec spec/browser_controller_spec.rb
```

The test suite includes 31 tests covering all components with TDD methodology.

## Project Structure

```
.
├── README.md                      # This file
├── DEPENDENCY_SECURITY_REPORT.md  # Security audit of all dependencies
├── Gemfile                        # Ruby dependencies
├── Gemfile.lock                   # Locked Ruby dependency versions
├── package.json                   # Node.js dependencies
├── package-lock.json              # Locked npm dependency versions
├── .gitignore                     # Git ignore rules
│
├── bankid_scraper.rb              # Main entry point
│
├── lib/                           # Core library code
│   ├── browser_controller.rb     # Playwright browser management
│   ├── content_crawler.rb        # URL queue and crawling logic
│   ├── content_extractor.rb      # HTML content extraction
│   ├── markdown_converter.rb     # HTML to Markdown conversion
│   ├── file_organizer.rb         # File system operations
│   └── stealth.js                # Browser fingerprint evasion
│
├── spec/                          # RSpec test suite
│   ├── browser_controller_spec.rb
│   ├── content_crawler_spec.rb
│   ├── content_extractor_spec.rb
│   ├── markdown_converter_spec.rb
│   └── file_organizer_spec.rb
│
├── docs/                          # Design and planning documents
│   └── plans/
│       ├── 2025-11-20-bankid-docs-scraper-design.md
│       └── 2025-11-20-bankid-docs-scraper-implementation.md
│
├── vendor/                        # Ruby gems (local install)
├── node_modules/                  # npm packages (local install)
└── bankid_docs/                   # Output directory (generated)
```

## Dependencies

All dependencies have been audited for security. See [DEPENDENCY_SECURITY_REPORT.md](DEPENDENCY_SECURITY_REPORT.md) for details.

### Ruby Gems

- **nokogiri** (~> 1.15) - HTML/XML parsing
- **playwright-ruby-client** (~> 1.44) - Browser automation
- **reverse_markdown** (~> 2.1) - HTML to Markdown conversion
- **rspec** (~> 3.12) - Testing framework (dev/test)
- **pry** (~> 0.14) - Debugging console (dev/test)

### Node.js Packages

- **playwright** (^1.44.0) - Browser automation framework by Microsoft

**Security Status:** ✅ All dependencies are secure with 0 known vulnerabilities.

## Performance

Typical performance metrics:

- **Pages:** 69 pages
- **Duration:** ~5 minutes (with 2-5s delays between requests)
- **Output Size:** ~450KB of markdown
- **Success Rate:** 100% (69/69 pages)
- **Network:** ~20MB total download
- **Memory:** ~200MB peak usage

## Troubleshooting

### "Playwright not found" error

**Solution:** Install Playwright browsers:
```bash
npx playwright install chromium
```

### Getting CAPTCHA pages instead of content

**Symptoms:** Files contain "Radware Captcha Page" text

**Solution:** The stealth.js and browser headers should prevent this, but if it happens:
1. Try running with `--no-headless` to see what's happening
2. Increase delays between requests
3. Clear any cookies/cache and try again

### "Content validation failed" warnings

**Explanation:** The page was saved but didn't pass quality checks (minimum length or headings)

**Action:** Usually safe to ignore for special pages like search or error pages

### Playwright browser crashes

**Solution:** Increase system resources or reduce concurrent operations:
```bash
# Run with visible browser to debug
bundle exec ruby bankid_scraper.rb --no-headless --max-pages 5
```

### Permission errors on vendor/ or node_modules/

**Solution:** Ensure you have write permissions:
```bash
chmod -R u+w vendor/ node_modules/
```

## Ethical Usage

This scraper is designed for:
- ✅ Creating personal offline documentation
- ✅ Educational purposes
- ✅ Development reference materials
- ✅ Archiving public documentation

Please use responsibly:
- ⚠️ Respect the site's robots.txt
- ⚠️ Don't overwhelm servers (we use 2-5s delays)
- ⚠️ Don't republish or redistribute the scraped content
- ⚠️ Credit BankID for their documentation

The BankID documentation is publicly available, and this tool simply automates downloading it for offline use.

## Known Limitations

- **JavaScript-only content:** Requires full browser rendering (slower than simple HTTP requests)
- **Dynamic content:** Some interactive elements may not render perfectly in Markdown
- **Rate limiting:** 2-5s delays mean full scrape takes ~5 minutes for 69 pages
- **BankID-specific:** Selectors are tuned for developers.bankid.com structure

## Future Enhancements

Potential improvements:

- [x] Download and embed images locally (✅ Implemented)
- [ ] Support for multiple output formats (PDF, HTML, etc.)
- [ ] Incremental updates (only fetch changed pages)
- [ ] Parallel page processing
- [ ] Configuration file support
- [ ] Docker container for easier deployment
- [ ] Web UI for progress monitoring

## Contributing

This is a personal project, but suggestions and improvements are welcome:

1. Fork the repository
2. Create a feature branch
3. Install git hooks: `script/setup-hooks`
4. Make your changes with tests
5. Run the test suite: `bundle exec rspec`
6. Run the linter: `bundle exec rubocop`
7. Submit a pull request

## Development

### Running Tests

```bash
# All tests
bundle exec rspec

# Specific test file
bundle exec rspec spec/browser_controller_spec.rb

# With documentation format
bundle exec rspec --format documentation
```

### Code Quality

This project uses RuboCop for linting and code style enforcement.

```bash
# Run linter
bundle exec rubocop

# Auto-fix violations
bundle exec rubocop --autocorrect-all

# Check specific files
bundle exec rubocop lib/browser_controller.rb
```

**Git Hooks:**

Install git hooks to automatically run RuboCop before commits:

```bash
script/setup-hooks
```

Once installed, RuboCop will run on staged Ruby files before each commit. If violations are found:
- Fix them manually or run `bundle exec rubocop --autocorrect-all`
- Or commit with `git commit --no-verify` to skip the check (not recommended)

### Code Coverage

This project uses SimpleCov to track test coverage:

```bash
# Run tests with coverage (automatically enabled)
bundle exec rspec

# View coverage report
open coverage/index.html  # macOS
xdg-open coverage/index.html  # Linux
```

**Current Coverage:**
- Line Coverage: **89.76%** (184 / 205 lines)
- Branch Coverage: **73.08%** (38 / 52 branches)

Coverage reports are generated automatically when running tests and saved to `coverage/`. This directory is excluded from git.

### Debugging

Use Pry for interactive debugging:

```ruby
require 'pry'

def some_method
  binding.pry  # Execution will stop here
  # ...
end
```

Run with visible browser:
```bash
bundle exec ruby bankid_scraper.rb --no-headless --max-pages 1
```

## License

This project is open source and available for personal and educational use.

The BankID documentation remains the property of BankID/Finansiell ID-Teknik BID AB.

## Acknowledgments

- **BankID** for providing comprehensive developer documentation
- **Microsoft** for the excellent Playwright framework
- **YusukeIwaki** for playwright-ruby-client
- **Ruby community** for the excellent ecosystem of gems

## Support

For issues, questions, or suggestions:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review [DEPENDENCY_SECURITY_REPORT.md](DEPENDENCY_SECURITY_REPORT.md) for security concerns
3. Run with `--no-headless` to debug visually
4. Check Playwright logs for browser-specific issues

---

**Built with Ruby 3.2, Playwright, and ❤️**

*Last updated: 2025-11-21*
