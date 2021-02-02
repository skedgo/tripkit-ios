//
//  UIFont+CustomFonts.m
//  TripKit
//
//  Created by Kuan Lun Huang on 30/03/2015.
//
//

//#if TARGET_OS_IPHONE

#import "UIFont+CustomFonts.h"

#import "TKConfig.h"

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

+ (void)printIncludedCustomFontsByNames
{
#ifdef DEBUG
  for (NSString *family in [UIFont familyNames]) {
    NSLog(@"%@", family);
    for (NSString *name in [UIFont fontNamesForFamilyName: family])
    {
      NSLog(@"  %@", name);
    }
  }
#endif
}

@end

//#endif
