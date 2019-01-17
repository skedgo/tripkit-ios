//
//  UIFont+CustomFonts.m
//  TripKit
//
//  Created by Kuan Lun Huang on 30/03/2015.
//
//

#import "UIFont+CustomFonts.h"

#import "TKConfig.h"

@implementation UIFont (CustomFonts)

+ (NSString *)preferredFontName
{
  NSString *preferred = [[TKConfig sharedInstance] preferredFonts][@"Regular"];
  if (preferred) {
    return preferred;
  } else {
    return nil;
  }
}

+ (NSString *)preferredBoldFontName
{
  NSString *preferred = [[TKConfig sharedInstance] preferredFonts][@"Bold"];
  if (preferred) {
    return preferred;
  } else {
    return nil;
  }
}

+ (NSString *)preferredSemiboldFontName
{
  NSString *preferred = [[TKConfig sharedInstance] preferredFonts][@"Semibold"];
  if (preferred) {
    return preferred;
  } else {
    return nil;
  }
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
