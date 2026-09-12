# Exquisite Corpse: iOS App Plan

This doc has two parts.

- **Part 1** is for you (Jesse). It lists every step to get the app on the App Store, in order.
- **Part 2** is for Claude. It tells Claude how to build the app with Xcode on your Mac.

## How the app will work on iOS

The game stays a web app. A thin native iOS app wraps it in a full-screen web view (`WKWebView`) and loads `index.html` from inside the app bundle. No server, no network. The "save" button hands the drawing to the native iOS share sheet so people can save to Photos, AirDrop, or text it.

This is the least work and keeps one codebase for the website and the app. The main risk is App Store guideline 4.2 ("minimum functionality"), which Apple uses to reject apps that are just a website in a box. The mitigations below (offline, bundled assets, native share sheet, proper icon, iPad support) are what usually gets a wrapped app through. If Apple still rejects it, the fallback is a native SwiftUI rewrite of the drawing screen. Do not start there.

---

# Part 1: Steps for Jesse

## Step 0. What you need

- A Mac that can run the latest Xcode. Update macOS first if the Mac App Store won't install Xcode.
- Xcode, from the Mac App Store. It is about 15 GB. Open it once after installing and let it finish "installing components."
- An iPhone with a cable, for real-device testing.
- An Apple ID with two-factor auth turned on.
- Claude Code installed on the Mac, run from inside this repo folder.
- About $99 for the Apple Developer Program.

## Step 1. Join the Apple Developer Program

1. Go to https://developer.apple.com/programs/enroll/ and sign in with your Apple ID.
2. Enroll as an **Individual**. (Enrolling as a company needs a D-U-N-S number and takes weeks. Not worth it.)
3. Pay the $99/year fee.
4. Wait for the approval email. Usually under 48 hours, sometimes minutes.
5. When approved, go to https://developer.apple.com/account and accept the license agreement. You must re-accept whenever Apple updates it, or uploads will fail.

You can do Steps 2 and 3 while you wait.

## Step 2. Decide the basics

Write these down. Claude will need them.

| Thing | Suggested value |
|---|---|
| App name on the App Store | `Exquisite Corpse` (check availability in Step 7; have a backup like `Exquisite Corpse: Draw Together`) |
| Bundle ID | `com.jessemann.exquisitecorpse` (reverse-domain style, lowercase, no dashes; permanent once published) |
| Price | Free |
| Devices | iPhone and iPad (the web app already has an iPad layout) |
| Minimum iOS | iOS 16. Old enough to cover nearly everyone, new enough to keep the code simple. |
| Category | Games, subcategory Family. Secondary: Games, Casual. |
| Age rating | Expect 4+. There is no user-generated content that leaves the device. |
| Support URL | `https://djessemann.github.io/exquisite-corpse/` |
| Privacy policy URL | `https://djessemann.github.io/exquisite-corpse/privacy.html` (Claude will write this page in Step 3) |

## Step 3. Prep the web app (Claude does this)

Tell Claude: *"Do Step 3 of docs/ios-app-plan.md."* Claude will:

1. **Vendor React.** Download the two React 18 UMD files from unpkg into a `vendor/` folder and point `index.html` at them. The app currently loads React from the internet, which will not work inside the iOS bundle and is a weak point for the PWA too.
2. **Bundle the font.** Download Space Mono Regular and Bold as `.woff2` into `fonts/`, add `@font-face` rules, and remove the Google Fonts links. The font is SIL Open Font License, so bundling is allowed. Add the `OFL.txt` license file next to it.
3. **Make the service worker conditional.** Only register `sw.js` when the page is served over http/https. Inside the iOS app the page loads from `file://` and service workers do not work there.
4. **Add a native share bridge.** In `saveToPhotos`, if `window.webkit.messageHandlers.share` exists, send the PNG as a base64 string to it. Otherwise keep the current `navigator.share` path. This is what makes "save" use the real iOS share sheet.
5. **Handle the notch and home bar.** Add `viewport-fit=cover` to the viewport meta tag and pad the top and bottom of the layout with `env(safe-area-inset-top)` and `env(safe-area-inset-bottom)`.
6. **Disable the long-press callout.** Add `-webkit-touch-callout: none` to the body CSS so long-pressing the canvas does not pop a menu.
7. **Write `privacy.html`.** A short plain-English page: the app collects no data, has no accounts, no analytics, and never sends anything off the device. It gets published with the site via GitHub Pages.
8. **Update `sw.js`** to pre-cache the new local files and bump the cache version.
9. Test the website still works, commit, push, and open a PR.

