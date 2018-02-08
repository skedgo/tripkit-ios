<img src="api-mark-logo.png" alt="TripGo API" width="30" height="30">  SkedGo's TripKit for iOS
======================================

![platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20watchOS-333333.svg) [![CocoaPods](https://img.shields.io/cocoapods/v/TripKit.svg)]() [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Additional documentation is available on the [TripGo Developer page](http://skedgo.github.io/tripgo-api/site/)

## Components

- TripKit (iOS, iOS extension, macOS): Core functionality for A-to-B routing, waypoint routing, real-time updates, transport data, and more.
- TripKitUI (iOS): UI elements for displaying trips on a map and TripGo-styled table cells.
- TripKitBookings (iOS): User accounts and in-app booking functionality.
- TripKitInterApp (iOS): Helpers for deep linking into other apps, such as FlitWays, GoCatch, Ingogo, Lyft, Ola and Uber.

## Installation

### Cocoapods (recommended)

Add desired pods:

```ruby
  pod 'TripKit',                '~> 3.0.1'
  pod 'TripKitUI',              '~> 3.0.1'
  pod 'TripKitBookings',        '~> 3.0.1'
  pod 'TripKitAddOns/InterApp', '~> 3.0.1'
  pod 'TripKitAddOns/Share',    '~> 3.0.1'
```

This is the recommended way as it let's you cherry-pick the desired components and if you use any of TripKit's dependencies, such as [RxSwift](https://github.com/ReactiveX/RxSwift), you'll end up with only a single copy of that.

### Carthage

TripKit with all its components is also available through Carthage. Note that this means that it's currently supprting iOS only.

Add this to your `Cartfile`:

```
github "skedgo/tripkit-ios" "v3.0.1"
```

Then run `carthage update` and add the framework to your project as described in [the Carthage docs](https://github.com/Carthage/Carthage).

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

- By default, calls to SkedGo's servers include an identifier that tracks calls from a single installation across session. This behaviour is **opt-out**. You can overwrite this by setting `TripKit.allowTracking`.
