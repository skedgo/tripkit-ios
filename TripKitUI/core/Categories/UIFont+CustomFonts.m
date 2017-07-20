//
//  UIFont+CustomFonts.m
//  TripGo
//
//  Created by Kuan Lun Huang on 30/03/2015.
//
//

#import "UIFont+CustomFonts.h"

#import "SGKConfig.h"

@implementation UIFont (CustomFonts)

+ (NSString *)preferredFontName
{
  NSString *preferred = [[SGKConfig sharedInstance] preferredFonts][@"Regular"];
  if (preferred) {
    return preferred;
  } else {
    return nil;
  }
}

+ (NSString *)preferredBoldFontName
{
  NSString *preferred = [[SGKConfig sharedInstance] preferredFonts][@"Bold"];
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
