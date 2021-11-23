//
//  TKConfig.m
//  TripKit
//
//  Created by Adrian Schoenig on 20/03/2015.
//
//

#if SWIFT_PACKAGE
#import <TripKitObjc/TKConfig.h>
#else
#import "TKConfig.h"
#endif

@interface TKConfig ()

@property (nonatomic, strong) NSDictionary *configuration;

@end

@implementation TKConfig

+ (TKConfig *)sharedInstance {
  static dispatch_once_t pred = 0;
  __strong static id _sharedObject = nil;
  dispatch_once(&pred, ^{
    _sharedObject = [[self alloc] init];
  });
  return _sharedObject;
}

- (NSDictionary *)configuration
{
  if (!_configuration) {
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]; // Yes, main bundle!
    if (plistPath) {
      _configuration = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    } else {
      _configuration = [NSDictionary dictionary];
    }
  }
  return _configuration;
}


#pragma mark - Colors.

- (NSDictionary *)globalTintColor
{
  if ([self.configuration[@"GlobalTintColor"] isKindOfClass:[NSDictionary class]])
  {
    return self.configuration[@"GlobalTintColor"];
  } else {
    return nil;
  }
}

- (NSDictionary *)globalAccentColor
{
  NSDictionary *accentDictionary;
  
  if ([self.configuration[@"GlobalAccentColor"] isKindOfClass:[NSDictionary class]])
  {
    accentDictionary = self.configuration[@"GlobalAccentColor"];
  } else {
    accentDictionary = nil;
  }
  return accentDictionary ?: [self globalTintColor];
}

- (NSDictionary *)globalBarTintColor
{
  if ([self.configuration[@"GlobalBarTintColor"] isKindOfClass:[NSDictionary class]])
  {
    return self.configuration[@"GlobalBarTintColor"];
  } else {
    return nil;
  }
}

- (NSDictionary *)globalSecondaryBarTintColor
{
  if ([self.configuration[@"GlobalSecondaryBarTintColor"] isKindOfClass:[NSDictionary class]])
  {
    return self.configuration[@"GlobalSecondaryBarTintColor"];
  } else {
    return nil;
  }
}

- (BOOL)globalTranslucency
{
  return [self.configuration[@"GlobalTranslucency"] boolValue];
}

#pragma mark - Fonts

- (NSDictionary *)preferredFonts
{
  if ([self.configuration[@"PreferredFonts"] isKindOfClass:[NSDictionary class]]) {
    return self.configuration[@"PreferredFonts"];
  } else {
    return nil;
  }
}

@end
