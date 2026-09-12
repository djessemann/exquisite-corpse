# Exquisite Corpse: iOS App Plan

This doc has two parts.

- **Part 1** is for you (Jesse). It lists every step to get the app on the App Store, in order.
- **Part 2** is for Claude. It says how to build the native app with Xcode on your Mac.

The behavior to rebuild is written out in `docs/ux-spec.md`. That spec is the contract. The website keeps running as is; nothing in this plan touches it.

## What is being built

A native iOS app in **Swift and SwiftUI**. No web view, no JavaScript, no React, no server. It works fully offline. The game, screens, tools, fill, undo, pass-the-device flow, and save-to-Photos all match the web app exactly. The code is written fresh for iOS. The only things carried over from the web app are the experience (via the spec), the Space Mono font, the color values, the squiggle and icon paths, and the flood-fill rules.

Why native and not a wrapper: it is what Apple prefers, it removes the "minimum functionality" rejection risk, drawing latency is better, and there is no dependency on a website.

Rough effort: about 700 to 1000 lines of Swift. Claude can write it in a few sessions. Most of the calendar time is you testing on a real phone and Apple's review.

---

# Part 1: Steps for Jesse

## Step 0. What you need

- A Mac that can run the latest Xcode. Update macOS first if the Mac App Store refuses to install Xcode.
- Xcode, from the Mac App Store. About 15 GB. Open it once and let it finish "installing components."
- An iPhone with a cable, for real testing. An iPad too if you have one.
- An Apple ID with two-factor auth turned on.
- Claude Code installed on the Mac, run from inside this repo folder.
- $99 for the Apple Developer Program.

## Step 1. Join the Apple Developer Program

1. Go to https://developer.apple.com/programs/enroll/ and sign in with your Apple ID.
2. Enroll as an **Individual**. (Company enrollment needs a D-U-N-S number and takes weeks.)
3. Pay $99/year.
4. Wait for the approval email. Usually under 48 hours.
5. When approved, go to https://developer.apple.com/account and accept the license agreement. Re-accept whenever Apple updates it, or uploads fail.

Do Steps 2 through 5 while you wait. Only Steps 7 onward need the paid account.

## Step 2. Decide the basics

| Thing | Suggested value |
|---|---|
| App name on the App Store | `Exquisite Corpse` (check availability in Step 7; have a backup like `Exquisite Corpse: Draw Together`) |
| Bundle ID | `com.jessemann.exquisitecorpse` (permanent once published) |
| Price | Free |
| Devices | iPhone and iPad |
| Minimum iOS | iOS 16 |
| Category | Games > Family. Secondary: Games > Casual. |
| Age rating | Expect 4+ |
| Support URL | `https://djessemann.github.io/exquisite-corpse/` |
| Privacy policy URL | `https://djessemann.github.io/exquisite-corpse/privacy.html` (Claude writes it in Step 3) |

## Step 3. Prep work Claude can do before Xcode exists

Tell Claude: *"Do Step 3 of docs/ios-app-plan.md."* Claude will:

1. Write `privacy.html` at the repo root: the app collects no data, has no accounts, no analytics, and never sends anything off the device. GitHub Pages publishes it automatically.
2. Download Space Mono Regular and Bold as `.ttf` into `ios/Fonts/` along with its `OFL.txt` license. (SIL Open Font License; bundling is allowed.)
3. Generate the 1024x1024 app icon PNG from `icon.svg` into `ios/Icon/` and check it has no alpha channel. Also ask you whether the thin squiggle reads at home-screen size or whether you want a bolder version. Your call.
4. Re-read `docs/ux-spec.md` against `index.html` and fix anything the spec gets wrong. The spec was written from the code once; a second pass catches mistakes.
5. Commit and push.

## Step 4. Create the Xcode project (you, about 5 minutes)

Claude cannot click through Xcode's new-project dialog, so you do this once.

1. Open Xcode. **File > New > Project.**
2. Pick **iOS > App**. Next.
3. Fill in:
   - Product Name: `ExquisiteCorpse` (no space)
   - Team: your name (see step 5 if the menu is empty)
   - Organization Identifier: `com.jessemann`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
   - Testing System: **None**
4. Next. Save it inside this repo in the `ios` folder. Uncheck "Create Git repository."
5. If Team is empty: **Xcode > Settings > Accounts > +**, sign in with your Apple ID, then go back and pick your team.
6. Project settings > **Signing & Capabilities**: check **Automatically manage signing** and pick your team. Xcode registers the bundle ID with Apple for you.
7. Quit Xcode.

Then tell Claude: *"Do Step 5 of docs/ios-app-plan.md."*

