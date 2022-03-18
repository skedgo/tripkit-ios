//
//  TKSettings.h
//  TripKit
//
//  Created by Adrian Schoenig on 11/06/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, TKSettingsSpeed) {
  TKSettingsSpeed_Slow = 0,
  TKSettingsSpeed_Average,
  TKSettingsSpeed_Fast,
};

NS_ASSUME_NONNULL_BEGIN

@interface TKSettings : NSObject

/**
 The maximum walking duration is a per-segment limit for mixed results, i.e., it does not apply to walking-only trips.
 
 @param duration Seconds
 */
+ (void)setMaximumWalkingDuration:(NSTimeInterval)duration;

/**
 @param gramsCO2PerKm Emissions for supplied mode identifier in grams of CO2 per kilometre
 @param modeIdentifier Mode identifier for which to apply these emissions
 */
+ (void)setEmissions:(float)gramsCO2PerKm forModeIdentifier:(NSString *)modeIdentifier;

@end

NS_ASSUME_NONNULL_END
