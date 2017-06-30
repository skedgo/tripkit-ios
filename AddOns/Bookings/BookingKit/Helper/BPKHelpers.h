//
//  SGBPHelper.h
//  TripGo
//
//  Created by Kuan Lun Huang on 4/02/2015.
//
//

@import Foundation;
@import UIKit;

@interface BPKHelpers : NSObject

+ (void)presentAlertFromController:(UIViewController *)controller withMessage:(NSString *)message;
+ (BOOL)isControllerPresentedModally:(UIViewController *)controller;

@end
