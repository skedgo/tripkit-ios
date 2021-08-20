//
//  TKStyleManager+SkedGoUI.m
//  TripKit
//
//  Created by Adrian Schoenig on 6/07/2016.
//
//

#import "TargetConditionals.h"
#if !TARGET_OS_OSX

#if SWIFT_PACKAGE
#import <TripKitObjc/TKStyleManager+UIKit.h>
#import <TripKitObjc/UIFont+CustomFonts.h>
#else
#import "TKStyleManager+UIKit.h"
#import "UIFont+CustomFonts.h" // for bundle
#endif

@implementation TKStyleManager (Fonts)

+ (UIFont *)systemFontWithSize:(CGFloat)size
{
  NSString *name = [UIFont preferredFontName];
  if (name) {
    UIFont *preferredFont = [UIFont fontWithName:name size:size];
    if (preferredFont) {
      return preferredFont;
    }
  }
  return [UIFont systemFontOfSize:size];
}

+ (UIFont *)boldSystemFontWithSize:(CGFloat)size
{
  NSString *name = [UIFont preferredBoldFontName];
  if (name) {
    UIFont *preferredFont = [UIFont fontWithName:name size:size];
    if (preferredFont) {
      return preferredFont;
    }
  }
  return [UIFont boldSystemFontOfSize:size];
}

+ (UIFont *)semiboldSystemFontWithSize:(CGFloat)size
{
  NSString *name = [UIFont preferredSemiboldFontName];
  if (name) {
    UIFont *preferredFont = [UIFont fontWithName:name size:size];
    if (preferredFont) {
      return preferredFont;
    }
  }
  return [UIFont systemFontOfSize:size weight:UIFontWeightSemibold];
}

+ (UIFont *)mediumSystemFontWithSize:(CGFloat)size
{
  NSString *name = [UIFont preferredMediumFontName];
  if (name) {
    UIFont *preferredFont = [UIFont fontWithName:name size:size];
    if (preferredFont) {
      return preferredFont;
    }
  }
  return [UIFont systemFontOfSize:size weight:UIFontWeightMedium];
}

@end

#endif
