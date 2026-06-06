# Playwright Browser Automation Sidecar

HTTP service used by Flutter desktop for Chrome/Edge web form automation.

## Setup

```bash
cd automation/playwright
npm install
npm run install-browsers
npm start
```

Service runs at `http://127.0.0.1:3939`.

## Features

- Launch Chromium / Chrome / Edge
- Auto-detect inputs, labels, selects
- Scroll long multi-step forms
- Fill text fields and dropdowns
- Upload images/documents (`input[type=file]`)
- Retry scroll when no fields matched
