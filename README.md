# SkedGo's TripKit for iOS

![platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20watchOS-333333.svg) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Additional documentation is available on the [TripGo Developer page](http://skedgo.github.io/tripgo-api/site/)

## Components

- TripKit (iOS, iOS extension, macOS): Core functionality for A-to-B routing, waypoint routing, real-time updates, transport data, and more.
- TripKitUI (iOS): UI elements for displaying trips on a map and TripGo-styled table cells.
- TripKitBookings (iOS): User accounts and in-app booking functionality.
- TripKitAddOns/InterApp (iOS): Helpers for deep linking into other apps, such as FlitWays, GoCatch, Ingogo, Lyft, Ola and Uber.
- TripKitAddOns/Share (iOS, iOS extensions, macOS): Helpers for creating shareable links to trips, services, transit stops, and meeting locations, that open in TripGo's web app.

## Installation

### Cocoapods (recommended)

At the top of your `Podfile`, make sure you include SkedGo's private pods:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/skedgo/PodSpecs.git'
```

And then add desired pods:

```ruby
  pod 'TripKit',                '~> 2.0beta4'
  pod 'TripKitUI',              '~> 2.0beta4'
  pod 'TripKitBookings',        '~> 2.0beta4'
  pod 'TripKitAddOns/InterApp', '~> 2.0beta4'
  pod 'TripKitAddOns/Share',    '~> 2.0beta4'
```

This is the recommended way as it let's you cherry-pick the desired components and if you use any of TripKit's sdependencies, such as [RxSwift](https://github.com/ReactiveX/RxSwift), you'll end up with only a single copy of that.

### Carthage

TripKit with all its components is also available through Carthage. Note that this means that it's currently supprting iOS only.

Add this to your `Cartfile`:

```
github "skedgo/tripkit-ios" "v2.0-beta4"
```

Then run `carthage update` and add the framework to your project as described in [the Carthage docs](https://github.com/Carthage/Carthage).

### Manually

- Drag the files into your project.
- Add dependencies (see [TripKit.podspec](TripKit.podspec))
- Specify `TK_NO_FRAMEWORKS` in both your target's `Other C Flags` *and* `Other Swift Flags`

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
