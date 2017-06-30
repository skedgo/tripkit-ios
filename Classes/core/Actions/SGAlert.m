//
//  SGKAlert.m
//  TripGo
//
//  Created by Kuan Lun Huang on 12/02/2015.
//
//

#import "SGAlert.h"

#import "SGStyleManager.h"

@interface SGAlert ()

@property (nonatomic, copy) void (^dismissBlock)();

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

- (void)showWithTitle:(NSString *)title
              message:(NSString *)message
         inController:(UIViewController *)controller
              dismiss:(void (^)())dismiss
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
  return NSLocalizedStringFromTableInBundle(@"Alert", @"Shared", [SGStyleManager bundle], @"Default title for alert view");
}

+ (NSString *)cancelTitle
{
  return NSLocalizedStringFromTableInBundle(@"OK", @"Shared", [SGStyleManager bundle], @"Default title for button that dismisses alert view");
}

@end
