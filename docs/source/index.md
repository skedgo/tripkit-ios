# TripKit SDK for iOS

This is the documentation of TripKit iOS, the iOS SDK for the [TripGo API](https://developer.tripgo.com).

The SDK consists of the following three frameworks:

- [**TripKit**](TripKit/index.html) (iOS, iOS extensions, macOS): Core functionality for A-to-B routing, waypoint routing, real-time updates, transport data, and more.
- [**TripKitUI**](TripKitUI/index.html) (iOS, iOS extensions): [View controllers](view-controllers.md), as well as individual UI helpers and components.
- [**TripKitInterApp** ](TripKitInterApp/index.html) (iOS): Helpers for deep linking into other apps, such as GoCatch, Ingogo, Lyft, Ola and Uber.

You can use them individually, but note that the latter two depend on the first one.

## Installation

### Carthage

Add this to your `Cartfile`:

```ruby
git "https://gitlab.com/SkedGo/iOS/tripkit-ios.git" "master"
```

Then run `carthage update` and add the desired framework to your project as described in [the Carthage docs](https://github.com/Carthage/Carthage).

When doing so, you'll need to add the respective dependencies:

- TripKit / TripKitInterApp:
    - ASPolygonKit
    - RxSwift (+ RxCocoa + RxRelay)
- TripKitUI:
    - Those of TripKit, plus:
    - Kingfisher
    - RxDataSources (+ Differentiator)
    - [TGCardViewController](https://gitlab.com/SkedGo/iOS/tripgo-cards-ios)

### Cocoapods

Add desired pods:

```ruby
pod 'TripKit',                '~> 4.0'
pod 'TripKitUI',              '~> 4.0'
pod 'TripKitInterApp',        '~> 4.0'
```

### Manually

- Drag the files into your project.
- Add dependencies (see TripKit.podspec)
- Add `-DTK_NO_MODULE` to your target's `Other C Flags` and `Other Swift Flags`
- Add `TK_NO_MODULE=1` to your target's `Preprocessor Macros`

If there's any trouble with that, see the examples in the repository.

## Set-up

- In your app delegate, provide your API key and start a new session:

```swift
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    
    TripKit.apiKey = "MY_API_KEY"
    TripKit.prepareForNewSession()

    // ...
  }
```