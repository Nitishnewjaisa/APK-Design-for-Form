# Hybrid Automation Setup Guide

## Project layout

```
form_autofill/
├── lib/automation/
│   ├── shared/      # Form engine, OCR, adapters, orchestrator
│   ├── android/     # Existing Accessibility Service bridge
│   ├── playwright/  # Dart Playwright HTTP client
│   └── windows/     # Win32/UIA stub (future)
├── automation/playwright/   # Node.js sidecar service
└── android/               # Native Kotlin (preserved)
```

## Android (APK on phone)

```powershell
flutter pub get
flutter run
```

1. Select **Android Automation**
2. Enable Accessibility in Settings
3. Fill profile → Start

## Browser / Web (Windows desktop)

Terminal 1 — Playwright service:

```powershell
cd automation/playwright
npm install
npm run install-browsers
npm start
```

Terminal 2 — Flutter app:

```powershell
cd form_autofill
flutter pub get
flutter run -d windows
```

1. Select **Browser Automation**
2. Enter form URL
3. Choose Chrome or Edge
4. Start Auto-Fill

## Hybrid OCR

1. Start Playwright sidecar (desktop)
2. On Android: enable Accessibility
3. Select **Hybrid OCR Automation**
4. Uses OCR-assisted matching + platform fallback

## Tesseract (Windows OCR)

Install Tesseract and add to PATH:

```powershell
winget install UB-Mannheim.TesseractOCR
```

## JSON profiles

Import/export via `JsonProfileDatasource` or copy `assets/profiles/example_profile.json`.
