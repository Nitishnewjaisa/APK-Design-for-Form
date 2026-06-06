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
  // extra debug for per-field diagnostics (consumed by Flutter Debug tab)
  debugFields: [],
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
    if (input.isFileInput) {
      return { ok: false, reason: 'isFileInput (handled separately)' };
    }

    if (!selector) {
      return { ok: false, reason: 'selector missing' };
    }

    if (input.isDropdown) {
      // Prefer label-based selection; fallback to raw value.
      try {
        await pg.selectOption(selector, { label: value });
      } catch (e1) {
        await pg.selectOption(selector, value);
      }
      return { ok: true, reason: '' };
    }

    await pg.fill(selector, value);
    return { ok: true, reason: '' };
  } catch (e) {
    return { ok: false, reason: (e && e.message) ? e.message : 'fill exception' };
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

  // reset debug container for this run
  status.debugFields = [];


  const scroll = new ScrollManager(page, {
    maxRetries: config.maxScrollRetries || 8,
    delayMs: config.scrollDelayMs || 600,
  });

  const filled = new Set();
  let retries = 0;

  // detailed per-field debug (returned to Flutter)
  const debugFields = [];


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
      if (!key) {
        debugFields.push({
          key: null,
          profileKey: null,
          status: 'SKIPPED',
          reason: 'no label match',
          usedHints: { label: input.label, ariaLabel: input.ariaLabel, name: input.name, placeholder: input.placeholder },
          inputSelector: input.selector,
        });
        continue;
      }

      if (filled.has(key)) {
        debugFields.push({
          key,
          profileKey: key,
          status: 'SKIPPED',
          reason: 'already filled',
          inputSelector: input.selector,
        });
        continue;
      }

      if (!fields[key]) {
        debugFields.push({
          key,
          profileKey: key,
          status: 'SKIPPED',
          reason: 'missing profile value',
          inputSelector: input.selector,
        });
        continue;
      }

      setStatus(
        input.isDropdown ? 'waitingDropdown' : 'filling',
        `Filling ${key}`,
        { fieldsFilled: filled.size, fieldsTotal: fieldKeys.length, scrollCount: scroll.scrollCount }
      );

      const fillRes = await fillField(page, input, fields[key]);
      if (fillRes.ok) {
        filled.add(key);
        progress = true;
        status.fieldsFilled = filled.size;
        debugFields.push({
          key,
          profileKey: key,
          status: 'SUCCESS',
          reason: '',
          inputSelector: input.selector,
          valueLength: String(fields[key] || '').length,
        });
      } else {
        debugFields.push({
          key,
          profileKey: key,
          status: 'FAILED',
          reason: fillRes.reason || 'fill failed',
          inputSelector: input.selector,
        });
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

  status.debugFields = debugFields;
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
