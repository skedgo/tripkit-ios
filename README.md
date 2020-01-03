<img src="api-mark-logo.png" alt="TripGo API" width="30" height="30">  SkedGo's TripKit for iOS
======================================

![platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20watchOS-333333.svg) [![CocoaPods](https://img.shields.io/cocoapods/v/TripKit.svg)]() [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Additional documentation is available on the [TripGo Developer page](https://developer.tripgo.com/)

## Components

- **TripKit** (iOS, iOS extensions, macOS): Core functionality for A-to-B routing, waypoint routing, real-time updates, transport data, and more.
- **TripKitUI** (iOS, iOS extensions): [View controllers](docs/view-controllers.md), as well as individual UI helpers and components.
- **TripKitInterApp** (iOS): Helpers for deep linking into other apps, such as FlitWays, GoCatch, Ingogo, Lyft, Ola and Uber.

## Installation

### Cocoapods

Add desired pods:

```ruby
  pod 'TripKit',                '~> 4.0'
  pod 'TripKitUI',              '~> 4.0'
  pod 'TripKitInterApp',        '~> 4.0'
```

### Carthage

Add this to your `Cartfile`:

```
git "https://gitlab.com/SkedGo/iOS/tripkit-ios.git" "master"
```

Then run `carthage update` and add the desired framework to your project as described in [the Carthage docs](https://github.com/Carthage/Carthage).

When doing so, you'll need to add the respective dependencies:

- TripKit / TripKitInterApp:
  - ASPolygonKit
  - RxSwift
  - RxCocoa
- TripKitUI:
  - Those of TripKit, plus:
  - Kingfisher
  - [TGCardViewController](https://gitlab.com/SkedGo/iOS/tripgo-cards-ios)

### Manually

- Drag the files into your project.
- Add dependencies (see [TripKit.podspec](TripKit.podspec))
- Add `-DTK_NO_MODULE` to your target's `Other C Flags` and `Other Swift Flags`
- Add `TK_NO_MODULE=1` to your target's `Preprocessor Macros`

If there's any trouble with that, see the example under [Project](Project).

## Set-up

- In your app delegate, provide your API key and start a new session:

```swift
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    
    TripKit.apiKey = "MY_API_KEY"
    TripKit.prepareForNewSession()

    // ...
  }
```

## License

TripKit is copyright 2011-2020 by SkedGo Pty Ltd