After this step, the website at GitHub Pages should look and behave the same as before, but work fully offline.

## Step 4. Create the Xcode project (you, about 5 minutes)

Claude cannot click through Xcode's "new project" dialog, so you do this once.

1. Open Xcode. Choose **File > New > Project**.
2. Pick **iOS > App**. Click Next.
3. Fill in:
   - Product Name: `ExquisiteCorpse` (no space)
   - Team: your name (appears after you sign in; see below)
   - Organization Identifier: `com.jessemann`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
   - Testing System: **None**
4. Click Next. Save it inside this repo in a folder called `ios`. Uncheck "Create Git repository" since the repo already exists.
5. If the Team menu is empty: **Xcode > Settings > Accounts > +**, sign in with your Apple ID, then go back and pick your team.
6. In the project settings, under **Signing & Capabilities**, make sure **Automatically manage signing** is checked and your team is selected. Xcode will register the bundle ID with Apple for you.
7. Quit Xcode.

Then tell Claude: *"Do Step 5 of docs/ios-app-plan.md."*

## Step 5. Build the wrapper app (Claude does this)

Claude follows Part 2 of this doc. In short, it will:

1. Replace the template `ContentView.swift` with a full-screen `WKWebView` that loads the bundled `index.html`.
2. Add the share bridge on the Swift side, which turns the base64 PNG into a `UIImage` and shows `UIActivityViewController`.
3. Add a script that copies the web files from the repo root into the app's `Web` folder, so there is one source of truth.
4. Set Info.plist keys: photo library permission text, launch screen, "no non-exempt encryption", portrait-only on iPhone, all orientations on iPad.
5. Generate the app icon from `icon.svg` as a 1024x1024 PNG and put it in the asset catalog.
6. Add a `PrivacyInfo.xcprivacy` file declaring no tracking and no data collection.
7. Build it for the iPhone simulator, run it, walk through a full game, and take screenshots.
8. Commit and push.

## Step 6. Test on your iPhone (you)

1. Plug in your iPhone. On the phone: **Settings > Privacy & Security > Developer Mode**, turn it on, restart the phone.
2. Open `ios/ExquisiteCorpse.xcodeproj` in Xcode.
3. In the toolbar, pick your iPhone as the run target.
4. Press the Play button. The first time, the phone will say the developer is untrusted. On the phone go to **Settings > General > VPN & Device Management** and trust your Apple ID.
5. Play a full game with your daughter. Test: drawing, fill, undo, eraser, pass the device, reveal, save to Photos, home. Rotate the phone. Try it on an iPad if you have one.
6. Report anything wrong to Claude. Repeat until it feels right.

## Step 7. Create the app record in App Store Connect (you, about 20 minutes)

1. Go to https://appstoreconnect.apple.com and sign in.
2. **My Apps > + > New App.**
   - Platform: iOS
   - Name: `Exquisite Corpse`. If it says the name is taken, use your backup.
   - Primary language: English (U.S.)
   - Bundle ID: pick `com.jessemann.exquisitecorpse` from the menu. (It only appears after Xcode registered it in Step 4.)
   - SKU: `exquisite-corpse-ios`
   - User access: Full Access
3. Fill in the **App Information** page: category (Games > Family, secondary Games > Casual), content rights (you own or have rights to all content), age rating questionnaire (answer No to everything; expect 4+).
4. Fill in **App Privacy**: click "Get Started," choose **"Data Not Collected."** Enter the privacy policy URL from Step 2.
5. **Pricing and Availability**: Free, all countries.
6. Save. Do not submit yet.