## Step 5. Build the app (Claude, in milestones)

Claude follows Part 2. It builds in this order and stops after each milestone so you can look:

| Milestone | What you should see |
|---|---|
| M1. Skeleton | App launches to the landing screen in Space Mono with squiggles and a "play" button. Tapping play shows an empty drawing screen. |
| M2. Drawing | You can draw with the pen. Strokes are smooth, round, and the right width. One finger only. |
| M3. Tools | Swatches, sizes, eraser, fill, and undo all behave per the spec. |
| M4. Flow | Done/sure?, pass the device, the guide strip from the previous section, all three turns. |
| M5. Reveal | The stitched drawing shows. Save opens the share sheet. Home/sure? returns to landing. |
| M6. iPad and polish | iPad sizes, rotation rules, safe areas, launch screen, icon. |
| M7. Store assets | Screenshots at the right sizes, draft store text. |

After each milestone Claude commits and pushes and tells you what to test.

## Step 6. Test on your iPhone (you)

1. On the phone: **Settings > Privacy & Security > Developer Mode**, turn on, restart.
2. Plug it in. Open `ios/ExquisiteCorpse.xcodeproj` in Xcode. Pick your iPhone in the toolbar. Press Play.
3. First time: the phone says the developer is untrusted. **Settings > General > VPN & Device Management**, trust your Apple ID.
4. Play a real game with your family. Compare it side by side with the website on the same phone. Anything that feels different goes back to Claude.
5. Turn on Airplane Mode and play again. It must work.

Do this after M3 and again after M5. Do not wait until the end.

## Step 7. Create the app record in App Store Connect (you, about 20 minutes)

1. https://appstoreconnect.apple.com, sign in.
2. **My Apps > + > New App.** Platform iOS. Name `Exquisite Corpse` (or backup). Primary language English (U.S.). Bundle ID from the menu (appears after Step 4). SKU `exquisite-corpse-ios`. Full Access.
3. **App Information**: category, content rights (you own all content), age rating questionnaire (No to everything).
4. **App Privacy**: "Data Not Collected." Enter the privacy policy URL.
5. **Pricing and Availability**: Free, all countries.
6. Save. Do not submit yet.

## Step 8. Screenshots and store text

Claude takes simulator screenshots (Part 2). Required:

| Device | Size | How many |
|---|---|---|
| iPhone 6.9" (largest iPhone simulator) | 1320 x 2868 | 3 to 5 |
| iPad 13" | 2064 x 2752 | 3 to 5 |

Apple scales these for smaller devices. Good shots: landing, mid-drawing of a head, pass the device, a finished reveal. Draw something in the simulator with the mouse first, then have Claude capture.

Store text (Claude drafts, you edit):

- **Subtitle** (30 chars): e.g. `Pass-and-draw party game`
- **Description**: what it is, three players one device, no accounts, no ads, offline.
- **Keywords** (100 chars): `drawing,party,game,surrealist,kids,family,doodle,pass and play`
- **Support URL** and **Marketing URL**: the GitHub Pages site.

## Step 9. Upload a build

**Xcode way (you, easiest the first time):**
1. Open the project. Set run target to **Any iOS Device (arm64)**.
2. **Product > Archive.**
3. In Organizer: select the archive, **Distribute App > App Store Connect > Upload**. Accept defaults.
4. Wait for "upload successful," then 10 to 30 minutes for the processing email.

**Command-line way (Claude):** Part 2 has it. Same result.

## Step 10. TestFlight (optional but smart)

1. App Store Connect > **TestFlight**. Add yourself and your wife as internal testers.
2. Install the TestFlight app on your phones and play for a few days. This exact build is what Apple reviews.

## Step 11. Submit for review

1. App Store Connect > your app > version **1.0**.
2. Upload screenshots. Paste description, keywords, subtitle, URLs.
3. **Build**: + and pick the processed build.
4. **App Review Information**: your contact info. No demo account. Notes:

   > Exquisite Corpse is a pass-and-play drawing game for three people on one device. Each player draws one section (head, body, legs) without seeing the others, then the full drawing is revealed. Fully native SwiftUI, no accounts, no network, no ads, no data collection. Drawings stay on the device unless the user shares them via the iOS share sheet. Works offline.

5. **Version Release**: manual or automatic.
6. **Add for Review**, then **Submit to App Review**. Expect 1 to 3 days.

## Step 12. If Apple rejects it

Read the message. Reply in Resolution Center if you disagree; reviewers do reverse. Likely ones:

