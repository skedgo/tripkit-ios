//
//  UIFont+CustomFonts.h
//  TripKit
//
//  Created by Kuan Lun Huang on 30/03/2015.
//
//

#import "TargetConditionals.h"
#if !TARGET_OS_OSX

@import UIKit;

#import "TKCrossPlatform.h"

@interface UIFont (CustomFonts)

+ (nullable NSString *)preferredFontName;

+ (nullable NSString *)preferredBoldFontName;

+ (nullable NSString *)preferredSemiboldFontName;

+ (nullable NSString *)preferredMediumFontName;

@end

#endif