## Step 8. Screenshots and store text

Ask Claude for both. Claude takes simulator screenshots at the right sizes (Part 2 covers this). You need:

| Device | Size | How many |
|---|---|---|
| iPhone 6.9" (e.g. iPhone 16 Pro Max simulator) | 1320 x 2868 | 3 to 5 |
| iPad 13" (e.g. iPad Pro 13" simulator) | 2064 x 2752 | 3 to 5 |

Apple scales these down for smaller devices, so you do not need other sizes.

Good screenshots for this app: the landing screen, someone mid-drawing of a head, the "pass the device" screen, and a finished reveal. Ask Claude to draw something fun on the canvas before capturing, or draw it yourself in the simulator with the mouse.

Store text you will paste in (Claude can draft it; you are the content designer, so edit it):

- **Subtitle** (30 chars): e.g. `Pass-and-draw party game`
- **Description**: what the game is, three players, no accounts, no ads, works offline.
- **Keywords** (100 chars, comma separated): `drawing,party,game,surrealist,kids,family,doodle,pass and play`
- **Promotional text** (optional, 170 chars)
- **Support URL** and **Marketing URL** (both can be the GitHub Pages site)

## Step 9. Upload a build

Two ways. The first is easier the first time.

**Xcode way (you):**
1. Open the project in Xcode. In the toolbar, set the run target to **Any iOS Device (arm64)**.
2. **Product > Archive.** Wait a minute or two.
3. The Organizer window opens. Select the archive, click **Distribute App**, choose **App Store Connect**, then **Upload**. Accept the defaults on every screen.
4. Wait for the "upload successful" message. Then wait 10 to 30 minutes for the email saying the build finished processing.

**Command-line way (Claude):** see Part 2. Uses `xcodebuild -exportArchive` with `destination: upload`. Same result.

## Step 10. TestFlight (optional but smart)

1. In App Store Connect, click **TestFlight**. Your build shows up once processed.
2. Add yourself and your wife as internal testers. Install the TestFlight app on your phones.
3. Play it for a few days. This is the build Apple will review, so make sure it is the real thing.

## Step 11. Submit for review

1. In App Store Connect, open your app, version **1.0**.
2. Upload screenshots. Paste in the description, keywords, subtitle, support URL.
3. Under **Build**, click + and pick the processed build.
4. **App Review Information**: your name, phone, email. No sign-in needed, so leave the demo account blank. In **Notes**, paste:

   > Exquisite Corpse is a pass-and-play drawing game for three people on one device. Each player draws one section (head, body, legs) without seeing the others, then the full drawing is revealed. There are no accounts, no network features, no ads, and no data collection. Drawings stay on the device unless the user saves or shares them via the iOS share sheet. The app works fully offline.

5. **Version Release**: choose "Manually release this version" so you control launch day, or "Automatically release."
6. Click **Add for Review**, then **Submit to App Review**.
7. Review usually takes 1 to 3 days. You get an email either way.

## Step 12. If Apple rejects it

Read the rejection carefully. Reply in Resolution Center if you disagree; reviewers do change their minds. Common ones for this kind of app:

- **Guideline 4.2, minimum functionality** ("your app is a website in a wrapper"): Reply explaining it is a complete offline game with no web dependency, native share, and iPad support. If they still say no, the next move is Claude rewriting the drawing screen in native SwiftUI with `PencilKit` or `Canvas`. That is a real project, roughly a week of Claude time with your testing.
- **Guideline 2.1, crashes or bugs**: they will attach a screenshot and device. Give it to Claude.
- **Guideline 5.1.1, missing permission string**: the photo library text is missing or vague. Claude fixes Info.plist.
- **Screenshot or metadata problems**: fix and resubmit; no new build needed.

## Step 13. After launch