- **2.1, crashes or bugs**: they attach a screenshot and device. Give it to Claude.
- **5.1.1, permission string**: the Photos permission text is missing or vague. Claude fixes Info.plist.
- **Metadata or screenshots**: fix in App Store Connect, resubmit, no new build.
- **4.3, spam or duplicate**: only if there are many "exquisite corpse" apps already. Reply describing what is different. Rare for a free, original game.

## Step 13. After launch

- Updates: bump version and build number, archive, upload, add "What's New," submit. Updates go through review too.
- Apple requires the current-year SDK each April. Keep Xcode updated.
- Renew the developer program yearly or the app comes down.

---

# Part 2: Instructions for Claude (Xcode on macOS)

You are running on Jesse's Mac inside this repo. You are building a native SwiftUI port of the web game. `docs/ux-spec.md` is the contract. `index.html` is the reference when the spec is unclear. Read both before writing Swift.

## What you can and cannot do

You **can**: read and write every file, run `xcodebuild`, `xcrun simctl`, `git`, `swift`, and shell scripts, build and run in the simulator, take screenshots and look at them, archive and upload.

You **cannot**: click in Xcode's GUI, sign into an Apple ID, accept Apple agreements, fill in App Store Connect forms, or trust a device. When a step needs one of these, stop and tell Jesse exactly what to click.

## Ground rules

- **Port the experience, not the code.** Do not transliterate the JavaScript. Write idiomatic Swift that produces the behavior in the spec. Where the spec gives numbers, use them exactly.
- **No dependencies.** No Swift packages, CocoaPods, Capacitor, fastlane, or web views. SwiftUI, UIKit where needed, CoreGraphics, Photos. That is all.
- **Build before you say it works.** A milestone is not done until `xcodebuild` succeeds with zero warnings you introduced, the app runs in the simulator, and you have looked at a screenshot of it.
- **Do not hand-edit `project.pbxproj`** except for small build-setting changes named below. Xcode 16+ projects use synchronized folders: adding a `.swift` file to the target folder on disk adds it to the project.
- **Never commit signing secrets, provisioning profiles, or API keys.** `.gitignore` gets `ios/build/`, `*.xcarchive`, `xcuserdata/`, `*.ipa`, `DerivedData/`.
- When a build fails, read the whole error, fix the cause, rebuild. Do not rerun the same command hoping.
- Stop at the end of every milestone in Step 5's table. Commit, push, and tell Jesse what to test.

## Sanity checks to run first

```bash
xcode-select -p          # /Applications/Xcode.app/Contents/Developer
xcodebuild -version
xcrun simctl list devices available | head -40
ls ios/ExquisiteCorpse.xcodeproj   # must exist (Jesse's Step 4)
```

If `xcode-select -p` points at CommandLineTools, ask Jesse to run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`. If the xcodeproj is missing, send Jesse to Step 4.

## Target file layout

```
ios/
  ExquisiteCorpse.xcodeproj/
  ExportOptions.plist                  # for command-line upload
  Fonts/                               # source assets, copied into the target below
  Icon/
  ExquisiteCorpse/
    ExquisiteCorpseApp.swift           # @main
    Info.plist
    PrivacyInfo.xcprivacy
    Assets.xcassets/AppIcon.appiconset/
    Fonts/SpaceMono-Regular.ttf, SpaceMono-Bold.ttf, OFL.txt
    Theme.swift                        # colors, font helpers, phone/iPad metrics
    Model/
      Palette.swift                    # the 10 colors, 3 sizes, canvas constants
      Tool.swift                       # enum pen/eraser/fill + the transition rules
      Operation.swift                  # stroke and fill value types
      CanvasBitmap.swift               # CGContext bitmap: draw stroke, flood fill, redraw, snapshot
      GameState.swift                  # ObservableObject: screen, turn, sections, tool state, ops, confirm flags
    Views/
      RootView.swift                   # switches on screen
      LandingView.swift
      DrawingView.swift
      TransitionView.swift
      RevealView.swift
      DrawingCanvasView.swift          # UIViewRepresentable, single-touch, feeds the bitmap
      SketchButton.swift               # the bordered button with 30ms invert
      Swatch.swift, SizeButton.swift, FillButton.swift
      Squiggles.swift                  # the two squiggle paths as Shapes
      ToolIcons.swift                  # pencil and bucket icon paths
      ShareSheet.swift                 # UIActivityViewController wrapper
