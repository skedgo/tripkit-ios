//
//  TKSettings.m
//  TripKit
//
//  Created by Adrian Schoenig on 11/06/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "TKSettings.h"

#import "TKBetaHelper.h"

#import <TripKit/TripKit-Swift.h>

@implementation TKSettings

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