- Every update: bump the version (1.0 to 1.1) and build number in Xcode, re-archive, upload, add "What's New" text, submit. Updates go through review too.
- Apple requires apps to be built with the current SDK each year, starting every April. Keep Xcode updated.
- Renew the developer program yearly or the app comes off the store.

---

# Part 2: Instructions for Claude (Xcode on macOS)

You are running on Jesse's Mac inside this repo. Your job is the iOS wrapper described above. Read Part 1 first so you know what Jesse has and has not done yet.

## What you can and cannot do

You **can**: read and write every file, run `xcodebuild`, `xcrun simctl`, `git`, `swift`, and shell scripts, build and run in the simulator, take screenshots, archive and upload.

You **cannot**: click in Xcode's GUI, sign into an Apple ID, accept Apple agreements, fill in App Store Connect forms, or trust a device. When a step needs one of these, stop and tell Jesse exactly what to click. Do not guess or work around it.

## Ground rules

- **Build before you say it works.** A change is not done until `xcodebuild` succeeds and you have run it in the simulator.
- **Keep the root `index.html` as the single source of truth.** Never fork a separate copy for iOS. The sync script copies it into the app at build time.
- **Do not hand-edit `project.pbxproj`** unless there is no other way. Xcode 16+ projects use synchronized folders, so adding a file to the target folder on disk adds it to the project. Info.plist keys can be set in the pbxproj as `INFOPLIST_KEY_*` build settings, or via a real `Info.plist` file. Prefer a real `Info.plist` file if you need more than a couple of keys: set `GENERATE_INFOPLIST_FILE = NO` and `INFOPLIST_FILE = ExquisiteCorpse/Info.plist` in the pbxproj (that is an acceptable small hand edit).
- **Keep it minimal.** No Capacitor, no CocoaPods, no Swift packages, no fastlane. Plain Swift, plain WebKit.
- **Never commit signing secrets, provisioning profiles, or API keys.** Add `ios/build/`, `ios/*.xcarchive`, `xcuserdata/`, and `*.ipa` to `.gitignore`.
- When a build fails, read the full error, fix the cause, and rebuild. Do not retry the same command hoping it changes.

## Sanity checks to run first

```bash
xcode-select -p                 # should print /Applications/Xcode.app/Contents/Developer
xcodebuild -version
xcrun simctl list devices available | head -40
ls ios/                         # ExquisiteCorpse.xcodeproj should exist (Jesse's Step 4)
```

If `xcode-select -p` points at CommandLineTools, run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` (this needs Jesse's password; ask). If the xcodeproj does not exist, stop and send Jesse to Step 4.

## Target file layout

```
ios/
  ExquisiteCorpse.xcodeproj/
  ExportOptions.plist              # for command-line upload
  sync-web.sh                      # copies web files from repo root into Web/
  ExquisiteCorpse/
    ExquisiteCorpseApp.swift       # @main, unchanged from template except body
    ContentView.swift              # WebView().ignoresSafeArea()
    WebView.swift                  # UIViewRepresentable around WKWebView + share bridge
    Info.plist
    PrivacyInfo.xcprivacy
    Assets.xcassets/
      AppIcon.appiconset/          # 1024x1024 PNG, no alpha
    Web/                           # generated by sync-web.sh, committed
      index.html
      react.production.min.js
      react-dom.production.min.js
      SpaceMono-Regular.woff2
      SpaceMono-Bold.woff2
      OFL.txt
