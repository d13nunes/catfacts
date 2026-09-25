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
