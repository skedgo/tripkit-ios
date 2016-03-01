//
//  TKSettings.m
//  TripGo
//
//  Created by Adrian Schoenig on 11/06/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "TKSettings.h"

#import "TKTripKit.h"

@implementation TKSettings

+ (NSMutableDictionary *)defaultDictionary
{
  NSMutableDictionary *paras = [NSMutableDictionary dictionaryWithCapacity:10];
  NSUserDefaults *sharedDefaults = [NSUserDefaults sharedDefaults];
  
  // JSON version
  [paras setValue:@(11) forKey:@"v"];
  
  // distance units
  NSString *unit = nil;
  switch ([sharedDefaults integerForKey:SVKDefaultsKeyProfileDistanceUnit]) {
    case SGDistanceUnitTypeAuto: // default
      unit = @"auto";
      break;
      
    case SGDistanceUnitTypeMetric:
      unit = @"metric";
      break;
      
    case SGDistanceUnitTypeImperial:
      unit = @"imperial";
      break;
    default:
      unit = @"auto";
      break;
  }
  [paras setValue:unit forKey:@"unit"];
  
  // profile settings
  float priceWeight   = [sharedDefaults floatForKey:TKDefaultsKeyProfileWeightMoney];
  float carbonWeight  = [sharedDefaults floatForKey:TKDefaultsKeyProfileWeightCarbon];
  float timeWeight    = [sharedDefaults floatForKey:TKDefaultsKeyProfileWeightTime];
  float hassleWeight  = [sharedDefaults floatForKey:TKDefaultsKeyProfileWeightHassle];
  if (priceWeight + carbonWeight + timeWeight + hassleWeight > 0.1) {
    NSString *weightString = [NSString stringWithFormat:@"(%f,%f,%f,%f)", priceWeight, carbonWeight, timeWeight, hassleWeight];
    [paras setValue:weightString forKey:@"wp"];
  }
  
  // transport preferences
  [paras setValue:[TKUserProfileHelper dislikedTransitModes] forKey:@"avoid"];
  
  if ([sharedDefaults boolForKey:TKDefaultsKeyProfileTransportConcessionPricing]) {
    [paras setValue:@(YES) forKey:@"conc"];
  }
  [paras setValue:@([sharedDefaults integerForKey:TKDefaultsKeyProfileTransportWalkSpeed])		forKey:@"ws"];
  [paras setValue:[sharedDefaults objectForKey:TKDefaultsKeyProfileTransportWalkMaxDuration]  forKey:@"wm"]; // optional
  [paras setValue:@([sharedDefaults integerForKey:TKDefaultsKeyProfileTransportTransferTime]) forKey:@"tt"];
  
  // beta features
  if ([sharedDefaults boolForKey:SVKDefaultsKeyProfileEnableFlights]) {
    [paras setValue:@(YES) forKey:@"ef"];
  }
  [paras setValue:@(YES) forKey:@"ir"];
  
#ifdef DEBUG
  [paras setValue:@([sharedDefaults boolForKey:TKDefaultsKeyProfileBookingsUseSandbox]) forKey:@"bsb"];
#else
  if ([sharedDefaults boolForKey:TKDefaultsKeyProfileBookingsUseSandbox]) {
    [paras setValue:@(YES) forKey:@"bsb"];
  }
#endif

  return paras;
}

+ (void)setMaximumWalkingDuration:(NSTimeInterval)duration
{
  NSInteger minutes = (NSInteger) ((duration + 59) / 60);
  [[NSUserDefaults sharedDefaults] setDouble:minutes forKey:TKDefaultsKeyProfileTransportWalkMaxDuration];
}

+ (void)setMinimumTransferDuration:(NSTimeInterval)duration
{
  NSInteger minutes = (NSInteger) ((duration + 59) / 60);
  [[NSUserDefaults sharedDefaults] setInteger:minutes forKey:TKDefaultsKeyProfileTransportTransferTime];
}

+ (void)setProfileWeight:(float)weight forComponent:(TKSettingsProfileWeight)component
{
  switch (component) {
    case TKSettingsProfileWeight_Carbon:
      [[NSUserDefaults sharedDefaults] setFloat:weight forKey:TKDefaultsKeyProfileWeightCarbon];
      break;
      
    case TKSettingsProfileWeight_Hassle:
      [[NSUserDefaults sharedDefaults] setFloat:weight forKey:TKDefaultsKeyProfileWeightHassle];
      break;
      
    case TKSettingsProfileWeight_Money:
      [[NSUserDefaults sharedDefaults] setFloat:weight forKey:TKDefaultsKeyProfileWeightMoney];
      break;

    case TKSettingsProfileWeight_Time:
      [[NSUserDefaults sharedDefaults] setFloat:weight forKey:TKDefaultsKeyProfileWeightTime];
      break;
  }
}

+ (void)setWalkingSpeed:(TKSettingsSpeed)speed
{
  [[NSUserDefaults sharedDefaults] setInteger:(NSInteger)speed forKey:TKDefaultsKeyProfileTransportWalkSpeed];
}

+ (void)setCyclingSpeed:(TKSettingsSpeed)speed
{
  [[NSUserDefaults sharedDefaults] setInteger:(NSInteger)speed forKey:TKDefaultsKeyProfileTransportCyclingSpeed];
}

@end
