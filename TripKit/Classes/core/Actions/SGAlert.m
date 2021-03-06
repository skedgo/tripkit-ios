//
//  SGKAlert.m
//  TripKit
//
//  Created by Kuan Lun Huang on 12/02/2015.
//
//

#import "SGAlert.h"

#import "SGStyleManager.h"

#import "TripKit/TripKit-Swift.h"

#if TARGET_OS_IPHONE

@interface SGAlert ()

@property (nonatomic, copy) void (^dismissBlock)(void);

@end

@implementation SGAlert

+ (void)showWithText:(NSString *)text
        inController:(UIViewController *)controller
{
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:[self alertTitle]
                                                                 message:text
                                                          preferredStyle:UIAlertControllerStyleAlert];
  
  UIAlertAction *ok = [UIAlertAction actionWithTitle:[self cancelTitle]
                                               style:UIAlertActionStyleDefault
                                             handler:nil];
  
  [alert addAction:ok];
  [controller presentViewController:alert animated:YES completion:nil];
}

+ (void)showWithTitle:(NSString *)title
              message:(NSString *)message
         inController:(UIViewController *)controller
              dismiss:(void (^)(void))dismiss
{
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                 message:message
                                                          preferredStyle:UIAlertControllerStyleAlert];
  
  UIAlertAction *ok = [UIAlertAction actionWithTitle:[[self class] cancelTitle]
                                               style:UIAlertActionStyleDefault
                                             handler:
                       ^(UIAlertAction *action) {
#pragma unused (action)
                         if (dismiss) {
                           dismiss();
                         }
                       }];
  
  [alert addAction:ok];
  [controller presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Private

+ (NSString *)alertTitle
{
  return Loc.Alert;
}

+ (NSString *)cancelTitle
{
  return Loc.OK;
}

@end

#endif
