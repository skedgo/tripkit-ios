//
//  TKConfig.m
//  TripKit
//
//  Created by Adrian Schoenig on 20/03/2015.
//
//

#import "TKConfig.h"

#import "TKLog.h"

@interface TKConfig ()

@property (nonatomic, strong) NSDictionary *configuration;

@end

@implementation TKConfig

+ (TKConfig *)sharedInstance {
  DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
    return [[self alloc] init];
  });
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
  return self.configuration[@"GlobalTintColor"];
}

- (NSDictionary *)globalAccentColor
{
  NSDictionary *accent = self.configuration[@"GlobalAccentColor"];
  return accent ?: [self globalTintColor];
}

- (NSDictionary *)globalBarTintColor
{
  return self.configuration[@"GlobalBarTintColor"];
}

- (NSDictionary *)globalSecondaryBarTintColor
{
  return self.configuration[@"GlobalSecondaryBarTintColor"];
}

- (BOOL)globalTranslucency
{
  return [self.configuration[@"GlobalTranslucency"] boolValue];
}

#pragma mark - Fonts

- (NSDictionary *)preferredFonts
{
  return self.configuration[@"PreferredFonts"];
}

@end
