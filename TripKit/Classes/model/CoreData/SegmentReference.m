//
//  SegmentReference.m
//  TripKit
//
//  Created by Adrian Schönig on 10/05/12.
//  Copyright (c) 2012 SkedGo. All rights reserved.
//

#import "SegmentReference.h"

#import <TripKit/TripKit-Swift.h>

enum {
  SGSegmentFlagTimesAreRealtime       = 1 << 0,
  SGSegmentFlagBicycleAccessible      = 1 << 1,
  SGSegmentFlagWheelchairAccessible   = 1 << 2,
  SGSegmentFlagWheelchairInaccessible = 1 << 3,
};
typedef NSUInteger SGSegmentFlag;


@implementation SegmentReference

@dynamic startTime, endTime;
@dynamic flags;
@dynamic index;
@dynamic templateHashCode;
@dynamic bookingHashCode;
@dynamic alertHashCodes;
@dynamic segmentTemplate;
@dynamic data;
@dynamic trip;
@dynamic service;
@dynamic realTimeVehicle, realTimeVehicleAlternatives;

- (SegmentTemplate *)template
{
  if (self.segmentTemplate) {
    return self.segmentTemplate;
  }
	
	if (! self.templateHashCode) {
    [TKLog debug:@"TKSegmentReference" text:[NSString stringWithFormat:@"Deleting segment reference without a hash code: %@", self]];
		return nil;
	}
  
  // link up to segment template
	self.segmentTemplate = [SegmentTemplate fetchSegmentTemplateWithHashCode:self.templateHashCode.integerValue inTripKitContext:self.managedObjectContext];
	return self.segmentTemplate;
}

- (id<TKVehicular>)vehicleFromAllVehicles:(NSArray *)allVehicles
{
  NSString *vehicleUUID = [self vehicleUUID];
  if (vehicleUUID) {
    for (id<TKVehicular> vehicle in allVehicles) {
      if ([vehicle respondsToSelector:@selector(vehicleUUID)]
          && [[vehicle vehicleUUID] isEqualToString:vehicleUUID]) {
        return vehicle;
      }
    }
  }
  return nil;
}

- (void)setVehicle:(id<TKVehicular>)vehicle
{
  if ([vehicle respondsToSelector:@selector(vehicleUUID)]) {
    self.vehicleUUID = [vehicle vehicleUUID];
  } else {
    self.vehicleUUID = nil;
  }
}

- (BOOL)timesAreRealTime
{
  return [self hasFlag:SGSegmentFlagTimesAreRealtime];
}

- (void)setTimesAreRealTime:(BOOL)timesAreRealTime
{
  [self setFlag:SGSegmentFlagTimesAreRealtime to:timesAreRealTime];
}

- (BOOL)isBicycleAccessible
{
  return [self hasFlag:SGSegmentFlagBicycleAccessible];
}

- (void)setBicycleAccessible:(BOOL)bicycleAccessible
{
  [self setFlag:SGSegmentFlagBicycleAccessible to:bicycleAccessible];
}

- (BOOL)isWheelchairAccessible
{
  return [self hasFlag:SGSegmentFlagWheelchairAccessible];
}

- (void)setWheelchairAccessible:(BOOL)wheelchairAccessible
{
  [self setFlag:SGSegmentFlagWheelchairAccessible to:wheelchairAccessible];
}

- (BOOL)isWheelchairInaccessible
{
  return [self hasFlag:SGSegmentFlagWheelchairInaccessible];
}

- (void)setWheelchairInaccessible:(BOOL)wheelchairInaccessible
{
  [self setFlag:SGSegmentFlagWheelchairInaccessible to:wheelchairInaccessible];
}

#pragma mark - Flags

- (BOOL)hasFlag:(SGSegmentFlag)flag
{
  return 0 != (self.flags.integerValue & flag);
}

- (void)setFlag:(SGSegmentFlag)flag to:(BOOL)value
{
  SGSegmentFlag flags = (SGSegmentFlag) self.flags.integerValue;
  if (value) {
    self.flags = @(flags | flag);
  } else {
    self.flags = @(flags & ~flag);
  }
}

@end
