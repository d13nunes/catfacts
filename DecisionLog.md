# Decision Log

## Minimum iOS version: 14.4 → 15.0

- **Device impact:** none. Every device that runs iOS 14 also runs iOS 15 (iPhone 6s / SE 1st gen and later). [Hardware support](https://en.wikipedia.org/wiki/IOS_version_history#Hardware_support)
- **Real-world caveat:** in production this call would be based on the user base's OS adoption analytics, not device support alone.
- **Why 15:** the exercise doesn't require 14, and installing an older simulator runtime only to test it isn't worth it here. Moving to 15 lets me use newer iOS and Swift APIs.
- **Why not higher:** for a new app I would start on iOS 18, but the Onfido SDK supports iOS 13+, so I kept a lower floor to show how I work with older targets (`if #available` / `@available` for newer APIs).
- **Dependencies:** the Podfile sets `platform :ios, '15.0'` and a `post_install` hook pins every pod target to 15.0. Alamofire's podspec declares iOS 10, which is below what current Xcode supports.
