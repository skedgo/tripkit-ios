//
//  SGKConfig.m
//  TripGo
//
//  Created by Adrian Schoenig on 20/03/2015.
//
//

#import "SGKConfig.h"

#import "SGKLog.h"

@interface SGKConfig ()

@property (nonatomic, strong) NSDictionary *configuration;

@end

@implementation SGKConfig

+ (SGKConfig *)sharedInstance {
  DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
    return [[self alloc] init];
  });
}

- (NSString *)appGroupName
{
  return self.configuration[@"AppGroupName"];
}

- (NSURL *)oauthCallbackURL
{
  NSString *URLString = self.configuration[@"OAuthCallbackURL"];
  if (URLString) {
    return [NSURL URLWithString:URLString];
  } else {
    return nil;
  }
}

- (NSString *)appURLScheme
{
  NSString *specified = self.configuration[@"URLScheme"];
  return specified != nil ? specified : @"tripgo";
}

- (BOOL)betaFeaturesAvailable
{
  return [self.configuration[@"BetaFeaturesAvailable"] boolValue];
}

- (BOOL)accountsAvailable
{
  return [self.configuration[@"AccountsAvailable"] boolValue];
}

- (BOOL)bookingAvailable
{
  return [self.configuration[@"BookingAvailable"] boolValue];
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
