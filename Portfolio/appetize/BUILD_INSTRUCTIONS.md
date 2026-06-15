# Appetize.io Build & Upload Instructions

## One-time setup

1. Create a free account at https://appetize.io
2. Keep this file updated with the public app URL after each upload.

## Building the Simulator .app

Run this in Terminal (takes ~2 min on first build):

```bash
xcodebuild \
  -scheme QuakeSense \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest' \
  -derivedDataPath /tmp/QuakeSense-build \
  build
```

The `.app` will be at:
```
/tmp/QuakeSense-build/Build/Products/Debug-iphonesimulator/QuakeSense.app
```

## Zipping the .app

```bash
cd /tmp/QuakeSense-build/Build/Products/Debug-iphonesimulator/
zip -r ~/Desktop/QuakeSense.app.zip QuakeSense.app
```

## Uploading to Appetize

1. Go to https://appetize.io → "Upload"
2. Drop `QuakeSense.app.zip`
3. Settings:
   - Device: iPhone 15 Pro
   - OS: iOS 17 (or latest available)
   - Orientation: Portrait
   - Autoplay: Off
4. Click "Upload"
5. Copy the public URL — paste it into `APPETIZE_URL` below.

## Current public URL

```
APPETIZE_URL=https://appetize.io/app/YOUR_APP_KEY_HERE
```

## Embed snippet for personal website

```html
<iframe
  src="https://appetize.io/embed/YOUR_APP_KEY_HERE?device=iphone15pro&osVersion=17&scale=75&autoplay=false&orientation=portrait"
  width="390"
  height="844"
  frameborder="0"
  scrolling="no"
  style="border-radius:40px; box-shadow:0 24px 80px rgba(0,0,0,0.25);"
></iframe>
```

> Note: CoreMotion tilt and CoreHaptics are not available in Appetize (Simulator limitation).
> Menu, Onboarding, and Room Selection play perfectly. Gameplay works but without real tilt control.
