//
//  SGPermissionManager+AuthorizationAlert.m
//  TripGo
//
//  Created by Kuan Lun Huang on 5/01/2015.
//
//

#import "SGPermissionManager+AuthorizationAlert.h"

#import "SGActions.h"
#import "SGStylemanager.h"

@implementation SGPermissionManager (AuthorizationAlert)

- (void)tryAuthorizationForSender:(id)sender
                 inViewController:(UIViewController *)controller
                       completion:(SGPermissionCompletionBlock)completion
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
  SGAuthorizationStatus status = [self authorizationStatus];
  switch (status) {
    case SGAuthorizationStatusRestricted:
    case SGAuthorizationStatusDenied:
      [self showAuthorizationAlertForSender:sender inViewController:controller];
      completion(NO);
      return;
      
    case SGAuthorizationStatusNotDetermined:
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
  
  SGAuthorizationStatus status = [self authorizationStatus];
  switch (status) {
    case SGAuthorizationStatusDenied:
      message = [self authorizationAlertText];
      break;
      
    case SGAuthorizationStatusRestricted:
      message = NSLocalizedStringFromTableInBundle(@"Access to this feature has been restricted for your device. Please check the Settings app > General > Restrictions or ask your device provider.", @"Shared", [SGStyleManager bundle], @"Authorization restricted alert message");
      break;
      
    default:
      //      NSLog(@"Unexpected authorisation status: %d", status);
      return;
  }
  
  
  SGActions *alert = [[SGActions alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Authorisation needed", @"Shared", [SGStyleManager bundle], @"Authorisation needed title")];
  alert.message = message;

  if (self.openSettingsHandler) {
    alert.hasCancel = YES;
    [alert addAction:NSLocalizedStringFromTableInBundle(@"Open Settings", @"Shared", [SGStyleManager bundle], @"Button to open Settings app section for this app") handler:self.openSettingsHandler];
  } else {
    alert.hasCancel = NO;
    [alert addAction:NSLocalizedStringFromTableInBundle(@"OK", @"Shared", [SGStyleManager bundle], @"Authorisation ok button") handler:nil];
  }
  
  // make sure to to show this on the main thread
  dispatch_async(dispatch_get_main_queue(), ^{
    [alert showForSender:sender inController:controller];
  });
}

@end
