//
//  TKAlertController.h
//  TripKit
//
//  Created by Kuan Lun Huang on 12/02/2015.
//
//

#import "TKCrossPlatform.h"

#if TARGET_OS_IPHONE

@interface TKAlertController : NSObject

+ (void)showWithText:(NSString *)text inController:(UIViewController *)controller;

+ (void)showWithTitle:(NSString *)title message:(NSString *)message inController:(UIViewController *)controller dismiss:(void(^)(void))dismiss;

@end

#endif
