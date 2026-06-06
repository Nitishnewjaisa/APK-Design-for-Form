import { chromium } from 'playwright';
import { matchLabel } from './label-matcher.mjs';
import { ScrollManager } from './scroll-manager.mjs';

let browser = null;
let context = null;
let page = null;
let running = false;
let paused = false;

export const status = {
  state: 'idle',
  message: '',
  fieldsFilled: 0,
  fieldsTotal: 0,
  scrollCount: 0,
};

function setStatus(state, message = '', extra = {}) {
  Object.assign(status, { state, message, ...extra });
}

function browserType(name) {
  switch (name) {
    case 'chrome':
      return { channel: 'chrome' };
    case 'msedge':
      return { channel: 'msedge' };
    case 'firefox':
      return { product: 'firefox' };
    default:
      return {};
  }
}

async function collectInputs(pg) {
  return pg.evaluate(() => {
    const inputs = [];
    const nodes = document.querySelectorAll(
      'input, textarea, select, [contenteditable="true"]'
    );
    nodes.forEach((el, index) => {
      const rect = el.getBoundingClientRect();
      const label =
        el.getAttribute('aria-label') ||
        el.getAttribute('placeholder') ||
        el.getAttribute('name') ||
        el.id ||
        '';
      let associated = '';
      if (el.id) {
        const lbl = document.querySelector(`label[for="${el.id}"]`);
        if (lbl) associated = lbl.textContent?.trim() || '';
      }
      inputs.push({
        index,
        tag: el.tagName.toLowerCase(),
        type: el.type || '',
        label: associated || label,
        ariaLabel: el.getAttribute('aria-label') || '',
        name: el.getAttribute('name') || '',
        id: el.id || '',
        placeholder: el.getAttribute('placeholder') || '',
        isDropdown: el.tagName.toLowerCase() === 'select',
        isFileInput: el.type === 'file',
        x: rect.x,
        y: rect.y,
        width: rect.width,
        height: rect.height,
        selector: el.id
          ? `#${CSS.escape(el.id)}`
          : el.name
            ? `[name="${el.name}"]`
            : `${el.tagName.toLowerCase()}:nth-of-type(${index + 1})`,
      });
    });
    return inputs;
  });
}

async function fillField(pg, input, value) {
  const selector = input.selector;
  try {
    if (input.isFileInput) return false;
    if (input.isDropdown) {
      await pg.selectOption(selector, { label: value }).catch(async () => {
        await pg.selectOption(selector, value);
      });
      return true;
    }
    await pg.fill(selector, value);
    return true;
  } catch {
    return false;
  }
}

async function uploadFiles(pg, paths) {
  for (const filePath of paths) {
    const inputs = await pg.locator('input[type="file"]').all();
    if (inputs.length > 0) {
      await inputs[0].setInputFiles(filePath);
    }
  }
}

export async function startAutomation(config) {
  if (running) await stopAutomation();
  running = true;
  paused = false;
  const fields = config.fields || {};
  const fieldKeys = Object.keys(fields);
  status.fieldsTotal = fieldKeys.length;
  status.fieldsFilled = 0;
  status.scrollCount = 0;

  setStatus('scanning', 'Launching browser…');

  const launchOpts = {
    headless: false,
    ...browserType(config.browser || 'chromium'),
  };
  browser = await chromium.launch(launchOpts);
  context = await browser.newContext();
  page = await context.newPage();

  if (config.url) {
    await page.goto(config.url, { waitUntil: 'domcontentloaded', timeout: 60000 });
  }

  if (config.uploadPaths?.length) {
    setStatus('filling', 'Uploading documents…');
    await uploadFiles(page, config.uploadPaths);
  }

  const scroll = new ScrollManager(page, {
    maxRetries: config.maxScrollRetries || 8,
    delayMs: config.scrollDelayMs || 600,
  });

  const filled = new Set();
  let retries = 0;

  while (running && filled.size < fieldKeys.length && retries < (config.maxScrollRetries || 8) + 3) {
    if (paused) {
      await page.waitForTimeout(300);
      continue;
    }

    setStatus('scanning', 'Detecting form fields…', {
      fieldsFilled: filled.size,
      scrollCount: scroll.scrollCount,
    });

    const inputs = await collectInputs(page);
    let progress = false;

    for (const input of inputs) {
      if (!running) break;
      const hints = [input.label, input.ariaLabel, input.name, input.placeholder];
      let key = null;
      for (const h of hints) {
        key = matchLabel(h || '', config.ocrThreshold || 55);
        if (key) break;
      }
      if (!key || filled.has(key) || !fields[key]) continue;

      setStatus(
        input.isDropdown ? 'waitingDropdown' : 'filling',
        `Filling ${key}`,
        { fieldsFilled: filled.size, fieldsTotal: fieldKeys.length, scrollCount: scroll.scrollCount }
      );

      const ok = await fillField(page, input, fields[key]);
      if (ok) {
        filled.add(key);
        progress = true;
        status.fieldsFilled = filled.size;
      }
    }

    if (filled.size >= fieldKeys.length) {
      setStatus('completed', 'All fields filled', {
        fieldsFilled: filled.size,
        fieldsTotal: fieldKeys.length,
        scrollCount: scroll.scrollCount,
      });
      break;
    }

    if (!progress) {
      setStatus('scrolling', 'Scrolling form…', {
        fieldsFilled: filled.size,
        scrollCount: scroll.scrollCount,
      });
      await scroll.scrollDown();
      status.scrollCount = scroll.scrollCount;
      retries++;
    } else {
      retries = 0;
    }
  }

  if (filled.size < fieldKeys.length && running) {
    setStatus('completed', `Filled ${filled.size}/${fieldKeys.length} fields`, {
      fieldsFilled: filled.size,
      fieldsTotal: fieldKeys.length,
      scrollCount: scroll.scrollCount,
    });
  }

  running = false;
}

export async function stopAutomation() {
  running = false;
  paused = false;
  setStatus('stopped', 'Automation stopped');
  if (context) await context.close().catch(() => {});
  if (browser) await browser.close().catch(() => {});
  context = null;
  browser = null;
  page = null;
}

export function pauseAutomation() {
  paused = true;
}

export function resumeAutomation() {
  paused = false;
}
