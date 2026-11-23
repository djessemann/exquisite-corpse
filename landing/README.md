# exquisite sketch: landing page

One static page. No build step. Upload this whole folder to any static host
(GitHub Pages, Netlify, Vercel, Cloudflare Pages, S3) and it works.

## Files

- `index.html`: the page
- `logo.svg`: the squiggle
- `drawings/`: gallery images (the `example-*.svg` files are placeholders)
- `app-store-badge.svg`: placeholder App Store badge
- `og-image.png`: 1200x630 preview image for links shared in iMessage, Slack, etc.
- `privacy/`: privacy policy (placeholder). Use its URL as the Privacy Policy URL in App Store Connect.
- `support/`: support page (placeholder). Use its URL as the Support URL in App Store Connect.
- `page.css`: shared styles for the privacy and support pages
- `favicon.svg`, `apple-touch-icon.png`, `fonts/`

## Before launch

1. **Drawings**: put the real PNGs in `drawings/` and change the `src` paths in
   the gallery section of `index.html`. Add or remove `<figure>` lines freely.
   The loop copies them on its own. Delete the `example-*.svg` files after.
2. **App Store link**: replace `href="#"` on `#app-store-link` with the real
   App Store URL.
3. **Official badge**: download the official "Download on the App Store" badge
   from Apple's marketing tools (tools.applemarketingtools.com) and save it over
   `app-store-badge.svg`. Apple asks that sites use their artwork as is.
4. **Smart banner (optional)**: uncomment the `apple-itunes-app` meta tag and add
   the app id, so Safari on iPhone shows an "open in app" banner.
5. **Link previews**: once the site has a real address, change `og:image` to the
   full URL (for example `https://example.com/og-image.png`). Some apps ignore
   relative paths. Regenerate `og-image.png` with the real drawings if you like.

6. **Privacy and support pages**: check every line still matches the app. They say
   the app collects nothing, has no accounts, ads or analytics, keeps drawings on
   the device, and asks before saving to Photos. If any of that changes, update
   `privacy/index.html` and its date. Swap the placeholder email if needed.

## Tweaks

- Gallery speed: `--speed` at the top of the `<style>` block (bigger is slower).
- Card size: `--card-w`.
- People with "reduce motion" turned on get a still gallery they can swipe.
