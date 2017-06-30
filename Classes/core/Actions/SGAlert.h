//
//  SGKAlert.h
//  TripGo
//
//  Created by Kuan Lun Huang on 12/02/2015.
//
//

#import <UIKit/UIKit.h>

@interface SGAlert : NSObject

+ (void)showWithText:(NSString *)text inController:(UIViewController *)controller;

- (void)showWithTitle:(NSString *)title message:(NSString *)message inController:(UIViewController *)controller dismiss:(void(^)())dismiss;

@end
