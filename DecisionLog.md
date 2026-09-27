# Decision Log

## Minimum iOS version: 14.4 → 15.0

- **Device impact:** none. Every device that runs iOS 14 also runs iOS 15 (iPhone 6s / SE 1st gen and later). [Hardware support](https://en.wikipedia.org/wiki/IOS_version_history#Hardware_support)
- **Real-world caveat:** in production this call would be based on the user base's OS adoption analytics, not device support alone.
- **Why 15:** the exercise doesn't require 14, and installing an older simulator runtime only to test it isn't worth it here. Moving to 15 lets me use newer iOS and Swift APIs.
- **Why not higher:** for a new app I would start on iOS 18, but the Onfido SDK supports iOS 13+, so I kept a lower floor to show how I work with older targets (`if #available` / `@available` for newer APIs).

## Dependencies: CocoaPods → Swift Package Manager

- **Decision:** use SPM. On a new project I would start with SPM from day one; since the skeleton came with CocoaPods, I migrated it.
- **Why:**
  - CocoaPods has been in maintenance mode since August 2024: security fixes and a couple of releases a year, no new features. [Support & Maintenance Plans](https://blog.cocoapods.org/CocoaPods-Support-Plans/)
  - Its trunk goes read-only on 2 December 2026, after which no pod gets new versions. [Trunk Read-only Plan](https://blog.cocoapods.org/CocoaPods-Specs-Repo/)
  - Alamofire (the only dependency) has supported SPM since 5.0, so nothing ties the project to CocoaPods.
- **What changed:** Alamofire is added as a package, "up to next major" from 5.12.2, and `Package.resolved` pins the exact version. `Podfile`, `Pods/` and `CatFacts.xcworkspace` are gone; open `CatFacts.xcodeproj`.
- **Side benefits:** the unit-test target now resolves Alamofire without extra setup (under CocoaPods it failed to build). Moving from 5.4.1 to 5.12.2 stays within the same major version, so no API changes were needed, and it removes the iOS 15 deprecation warnings the old version produced.
- **Link to the iOS floor:** Alamofire 5.12.2's `Package.swift` requires iOS 15 (its podspec still says iOS 10), so SPM and the iOS 15 bump go together.

## App entry point: scene-based UIKit, no storyboard

- **Decision:** UIKit with the scene lifecycle. `SceneDelegate` builds the window and root navigation controller in code; `Main.storyboard` and its `Info.plist` entries are removed. `LaunchScreen.storyboard` stays.
- **Why the scene lifecycle:** Apple requires it from the release after iOS 26 when building with the latest SDK, or the app won't launch. [TN3187](https://developer.apple.com/documentation/technotes/tn3187-migrating-to-the-uikit-scene-based-life-cycle) `UIScene` exists since iOS 13, so one entry point covers iOS 15 to 27 with no `#available` checks.
- **Why UIKit over SwiftUI:** with an iOS 15 floor, SwiftUI lacks `NavigationStack` (iOS 16) and `@Observable` (iOS 17), so I'd need the deprecated `NavigationView` or `#available` branches. The UIKit APIs this app needs (collection-view lists, diffable data sources, content configurations, `UISearchController`) all exist on iOS 15 and aren't deprecated on 27.
- **Why no storyboard:** UI in code gives readable diffs and no XML merge conflicts, and view controllers can receive their dependencies through initializers.

## Networking: Alamofire → URLSession

- **Decision:** remove Alamofire and use `URLSession` directly. The project now has no third-party dependencies.
- **Why:** the native SDK already does everything the app needs. It makes one GET request and decodes JSON, which `URLSession`'s async `data(from:)` (iOS 15) and `JSONDecoder` handle without an external dependency.
- **What a dependency costs:** updates to track, supply-chain and security exposure, and extra build time and binary size. In an SDK, every dependency is also forced on the host app, which may already use a different version of it.
- **What changed:** `URLSessionHTTPClient` replaces `AlamofireHTTPClient` behind the same `HTTPClient` protocol, so the repository, view model and error handling didn't change. It keeps the same checks (2xx status, `application/json` content type) and the same `NetworkError` mapping, and the existing client tests pass against it through a stub `URLProtocol`.
- **What I give up:** Alamofire's request interceptors (retry, auth adapters), multipart uploads and upload/download progress helpers. If the app needs them later, they can go behind `HTTPClient` without touching the other layers, and any new dependency would come in through SPM (see above).

## Fact badges: inline, 28pt, scaled with Dynamic Type

- **Decision:** Change the verified and new badges to be inline with the text.
- **Why inline:** the badges are read before the fact, and the text keeps the full row width instead of sharing it with a column of icons. This change better hightlighs the fact tags, improving the user experience.
- **Assets resizing:** Provided assets didn't have coherent sizes so I normalized their sizes to 28pt, by reszing 2x to 56px and 3x to 84px. Why 28? It's good size to standout without being too big compared with the text size.
- **Scaling with the text:** I also added `@ScaledMetric`, so the badges are 28pt at the default text size and grow with Dynamic Type like the text around them. Images inside `Text` ignore `.resizable()` and `.frame`, so `UIImage.resized(to:)` (in `Shared/Utils`) redraws each badge at the scaled size.
- **Why `UIImage` and not `Image`:** inside `Text`, an `Image` keeps its own size; only SF Symbols scale with the font. So each badge is redrawn at the scaled size as a `UIImage`, with `UIGraphicsImageRenderer`.
- **Why tint the verified badge blue:** verified badges are usually blue, so users recognise them at a glance, but the provided image is black. It's rendered as a template, which lets it take a colour, and tinted blue. Apple deprecated `foregroundColor` in favour of `foregroundStyle`, but `foregroundStyle` on `Text` needs iOS 17 or higher, so `if #available(iOS 17.0, *)` uses it there and falls back to `foregroundColor` on iOS 15 and 16. If future versions of iOS stop using `foregroundColor` the app will continue to work.
- **Considerations:**
  - The provided artwork is 48px (new) and 64px (verified), so the 84px @3x images are scaled up and slightly soft, more so at larger text sizes. Sharp badges need larger or vector source art.
  - At 28pt the badges are taller than the body text, so each fact's first line is taller than the rest.
  - Considered using SF Symbols but there wasn't no SF Symbol for "new"
