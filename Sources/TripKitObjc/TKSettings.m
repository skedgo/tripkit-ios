//
//  TKSettings.m
//  TripKit
//
//  Created by Adrian Schoenig on 11/06/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#if SWIFT_PACKAGE
#import <TripKitObjc/NSUserDefaults+SharedDefaults.h>
#import <TripKitObjc/TKSettings.h>
#import <TripKitObjc/TKConstants.h>
#else
#import "TKSettings.h"
#import "TKConstants.h"
#import "NSUserDefaults+SharedDefaults.h"
#endif

@implementation TKSettings

+ (void)setMaximumWalkingDuration:(NSTimeInterval)duration
{
  NSInteger minutes = (NSInteger) ((duration + 59) / 60);
  [[NSUserDefaults sharedDefaults] setDouble:minutes forKey:TKDefaultsKeyProfileTransportWalkMaxDuration];
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