```

Keep `Web/` flat. Xcode flattens resource folders into the bundle root anyway, so relative paths with subfolders in `index.html` would break inside the app. The sync script should rewrite `vendor/` and `fonts/` paths to flat filenames, or better, keep the root repo layout flat too so no rewriting is needed.

## The web view (WebView.swift)

Requirements, not code. Write the code yourself and build it.

- `UIViewRepresentable` wrapping `WKWebView`.
- Configuration: add a `WKUserContentController` with a script message handler named `share`. The coordinator implements `WKScriptMessageHandler`.
- Load with `webView.loadFileURL(indexURL, allowingReadAccessTo: indexURL.deletingLastPathComponent())` where `indexURL = Bundle.main.url(forResource: "index", withExtension: "html")`.
- `webView.scrollView.isScrollEnabled = false`, `bounces = false`, `contentInsetAdjustmentBehavior = .never`. Inner `overflow: auto` divs in the page still scroll; that is fine.
- `webView.isOpaque = false`, background white. `allowsLinkPreview = false`. `allowsBackForwardNavigationGestures = false`.
- The SwiftUI view uses `.ignoresSafeArea()` so the web page gets the whole screen. The page pads itself with `env(safe-area-inset-*)`.
- Share handler: message body is a base64 string (no `data:image/png;base64,` prefix; strip it if present). Decode to `Data`, make a `UIImage`, present a `UIActivityViewController` with `[image]` from the top view controller. On iPad set `popoverPresentationController.sourceView` to the web view and `sourceRect` to the bottom center, or it will crash.
- Do not use `loadHTMLString`. It breaks relative paths and `getImageData`.

## The JS side (root index.html, done in Step 3)

In `saveToPhotos`, before the `navigator.share` check:

```js
var bridge = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.share;
if (bridge) { bridge.postMessage(pc.toDataURL("image/png").split(",")[1]); return; }
```

And wrap the service worker registration in `if (location.protocol.startsWith("http"))`.

## Info.plist keys

| Key | Value |
|---|---|
| `NSPhotoLibraryAddUsageDescription` | `Lets you save your finished drawing to Photos.` |
| `ITSAppUsesNonExemptEncryption` | `false` |
| `UILaunchScreen` | empty dict (gives a plain system-background launch screen) |
| `UISupportedInterfaceOrientations` | Portrait only |
| `UISupportedInterfaceOrientations~ipad` | all four |
| `UIRequiresFullScreen` | `true` on iPad (skips multitasking layout work) |
| `CFBundleDisplayName` | `Exquisite Corpse` |
| `UIStatusBarStyle` | `UIStatusBarStyleDarkContent` |
| `UIViewControllerBasedStatusBarAppearance` | `false` |

Also set in build settings: `IPHONEOS_DEPLOYMENT_TARGET = 16.0`, `TARGETED_DEVICE_FAMILY = "1,2"`, `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 1`.

## App icon

```bash
# 1024x1024, no alpha channel. Apple rejects icons with transparency.
rsvg-convert -w 1024 -h 1024 icon.svg -o /tmp/icon.png   # brew install librsvg
# or if rsvg-convert is missing:
qlmanage -t -s 1024 -o /tmp icon.svg && mv /tmp/icon.svg.png /tmp/icon.png
sips -s format png --matchTo '/System/Library/ColorSync/Profiles/sRGB Profile.icc' /tmp/icon.png --out ios/ExquisiteCorpse/Assets.xcassets/AppIcon.appiconset/icon-1024.png
```

Check `sips -g hasAlpha` prints `no`. If it prints `yes`, flatten onto white with `sips` or ImageMagick. Update `Contents.json` in the appiconset to point at the file with `"platform": "ios", "size": "1024x1024"` (single-size icon; Xcode 14+ derives the rest). The current icon is a thin squiggle on white. Consider asking Jesse whether it wants a thicker stroke or a colored background so it reads at 60px on a home screen.

## PrivacyInfo.xcprivacy

A plist with `NSPrivacyTracking = false`, empty `NSPrivacyTrackingDomains`, empty `NSPrivacyCollectedDataTypes`, empty `NSPrivacyAccessedAPITypes`. Nothing in this app touches a required-reason API, so the last array stays empty.

## Build and run in the simulator

```bash
cd ios
./sync-web.sh

# find a device
xcrun simctl list devices available | grep -i "iphone 16 pro max"

# build
xcodebuild -project ExquisiteCorpse.xcodeproj -scheme ExquisiteCorpse \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -derivedDataPath build build 2>&1 | tail -30