```

Adjust names freely. Keep model separate from views so the bitmap and fill logic can be unit-tested if that ever becomes useful.

## Architecture notes

**Bitmap, not vector.** The drawing surface is a `CGContext` bitmap in RGBA8, sized 600 x 420 times a scale factor (start at 2). All coordinates are in 600 x 420 logical units; the context is scaled once. Strokes are drawn into it segment by segment as touches arrive. Flood fill reads and writes its pixel buffer directly. This matches the spec's undo and fill semantics exactly and is fast enough.

**Display.** The canvas view is a `UIView` subclass inside `UIViewRepresentable`. It sets `isMultipleTouchEnabled = false`, tracks the one active `UITouch`, and sets `layer.contents` to the bitmap's `CGImage` after each change (or draws it in `draw(_:)`). `contentMode = .scaleAspectFit` is not needed if the view's frame is already the 10:7 size, which SwiftUI enforces with `aspectRatio(600/420, contentMode: .fit)`.

**Touches.** `touchesBegan`: if a touch is already active, ignore. Map the point to logical units by `bitmapSize / bounds.size`. If tool is fill, run the fill and append the op if it changed anything. Otherwise start a stroke. `touchesMoved`: only for the active touch; append the point, draw the last segment. `touchesEnded` and `touchesCancelled`: commit if 2+ points, clear the active touch. Report "touch began" up to the state so the done button's "sure?" resets.

**State.** One `GameState` `ObservableObject` owns everything in the spec's "Tools" and "Screens" sections. Views read it and call intent methods (`tapSwatch(color)`, `tapSize(size)`, `tapFill()`, `undo()`, `tapDone()`, `tapHome()`, `tapSave()`, `play()`, `ready()`). Put the tool transition rules in these methods so they are in one place and match the spec table.

**Sections and composite.** A captured section is a `CGImage` from the bitmap. The composite is built in a fresh `CGContext` of 600 x 1210 logical units at the same scale. The padded save version adds 50 on each side. Convert to `UIImage` for display and for sharing.

**Share.** Use `UIActivityViewController` with `[UIImage]` via a `UIViewControllerRepresentable`, presented with `.sheet`. On iPad set `popoverPresentationController.sourceView` and `sourceRect`. ("Save Image" in the sheet triggers the Photos permission prompt, which is why Info.plist needs the usage string.) `ShareLink` also works on iOS 16 if you prefer it; either is fine as long as the sheet shows "Save Image."

**Fonts.** Add both `.ttf` files to the target and list them under `UIAppFonts` in Info.plist. Use `Font.custom("SpaceMono-Regular", size:)`. Verify the PostScript name with `fc-scan` or by loading in the simulator and checking `UIFont.familyNames`. A silent fallback to system font is the most common mistake here; the landing screenshot will show it.

**Phone vs iPad.** The spec's `phone / iPad` values switch at 768pt width. Use `GeometryReader` at the root (or `horizontalSizeClass`, but the width rule is what the web app uses) and pass a `Metrics` struct down. Do not sprinkle `if isPad` through every view; put both values in one table.

**Squiggles and icons.** Convert the SVG path strings in the spec to `Path` with `move`, `addCurve`, `addLine`, `addQuadCurve`. They are short. Keep the original viewBox and use `.scaledToFit()` inside a frame.

## Info.plist keys

| Key | Value |
|---|---|
| `NSPhotoLibraryAddUsageDescription` | `Lets you save your finished drawing to Photos.` |
| `ITSAppUsesNonExemptEncryption` | `false` |
| `UILaunchScreen` | empty dict (plain white launch) |
| `UIAppFonts` | `SpaceMono-Regular.ttf`, `SpaceMono-Bold.ttf` |
| `UISupportedInterfaceOrientations` | Portrait only |
| `UISupportedInterfaceOrientations~ipad` | all four |
| `UIRequiresFullScreen` | `true` |
| `UIUserInterfaceStyle` | `Light` |
| `CFBundleDisplayName` | `Exquisite Corpse` |
| `UIStatusBarStyle` | `UIStatusBarStyleDarkContent` |
| `UIViewControllerBasedStatusBarAppearance` | `false` |

Xcode's template generates Info.plist from build settings. To use a real file: in the pbxproj set `GENERATE_INFOPLIST_FILE = NO` and `INFOPLIST_FILE = ExquisiteCorpse/Info.plist` for both Debug and Release. That is an acceptable hand edit.

Build settings: `IPHONEOS_DEPLOYMENT_TARGET = 16.0`, `TARGETED_DEVICE_FAMILY = "1,2"`, `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 1`.

## App icon

```bash
rsvg-convert -w 1024 -h 1024 icon.svg -o ios/Icon/icon-1024.png      # brew install librsvg
# or without Homebrew:
qlmanage -t -s 1024 -o ios/Icon icon.svg && mv ios/Icon/icon.svg.png ios/Icon/icon-1024.png
sips -g hasAlpha ios/Icon/icon-1024.png     # must say "no"; if "yes", flatten onto white
```

Copy it into `Assets.xcassets/AppIcon.appiconset/` and set `Contents.json` to a single 1024x1024 iOS entry.

## PrivacyInfo.xcprivacy

`NSPrivacyTracking = false`, and empty arrays for `NSPrivacyTrackingDomains`, `NSPrivacyCollectedDataTypes`, `NSPrivacyAccessedAPITypes`. Nothing here touches a required-reason API.

## Build and run in the simulator

```bash
cd ios
xcrun simctl list devices available | grep -iE "iphone 1[6-9] pro max|ipad pro 13"

