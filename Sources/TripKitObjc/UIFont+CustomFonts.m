//
//  UIFont+CustomFonts.m
//  TripKit
//
//  Created by Kuan Lun Huang on 30/03/2015.
//
//

#import "TargetConditionals.h"
#if !TARGET_OS_OSX

#if SWIFT_PACKAGE
#import <TripKitObjc/UIFont+CustomFonts.h>
#import <TripKitObjc/TKConfig.h>
#else
#import "UIFont+CustomFonts.h"
#import "TKConfig.h"
#endif

@implementation UIFont (CustomFonts)

+ (NSString *)preferredFontName
{
  return [[TKConfig sharedInstance] preferredFonts][@"Regular"];
}

+ (NSString *)preferredBoldFontName
{
  return [[TKConfig sharedInstance] preferredFonts][@"Bold"];
}

+ (NSString *)preferredSemiboldFontName
{
  return [[TKConfig sharedInstance] preferredFonts][@"Semibold"];
}

+ (NSString *)preferredMediumFontName
{
  return [[TKConfig sharedInstance] preferredFonts][@"Medium"];
}

@end

#endif
