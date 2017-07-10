//
//  SGBPHelper.m
//  TripGo
//
//  Created by Kuan Lun Huang on 4/02/2015.
//
//

#import "BPKHelpers.h"

@implementation BPKHelpers

+ (void)presentAlertFromController:(UIViewController *)controller withMessage:(NSString *)message
{
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
  [controller presentViewController:alert animated:YES completion:nil];
}

+ (BOOL)isControllerPresentedModally:(UIViewController *)controller
{
  return controller.navigationController != nil && controller.navigationController.viewControllers[0] == controller;
}

@end
