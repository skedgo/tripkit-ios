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
  if ([UIAlertController class] != nil) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [controller presentViewController:alert animated:YES completion:nil];
    
  } else {
    // iOS 7 and below
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
  }
}

+ (BOOL)isControllerPresentedModally:(UIViewController *)controller
{
  return controller.navigationController != nil && controller.navigationController.viewControllers[0] == controller;
}

@end