xcodebuild -project ExquisiteCorpse.xcodeproj -scheme ExquisiteCorpse \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -derivedDataPath build build 2>&1 | grep -E "error|warning|BUILD" 

xcrun simctl boot "iPhone 16 Pro Max" 2>/dev/null || true
open -a Simulator
APP=$(find build/Build/Products -name "ExquisiteCorpse.app" | head -1)
xcrun simctl install booted "$APP"
xcrun simctl launch booted com.jessemann.exquisitecorpse
sleep 2
xcrun simctl io booted screenshot /tmp/shot.png   # then open the PNG and look at it
```

Device names change with each Xcode; use whatever `simctl list` shows. Pipe build output through `grep` or `tail`; the raw log is thousands of lines.

You cannot draw in the simulator from the command line. To exercise drawing, ask Jesse to draw with the mouse in the Simulator window, or write a small XCTest against `CanvasBitmap` (stroke, fill, undo, redraw) which needs no UI at all. The second is worth doing at M2 and M3: it is the fastest way to prove the fill tolerance and undo order match the spec.

Console output from the app: `xcrun simctl launch --console booted com.jessemann.exquisitecorpse`, or `log stream --predicate 'process == "ExquisiteCorpse"'`.

## Screenshots for the App Store (M7)

```bash
mkdir -p screenshots
for d in "iPhone 16 Pro Max" "iPad Pro 13-inch (M4)"; do
  xcrun simctl boot "$d" 2>/dev/null || true
  xcrun simctl install "$d" "$APP"
  xcrun simctl launch "$d" com.jessemann.exquisitecorpse
  sleep 3
  xcrun simctl io "$d" screenshot "screenshots/$(echo "$d" | tr ' ' '-')-landing.png"
done
sips -g pixelWidth -g pixelHeight screenshots/*.png
```

iPhone must be 1320x2868 (or 1290x2796). iPad must be 2064x2752. For mid-game shots, Jesse draws in the Simulator, then you capture.

## Archive and upload from the command line

Only after Step 4 (signing) and Step 7 (app record) are both done.

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

Team ID: `xcodebuild -showBuildSettings | grep DEVELOPMENT_TEAM`.

```bash
cd ios
xcodebuild -project ExquisiteCorpse.xcodeproj -scheme ExquisiteCorpse \
  -destination 'generic/platform=iOS' -configuration Release \
  -archivePath build/ExquisiteCorpse.xcarchive archive -allowProvisioningUpdates 2>&1 | tail -20

xcodebuild -exportArchive -archivePath build/ExquisiteCorpse.xcarchive \
  -exportOptionsPlist ExportOptions.plist -exportPath build/export \
  -allowProvisioningUpdates 2>&1 | tail -20
```

If it prompts for a password or fails on the keychain, tell Jesse to use the Xcode Organizer path in Step 9. Bump `CURRENT_PROJECT_VERSION` before every upload; App Store Connect refuses a repeated build number.

## Definition of done

- [ ] Builds for simulator and for `generic/platform=iOS` with zero errors.
- [ ] Every screen uses Space Mono (check a screenshot; system font is the usual failure).
- [ ] Every row in `docs/ux-spec.md` under "Tools, and the rules between them" behaves as written. Walk the table.
- [ ] Fill next to an anti-aliased stroke edge leaves no halo.
- [ ] Undo after a fill restores exactly the previous picture.
- [ ] Second finger during a stroke is ignored.
- [ ] Guide strip from the previous section appears and survives undo.
- [ ] Composite lines up with no seam or doubled strip.
- [ ] Share sheet shows "Save Image" and saving works on a real device (Jesse).
- [ ] Airplane Mode: everything works.
- [ ] iPhone does not rotate. iPad does, and the layout still fits.
- [ ] No content under the status bar or home indicator.
- [ ] App icon shows on the home screen.
- [ ] `git status` clean, build products ignored, everything pushed.
