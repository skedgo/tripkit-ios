//
//  UIFont+CustomFonts.h
//  TripKit
//
//  Created by Kuan Lun Huang on 30/03/2015.
//
//

#import <UIKit/UIKit.h>

@interface UIFont (CustomFonts)

+ (nullable NSString *)preferredFontName;

+ (nullable NSString *)preferredBoldFontName;

+ (nullable NSString *)preferredSemiboldFontName;

+ (void)printIncludedCustomFontsByNames;

@end
