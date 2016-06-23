# SkedGo's TripKit for iOS

Some documentation can be found in the [TripGo API Wiki](https://github.com/skedgo/tripgo-api/wiki)

## Installation

TripKit should be installed via cocoapods:

Either install the lot:

```
pod 'TripKit'
```

Or cherry-pick the modules that you like:

```
pod 'TripKit/Core'
pod 'TripKit/Agenda'
pod 'TripKit/Bookings'
pod 'TripKit/InterApp'
```

## Set-up

* Refresh the cached information at an appropriate time, e.g., when your app finished launching or comes back to the foreground:

```  objective-c
  [[SVKServer sharedInstance] updateRegionsForced:NO];
```



## Optional features

### Logging

Dependencies:

* CocoaPods:
``` ruby
  pod 'CocoaLumberjack'
```

TODO: How to use this

### Booking features

Dependencies:

* CocoaPods:
``` ruby
  pod 'AFNetworking', '~> 2.5.3'
```
* Modules from [SkedGo's shared iOS code base](https://github.com/skedgo/shared-ios)
  * BookingKit

TODO: How to use this

### Agenda (Swift-only)

Dependencies:

* Cocoapods:
``` ruby
  pod 'RxSwift', '~> 2.0'
```

TODO: How to use this

### Inter-app Communication

Dependencies:

* Modules from [SkedGo's shared iOS code base](https://github.com/skedgo/shared-ios)
  * Actions

TODO: How to use this

## Tracking

Calls to the SkedGo servers typically include an "X-TripGo-UUID" header which allows tracking calls from a single installation across sessions. This behaviour is **opt-out**. Opt-out by adding a Boolean with key `SVKDefaultsKeyProfileTrackUsage` and value `true` to the standard user defaults.
