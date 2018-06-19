//
//  TKSettings.m
//  TripKit
//
//  Created by Adrian Schoenig on 11/06/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "TKSettings.h"

#import "SGKBetaHelper.h"

#import <TripKit/TripKit-Swift.h>

@implementation TKSettings

+ (NSMutableDictionary *)defaultDictionary
{
  NSMutableDictionary *paras = [NSMutableDictionary dictionaryWithCapacity:10];
  NSUserDefaults *sharedDefaults = [NSUserDefaults sharedDefaults];
  
  // JSON version
  [paras setValue:@(11) forKey:@"v"];
  
  // distance units
  NSString *unit;
  if (@available(iOS 10.0, *)) {
    unit = [NSLocale currentLocale].usesMetricSystem ? @"metric" : @"imperial";
  } else {
    unit = @"auto";
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
  if (TKUserProfileHelper.showWheelchairInformation) {
    [paras setValue:@(YES) forKey:@"wheelchair"];
  }
  
  // All optional
  [paras setValue:[sharedDefaults objectForKey:TKDefaultsKeyProfileTransportCyclingSpeed] forKey:@"cs"];
  [paras setValue:[sharedDefaults objectForKey:TKDefaultsKeyProfileTransportWalkSpeed] forKey:@"ws"];
  [paras setValue:[sharedDefaults objectForKey:TKDefaultsKeyProfileTransportWalkMaxDuration] forKey:@"wm"];
  [paras setValue:[sharedDefaults objectForKey:TKDefaultsKeyProfileTransportTransferTime] forKey:@"tt"];
  [paras setValue:[sharedDefaults objectForKey:TKDefaultsKeyProfileTransportEmissions] forKey:@"co2"];
  if (TKSettings.ignoreCostToReturnCarHireVehicle) {
    [paras setValue:@(NO) forKey:@"2wirc"];
  }

  // beta features
  if ([sharedDefaults boolForKey:SVKDefaultsKeyProfileEnableFlights]) {
    [paras setValue:@(YES) forKey:@"ef"];
  }
  [paras setValue:@(YES) forKey:@"ir"];
  
#ifdef DEBUG
  NSNumber *bsbRaw = [sharedDefaults objectForKey:TKDefaultsKeyProfileBookingsUseSandbox];
  if (bsbRaw) {
    [paras setValue:bsbRaw forKey:@"bsb"];
  } else {
    [paras setValue:@(YES) forKey:@"bsb"]; // Default to Sandbox
  }
#else
  if ([SGKBetaHelper isBeta]
      && [sharedDefaults boolForKey:TKDefaultsKeyProfileBookingsUseSandbox]) {
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

    case TKSettingsProfileWeight_Exercise:
      [[NSUserDefaults sharedDefaults] setFloat:weight forKey:TKDefaultsKeyProfileWeightExercise];
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

+ (void)setEmissions:(float)gramsCO2PerKm forModeIdentifier:(NSString *)modeIdentifier
{
  NSMutableDictionary *mutable = nil;
  id previous = [[NSUserDefaults sharedDefaults] objectForKey:TKDefaultsKeyProfileTransportEmissions];
  if ([previous isKindOfClass:[NSDictionary class]]) {
    mutable = [NSMutableDictionary dictionaryWithDictionary:previous];
  } else {
    mutable = [NSMutableDictionary dictionaryWithCapacity:1];
  }
  [mutable setObject:@(gramsCO2PerKm) forKey:modeIdentifier];
  [[NSUserDefaults sharedDefaults] setObject:[NSDictionary dictionaryWithDictionary:mutable]
                                      forKey:TKDefaultsKeyProfileTransportEmissions];
}

@end
