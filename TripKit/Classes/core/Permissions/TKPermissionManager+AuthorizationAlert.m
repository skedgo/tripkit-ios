//
//  TKPermissionManager+AuthorizationAlert.m
//  TripKit
//
//  Created by Kuan Lun Huang on 5/01/2015.
//
//

#import "TKPermissionManager+AuthorizationAlert.h"

#import "TKTripKit.h"
#import "TKActions.h"

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
      message = NSLocalizedStringFromTableInBundle(@"Access to this feature has been restricted for your device. Please check the Settings app > General > Restrictions or ask your device provider.", @"Shared", [TKTripKit bundle], @"Authorization restricted alert message");
      break;
      
    default:
      //      NSLog(@"Unexpected authorisation status: %d", status);
      return;
  }
  
  
  TKActions *alert = [[TKActions alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Authorisation needed", @"Shared", [TKTripKit bundle], @"Authorisation needed title")];
  alert.message = message;

  if (self.openSettingsHandler) {
    alert.hasCancel = YES;
    [alert addAction:NSLocalizedStringFromTableInBundle(@"Open Settings", @"Shared", [TKTripKit bundle], "Button that goes to the Setting's app") handler:self.openSettingsHandler];
  } else {
    alert.hasCancel = NO;
    [alert addAction:NSLocalizedStringFromTableInBundle(@"OK", @"Shared", [TKTripKit bundle], "OK action") handler:nil];
  }
  
  // make sure to to show this on the main thread
  dispatch_async(dispatch_get_main_queue(), ^{
    [alert showForSender:sender inController:controller];
  });
}

@end

#endif
