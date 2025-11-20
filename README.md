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
