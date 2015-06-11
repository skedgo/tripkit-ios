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
  [paras setValue:[SGKConfig regionEligibility] forKey:@"app"];
  
  // distance units
  NSString *unit = nil;
  switch ([sharedDefaults integerForKey:SVKDefaultsKeyProfileDistanceUnit]) {
    case SGDistanceUnitTypeAuto:
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
  NSString *weightString = [NSString stringWithFormat:@"(%f,%f,%f,%f)", priceWeight, carbonWeight, timeWeight, hassleWeight];
  [paras setValue:weightString forKey:@"wp"];
  
  // transport preferences
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
  if ([sharedDefaults boolForKey:SVKDefaultsKeyProfileEnableInterregional]) {
    [paras setValue:@(YES) forKey:@"ir"];
  }
  
  [paras setValue:@(! [sharedDefaults boolForKey:TKDefaultsKeyProfileEnableRealBookings]) forKey:@"bsb"];
  return paras;
}

+ (void)setMaximumWalkingDuration:(NSTimeInterval)duration
{
  [[NSUserDefaults sharedDefaults] setDouble:duration forKey:TKDefaultsKeyProfileTransportWalkMaxDuration];
}

@end
