//
//  TKSettings.h
//  TripGo
//
//  Created by Adrian Schoenig on 11/06/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, TKSettingsProfileWeight) {
  TKSettingsProfileWeight_Money,
  TKSettingsProfileWeight_Carbon,
  TKSettingsProfileWeight_Time,
  TKSettingsProfileWeight_Hassle
};

typedef NS_ENUM(NSInteger, TKSettingsSpeed) {
  TKSettingsSpeed_Slow = 0,
  TKSettingsSpeed_Average,
  TKSettingsSpeed_Fast,
};


@interface TKSettings : NSObject

+ (NSMutableDictionary *)defaultDictionary;

/**
 The maximum walking duration is a per-segment limit for mixed results, i.e., it does not apply to walking-only trips.
 
 @param duration Seconds
 */
+ (void)setMaximumWalkingDuration:(NSTimeInterval)duration;

/**
 The minimum transfer duration applies for trips with more than one public transport segment. It sets the minimum time that the user needs to arrive at every public transport segment after the first one.
 @param duration Seconds, which will get rounded up to the next minute.
 */
+ (void)setMinimumTransferDuration:(NSTimeInterval)duration;

/**
 Sets the profile weight for a specific component. Each component should be in the range of [0.1, 2.0], otherwise this is enforced server side. Weights of the components are relative to each other.
 @param weight New weight, preferably in range [0.1, 2.0]
 @param component The component for which to set this weight.
 */
+ (void)setProfileWeight:(float)weight forComponent:(TKSettingsProfileWeight)component;

/**
 @param speed The new walking speed. Slow is roughly 2km/h, average 4km/h, fast 6km/h.
 */
+ (void)setWalkingSpeed:(TKSettingsSpeed)speed;

/**
 @param speed The new cycling speed. Slow is roughly 8km/h, average 12km/h, fast 25km/h.
 */
+ (void)setCyclingSpeed:(TKSettingsSpeed)speed;

@end
