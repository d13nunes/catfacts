# Decision Log

## Minimum iOS version: 14.4 → 15.0

- **Device impact:** None. Every device that runs iOS 14 also runs iOS 15 (iPhone 6s / SE 1st gen and later). [Hardware support](https://en.wikipedia.org/wiki/IOS_version_history#Hardware_support)
- **Real-world caveat:** In production this decision would be based on the user base's OS adoption analytics, not device support alone.
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

## App entry point: SceneDelegate

- **Decision:** Using `SceneDelegate` and the app entrypoint
- **Why the scene lifecycle:** Apple requires it from the release after iOS 26 when building with the latest SDK, or the app won't launch. [TN3187](https://developer.apple.com/documentation/technotes/tn3187-migrating-to-the-uikit-scene-based-life-cycle) `UIScene` exists since iOS 13, so one entry point covers iOS 15 to 27 with no `#available` checks.

## Networking: Alamofire → URLSession

- **Decision:** Remove Alamofire and use URLSession directly. The project now has no third-party dependencies.
- **Why:** The native SDK already does everything the app needs. It makes one GET request and decodes JSON, which
  URLSession's async `data(from:)` (iOS 15) and `JSONDecoder` handle without an external dependency.

## Fact badges: inline, 28pt, scaled with Dynamic Type

- **Decision:** Show the verified and new badges inline, at the start of each fact's text.
- **Why:** The badges are seen first, closer to the content they describe and better occupation screen space.
- **Size:** 28pt, big enough to stand out without overpowering the text. The provided images came in different sizes, so I resized them to 56px (@2x) and 84px (@3x).
- **Dynamic Type:** `@ScaledMetric` makes the badges grow with the text. Inside `Text`, an image ignores `.resizable()` and `.frame`, and only SF Symbols scale with the font. So each badge is redrawn at the scaled size as a `UIImage`, using `UIImage.resized(to:)` with `UIGraphicsImageRenderer`.
- **Trade-offs:**
  - The source images are 48px (new) and 64px (verified), so the @3x versions are scaled up and look slightly soft. Sharp badges need larger or vector artwork.
  - At 28pt the badges are taller than the body text, so the first line of each fact is taller than the rest.
  - SF Symbols weren't an option because there's no symbol for "new".

## Foreground Refresh

- **Decision:** Reload facts on app foregrounding
- **Why:** Facts change server-side without notification, and users leave the app backgrounded for long periods.
- **Implementation:** The ViewModel uses Combine to observe `willEnterForegroundNotification` (preventing false reloads from Control Center or system alerts).
- **UX/Behavior:** Existing data remains visible while reloading. If the refresh fails, the standard error screen appears.

## Pull to Refresh (iOS 16+)

- **Decision:** Enable manual reloads using SwiftUI's `.refreshable` on the `ScrollView`, calling `refresh()`.
- **OS Constraints:** `.refreshable` on `ScrollView` requires iOS 16+. On iOS 15, the modifier is ignored safely, avoiding complex UIKit fallbacks or custom `List` styling.
- **Behavior:**
  - In-flight reloads ignore redundant pull requests.
  - **Failures:** A failed pull silently retains current facts rather than interrupting the user with an error screen.
  - **Caching:** Requests respect standard `URLSession` caching (`max-age=3600`), so reloads within an hour may serve cached data unless explicit cache-bypassing is added.
