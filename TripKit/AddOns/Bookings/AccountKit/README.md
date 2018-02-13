# AccountKit

## Dependencies

Dependencies:

- [`shared-ios`](https://github.com/skedgo/shared-ios):
  - [`ServerKit`](https://github.com/skedgo/shared-ios/tree/master/Classes/ServerKit)
  - [`SGAlert`](https://github.com/skedgo/shared-ios/tree/master/Classes/Actions)
- Cocoapods
  - [`KVNProgress`](https://github.com/kevin-hirsch/KVNProgress)
- Swiftify your project
  - Add `#import "AMKAccountKit.h"` to your `$ProjectName-Bridging-Header.h`
  - Add `#import "$ProjectName-Swift.h"` to your prefix header

## Usage

During your application initialisation call:

```objective-c
  [[AMKManager sharedInstance] setup];
```

Let the user log in by presenting the view controller to sign-up or log-in:

```objective-c
  AKSignUpViewController *signUp = [AKSignUpViewController new];
  signUp.delegate = self;
  UINavigationController *modal = [[UINavigationController alloc] initWithRootViewController:signUp];
  [self presentViewController:modal animated:YES completion:nil];
```

You can then check if the user logged in in your code by checking if `[AMKUser sharedUser].token == nil`.

There's also a view controller to display the user's account:

```objective-c
  AKAccountViewController *info = [[AKAccountViewController alloc] init];
  info.user = [AMKUser sharedUser];
  UINavigationController *modal = [[UINavigationController alloc] initWithRootViewController:signUp];
  [self presentViewController:modal animated:YES completion:nil];
```
