//
//  SGBPHelper.m
//  TripKit
//
//  Created by Kuan Lun Huang on 4/02/2015.
//
//

#import "BPKHelpers.h"

#ifdef TK_NO_FRAMEWORKS
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#endif


@implementation BPKHelpers

+ (void)presentAlertFromController:(UIViewController *)controller withMessage:(NSString *)message
{
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:Loc.OK style:UIAlertActionStyleDefault handler:nil]];
  [controller presentViewController:alert animated:YES completion:nil];
}

+ (BOOL)isControllerPresentedModally:(UIViewController *)controller
{
  return controller.navigationController != nil && controller.navigationController.viewControllers[0] == controller;
}

@end
