import express from 'express';
import {
  startAutomation,
  stopAutomation,
  pauseAutomation,
  resumeAutomation,
  status,
} from './form-automation.mjs';

const app = express();
const PORT = 3939;

app.use(express.json({ limit: '10mb' }));

app.get('/health', (_, res) => res.json({ ok: true, service: 'playwright-automation' }));

app.get('/automation/status', (_, res) => res.json(status));

app.post('/automation/start', async (req, res) => {
  try {
    const config = {
      url: req.body.url,
      fields: req.body.fields || {},
      browser: req.body.browser || 'chromium',
      uploadPaths: req.body.uploadPaths || [],
      maxScrollRetries: req.body.maxScrollRetries ?? 8,
      scrollDelayMs: req.body.scrollDelayMs ?? 600,
      retryDelayMs: req.body.retryDelayMs ?? 400,
      ocrThreshold: req.body.ocrThreshold ?? 65,
      useOcrAssist: req.body.useOcrAssist ?? false,
    };
    startAutomation(config).catch((err) => {
      status.state = 'error';
      status.message = err.message;
    });
    res.json({ started: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/automation/stop', async (_, res) => {
  await stopAutomation();
  res.json({ stopped: true });
});

app.post('/automation/pause', (_, res) => {
  pauseAutomation();
  res.json({ paused: true });
});

app.post('/automation/resume', (_, res) => {
  resumeAutomation();
  res.json({ resumed: true });
});

app.listen(PORT, '127.0.0.1', () => {
  console.log(`[FormAutoFill] Playwright service listening on http://127.0.0.1:${PORT}`);
});
