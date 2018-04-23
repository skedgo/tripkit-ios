//
//  SGPermissionManager+AuthorizationAlert.h
//  TripKit
//
//  Created by Kuan Lun Huang on 5/01/2015.
//
//

#import "SGPermissionManager.h"

#import "SGKCrossPlatform.h"

#if TARGET_OS_IPHONE

@interface SGPermissionManager (AuthorizationAlert)

- (void)tryAuthorizationForSender:(nullable id)sender
                 inViewController:(nullable UIViewController *)controller
                       completion:(nonnull SGPermissionCompletionBlock)completion;

- (void)showAuthorizationAlertForSender:(id)sender
                       inViewController:(UIViewController *)controller;

@end

#endif
