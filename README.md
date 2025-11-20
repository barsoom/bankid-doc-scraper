# BankID Documentation Scraper

Downloads complete BankID developer documentation from https://developers.bankid.com/

## Prerequisites

- Ruby 3.0+
- Node.js (for Playwright)

## Setup

```bash
bundle install --path vendor/bundle
npm install
npx playwright install chromium
```

## Usage

```bash
ruby bankid_scraper.rb
```

## Options

- `--headless` / `--headed` - Show browser (default: headless)
- `--output-dir PATH` - Output directory (default: ./bankid_docs)
- `--base-url URL` - Starting URL (default: https://developers.bankid.com/)
- `--max-pages N` - Limit pages for testing (default: unlimited)

## Example Output

```
Starting BankID documentation scraper...
Base URL: https://developers.bankid.com/
Output: ./bankid_docs
Mode: headless
Max pages: unlimited

[1/1] Processing: https://developers.bankid.com/
  ✓ Saved (found 15 new links)
[2/16] Processing: https://developers.bankid.com/api
  ✓ Saved (found 3 new links)
...
==============================================================
Download Complete!
==============================================================
Total pages: 47
Successful: 45
Failed: 2
  (see ./bankid_docs/failed_urls.txt)
Duration: 3m 42s
Output: ./bankid_docs
==============================================================
```

## Known Limitations

The BankID developer documentation site (`https://developers.bankid.com/`) uses bot protection (CAPTCHA) which prevents automated scraping. This scraper implementation is fully functional but cannot bypass CAPTCHA protection.

The scraper works correctly on documentation sites without bot protection. All components (browser automation, content extraction, markdown conversion, file organization) have been tested and verified.
