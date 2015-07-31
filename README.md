# SkedGo's TripKit for iOS

Some documentation can be found in the [Wiki](https://github.com/skedgo/tripkit-ios/wiki)

## Dependencies

* CocoaPods:
``` 
  pod 'AFNetworking', '~> 2.5.3'
  pod 'CocoaLumberjack'
```

* Selected modules from [SkedGo's shared iOS code base](https://github.com/skedgo/shared-ios)
  * RootKit
  * ServerKit
  * TransportKit

## Set-up

* Refresh the cached information at an appropriate time, e.g., when your app finished launching or comes back to the foreground:

```
  [[SVKServer sharedInstance] updateRegionsForced:NO];
```

## Tracking

Calls to the SkedGo servers typically include an "X-TripGo-UUID" header which allows tracking calls from a single installation across sessions. This behaviour is **opt-out**. Opt-out by adding a Boolean with key `SVKDefaultsKeyProfileTrackUsage` and value `true` to the standard user defaults.
