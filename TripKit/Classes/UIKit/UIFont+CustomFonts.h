//
//  UIFont+CustomFonts.h
//  TripKit
//
//  Created by Kuan Lun Huang on 30/03/2015.
//
//

@import UIKit;

@interface UIFont (CustomFonts)

+ (nullable NSString *)preferredFontName;

+ (nullable NSString *)preferredBoldFontName;

+ (nullable NSString *)preferredSemiboldFontName;

+ (nullable NSString *)preferredMediumFontName;

+ (void)printIncludedCustomFontsByNames;

@end