# run
xcrun simctl boot "iPhone 16 Pro Max" 2>/dev/null || true
open -a Simulator
APP=$(find build/Build/Products -name "ExquisiteCorpse.app" | head -1)
xcrun simctl install booted "$APP"
xcrun simctl launch booted com.jessemann.exquisitecorpse
```

Pipe build output through `tail` or `grep -E "error|warning|BUILD"`; the full log is thousands of lines. If `xcpretty` is installed, use it.

Then look at it. Take a screenshot and read it with your image tool:

```bash
xcrun simctl io booted screenshot /tmp/shot.png
```

Walk through a full game. You can drive taps with `xcrun simctl` only in limited ways, so for real interaction ask Jesse to click through in the Simulator window, or automate with a short XCUITest only if it becomes necessary. At minimum confirm: the landing screen renders with the right font, tapping play opens the canvas, the canvas fills the width, and no white gap sits under the status bar or above the home bar.

Read the web view's console for JS errors: in Safari on the Mac, **Develop > Simulator > ExquisiteCorpse > index.html**. This needs Jesse to enable Safari's Develop menu once (Safari > Settings > Advanced). Ask them if you need it.

## Screenshots for the App Store

```bash
for d in "iPhone 16 Pro Max" "iPad Pro 13-inch (M4)"; do
  xcrun simctl boot "$d" 2>/dev/null || true
  xcrun simctl install "$d" "$APP"
  xcrun simctl launch "$d" com.jessemann.exquisitecorpse
  sleep 3
  xcrun simctl io "$d" screenshot "screenshots/$(echo "$d" | tr ' ' '-')-landing.png"
done
```

Device names change with each Xcode. Use whatever `simctl list` shows for the largest iPhone and the 13-inch iPad. Verify pixel sizes with `sips -g pixelWidth -g pixelHeight`. iPhone must be 1320x2868 (or 1290x2796); iPad must be 2064x2752. If Jesse wants a drawing in the shot, they draw it in the Simulator with the mouse, then you capture.

## Archive and upload from the command line

Only after Jesse has done Step 4 (signing set up in Xcode) and Step 7 (app record exists). Both must be true or the upload fails with an unhelpful error.

`ios/ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>upload</string>
  <key>signingStyle</key><string>automatic</string>
  <key>teamID</key><string>TEAM_ID_HERE</string>
</dict>
</plist>
```

Get the team ID from `xcodebuild -showBuildSettings | grep DEVELOPMENT_TEAM`.

```bash
cd ios
./sync-web.sh
xcodebuild -project ExquisiteCorpse.xcodeproj -scheme ExquisiteCorpse \
  -destination 'generic/platform=iOS' -configuration Release \
  -archivePath build/ExquisiteCorpse.xcarchive archive -allowProvisioningUpdates 2>&1 | tail -20

xcodebuild -exportArchive -archivePath build/ExquisiteCorpse.xcarchive \
  -exportOptionsPlist ExportOptions.plist -exportPath build/export \
  -allowProvisioningUpdates 2>&1 | tail -20
```

`-allowProvisioningUpdates` lets xcodebuild use the Apple ID Jesse signed into Xcode. If it prompts for a password or fails with a keychain error, fall back to telling Jesse to do the Xcode Organizer upload in Step 9. That path always works.

Before every upload, bump `CURRENT_PROJECT_VERSION`. App Store Connect rejects a build number it has seen before.

## Definition of done for the wrapper

- [ ] `xcodebuild` succeeds for simulator and for `generic/platform=iOS` with zero errors.
- [ ] Landing screen renders in Space Mono, not a fallback font.
- [ ] Full game plays through in the simulator on iPhone and iPad.
- [ ] Save shows the iOS share sheet with "Save Image" in it, and saving works on a real device (Jesse tests).
- [ ] No content hidden under the status bar or home indicator.
- [ ] App works in Airplane Mode on a real device.
- [ ] App icon shows on the home screen, not a blank grid.
- [ ] Rotating an iPhone does nothing; rotating an iPad relayouts.
- [ ] `git status` is clean, build products are ignored, everything is pushed.
