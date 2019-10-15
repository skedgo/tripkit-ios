//
//  TKPermissionManager+AuthorizationAlert.h
//  TripKit
//
//  Created by Kuan Lun Huang on 5/01/2015.
//
//

#import "TKPermissionManager.h"

#import "TKCrossPlatform.h"

#if TARGET_OS_IPHONE

@interface TKPermissionManager (AuthorizationAlert)

- (void)tryAuthorizationForSender:(nullable id)sender
                 inViewController:(nonnull UIViewController *)controller
                       completion:(nonnull TKPermissionCompletionBlock)completion;

- (void)showAuthorizationAlertForSender:(nullable id)sender
                       inViewController:(nonnull UIViewController *)controller;

@end

#endif
