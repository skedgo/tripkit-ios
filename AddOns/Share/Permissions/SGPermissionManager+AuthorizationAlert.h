//
//  SGPermissionManager+AuthorizationAlert.h
//  TripGo
//
//  Created by Kuan Lun Huang on 5/01/2015.
//
//

#import "SGPermissionManager.h"

@import UIKit;

@interface SGPermissionManager (AuthorizationAlert)

- (void)tryAuthorizationForSender:(id)sender
                 inViewController:(UIViewController *)controller
                       completion:(SGPermissionCompletionBlock)completion;
- (void)showAuthorizationAlertForSender:(id)sender
                       inViewController:(UIViewController *)controller;

@end
