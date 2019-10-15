//
//  TKPermissionManager+AuthorizationAlert.m
//  TripKit
//
//  Created by Kuan Lun Huang on 5/01/2015.
//
//

#import "TKPermissionManager+AuthorizationAlert.h"

#import "TKActions.h"
#import "TKStyleManager.h"

#import "TripKit/TripKit-Swift.h"

#if TARGET_OS_IPHONE

@implementation TKPermissionManager (AuthorizationAlert)

- (void)tryAuthorizationForSender:(id)sender
                 inViewController:(UIViewController *)controller
                       completion:(TKPermissionCompletionBlock)completion
{
  if (! [self featureIsAvailable]) {
    //    NSLog(@"Attempted `tryAuthorization` even though feature isn't available!");
    completion(NO);
    return;
  }
  
  if ([self isAuthorized]) {
    completion(YES);
    return;
  }
  
  // we aren't authorized yet. can we authorize at all?
  TKAuthorizationStatus status = [self authorizationStatus];
  switch (status) {
    case TKAuthorizationStatusRestricted:
    case TKAuthorizationStatusDenied:
      [self showAuthorizationAlertForSender:sender inViewController:controller];
      completion(NO);
      return;
      
    case TKAuthorizationStatusNotDetermined:
      [self askForPermission:completion];
      return;
      
    default:
      //      NSLog(@"Unexpected authorisation status: %d", status);
      completion(NO);
      return;
  }
}

- (void)showAuthorizationAlertForSender:(id)sender
                       inViewController:(UIViewController *)controller
{
  if (! [self authorizationRestrictionsApply])
    return;
  
  NSString *message = nil;
  
  TKAuthorizationStatus status = [self authorizationStatus];
  switch (status) {
    case TKAuthorizationStatusDenied:
      message = [self authorizationAlertText];
      break;
      
    case TKAuthorizationStatusRestricted:
      message = NSLocalizedStringFromTableInBundle(@"Access to this feature has been restricted for your device. Please check the Settings app > General > Restrictions or ask your device provider.", @"Shared", [TKStyleManager bundle], @"Authorization restricted alert message");
      break;
      
    default:
      //      NSLog(@"Unexpected authorisation status: %d", status);
      return;
  }
  
  
  TKActions *alert = [[TKActions alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Authorisation needed", @"Shared", [TKStyleManager bundle], @"Authorisation needed title")];
  alert.message = message;

  if (self.openSettingsHandler) {
    alert.hasCancel = YES;
    [alert addAction:Loc.OpenSettings handler:self.openSettingsHandler];
  } else {
    alert.hasCancel = NO;
    [alert addAction:Loc.OK handler:nil];
  }
  
  // make sure to to show this on the main thread
  dispatch_async(dispatch_get_main_queue(), ^{
    [alert showForSender:sender inController:controller];
  });
}

@end

#endif
