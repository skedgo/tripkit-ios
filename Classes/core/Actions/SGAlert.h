//
//  SGKAlert.h
//  TripKit
//
//  Created by Kuan Lun Huang on 12/02/2015.
//
//

#import "SGKCrossPlatform.h"

#if TARGET_OS_IPHONE

@interface SGAlert : NSObject

+ (void)showWithText:(NSString *)text inController:(UIViewController *)controller;

- (void)showWithTitle:(NSString *)title message:(NSString *)message inController:(UIViewController *)controller dismiss:(void(^)())dismiss;

@end

#endif
