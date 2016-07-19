# SkedGo's TripKit for iOS

Additional documentation is available on the [TripGo Developer page](http://skedgo.github.io/tripgo-api/site/)

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

## Tracking

Calls to the SkedGo servers typically include an "X-TripGo-UUID" header which allows tracking calls from a single installation across sessions. This behaviour is **opt-out**. Opt-out by adding a Boolean with key `SVKDefaultsKeyProfileTrackUsage` and value `true` to the standard user defaults.
