# TripKit SDK for iOS

This is the documentation of TripKit iOS, the iOS SDK for the [TripGo API](https://developer.tripgo.com).

The SDK consists of the following three frameworks:

- [**TripKit**](TripKit/TripKit.html) (iOS, iOS extensions, macOS): Core functionality for A-to-B routing, waypoint routing, real-time updates, transport data, and more.
- [**TripKitUI**](TripKit/TripKitUI.html) (iOS, iOS extensions): [View controllers](view-controllers.md), as well as individual UI helpers and components.
- [**TripKitInterApp** ](TripKit/TripKitInterApp.html) (iOS): Helpers for deep linking into other apps, such as GoCatch, Ingogo, Lyft, Ola and Uber.

TripKit contains the core logic, and the other two depend on it..

## Installation

### Swift Package Manager

Full support for SPM is incoming in the upcoming version 5.0. For now, you can use the `main` branch.

Add it to your dependencies:

```swift
.package(name: "TripKit", url: "https://github.com/skedgo/tripkit-ios", branch: "main")
```

And then add the TripKit, TripKitUI, and/or TripKitInterApp dependencies to your target, as appropriate.

### Cocoapods

Add desired pods to your `Podfile`:

```ruby
use_frameworks!

pod 'TripKit'
pod 'TripKitUI'
pod 'TripKitInterApp'
```

Then run `pod update` and you're set.

If you get a "Sandbox" error, make sure that your `ENABLE_USER_SCRIPT_SANDBOXING` is set to 'No', see [Stack Overflow](https://stackoverflow.com/questions/76590131/error-while-build-ios-app-in-xcode-sandbox-rsync-samba-13105-deny1-file-w).

### Manually

- Drag the files into your project.
- Add dependencies (see TripKit.podspec)

If there's any trouble with that, see the examples in the repository.

## Set-up

First up, sign up for a [TripGo API key](https://developer.tripgo.com).

In your app delegate, provide your API key and start a new session:

```swift
import TripKit

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
  
  TripKit.apiKey = "MY_API_KEY"
  TripKit.prepareForNewSession()

  // ...
}
```

You can then start using TripKit and TripKitUI, e.g.:

```swift
import TripKitUI

let controller = TKUIHomeViewController()
present(controller, animated: true)
```

Have a look at the [`TripKitUIExample`](https://github.com/skedgo/tripkit-ios/tree/main/Examples/TripKitUIExample) in the GitHub repository, as well as the SDK Reference at the top of this page.
