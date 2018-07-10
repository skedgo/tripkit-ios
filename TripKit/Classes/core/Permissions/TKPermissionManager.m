//
//  TKPermissionManager.m
//  Welcome
//
//  Created by Adrian Schoenig on 4/09/12.
//  Copyright (c) 2012 Adrian Schoenig. All rights reserved.
//

#import "TKPermissionManager.h"

NSString *const TKPermissionsChangedNotification =  @"kTKPermissionsChangedNotification";

@implementation TKPermissionManager

#pragma mark - Methods to be implemented by subclasses

- (BOOL)featureIsAvailable
{
  // Objective C has no support for abstract methods, so we're raising an exception instead
  NSException *ex = [NSException exceptionWithName:@"Abstract Method Not Overridden"
                                            reason:@"You MUST override this save method"
                                          userInfo:nil];
  [ex raise];
  return NO;
}

- (void)askForPermission:(void (^)(BOOL enabled))completion
{
#pragma unused(completion)
  // Objective C has no support for abstract methods, so we're raising an exception instead
  NSException *ex = [NSException exceptionWithName:@"Abstract Method Not Overridden"
                                            reason:@"You MUST override this save method"
                                          userInfo:nil];
  [ex raise];
}

- (BOOL)authorizationRestrictionsApply
{
  // Objective C has no support for abstract methods, so we're raising an exception instead
  NSException *ex = [NSException exceptionWithName:@"Abstract Method Not Overridden"
                                            reason:@"You MUST override this save method"
                                          userInfo:nil];
  [ex raise];
  return NO;
}

- (TKAuthorizationStatus)authorizationStatus
{
  // Objective C has no support for abstract methods, so we're raising an exception instead
  NSException *ex = [NSException exceptionWithName:@"Abstract Method Not Overridden"
                                            reason:@"You MUST override this save method"
                                          userInfo:nil];
  [ex raise];
  return TKAuthorizationStatusNotDetermined;
}

- (NSString *)authorizationAlertText
{
  // Objective C has no support for abstract methods, so we're raising an exception instead
  NSException *ex = [NSException exceptionWithName:@"Abstract Method Not Overridden"
                                            reason:@"You MUST override this save method"
                                          userInfo:nil];
  [ex raise];
  return @"";
}

#pragma mark - Public methods

- (BOOL)isAuthorized
{
  if (! [self featureIsAvailable])
    return NO;
  
  if ([self authorizationRestrictionsApply]) {
    TKAuthorizationStatus status = [self authorizationStatus];
    return status == TKAuthorizationStatusAuthorized;
    
  } else {
    // no restrictions apply
    return YES;
  }
}


@end
