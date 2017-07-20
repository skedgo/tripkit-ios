//
//  UIFont+CustomFonts.h
//  TripGo
//
//  Created by Kuan Lun Huang on 30/03/2015.
//
//

#import <UIKit/UIKit.h>

@interface UIFont (CustomFonts)

+ (nullable NSString *)preferredFontName;

+ (nullable NSString *)preferredBoldFontName;

+ (void)printIncludedCustomFontsByNames;

@end
