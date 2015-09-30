//
//  SegmentReference.m
//  TripGo
//
//  Created by Adrian Schönig on 10/05/12.
//  Copyright (c) 2012 SkedGo. All rights reserved.
//

#import "SegmentReference.h"

#import "TKTripKit.h"

enum {
  SGSegmentFlagTimesAreRealtime = 1 << 0,
};
typedef NSUInteger SGSegmentFlag;


@implementation SegmentReference

@dynamic startTime, endTime;
@dynamic flags;
@dynamic index;
@dynamic templateHashCode;
@dynamic alertHashCodes;
@dynamic segmentTemplate;
@dynamic data;
@dynamic toDelete;
@dynamic trip;
@dynamic service;

+ (void)removeOrphansFromManagedObjectContext:(NSManagedObjectContext *)context
{
	NSSet *objects;
	
	// delete any segment references without a trip
	objects = [context fetchObjectsForEntityClass:self
														withPredicateString:@"toDelete = NO AND trip == nil"];
	for (SegmentReference *reference in objects) {
		DLog(@"Deleting segment reference without a trip: %@", reference);
    [reference remove];
	}
}

- (void)remove
{
  self.toDelete = YES;
}

- (SegmentTemplate *)template
{
  if (self.segmentTemplate) {
    return self.segmentTemplate;
  }
	
	if (! self.templateHashCode) {
		return nil; // this gotta be a terminal
	}
  
  // link up to segment template
	self.segmentTemplate = [SegmentTemplate fetchSegmentTemplateWithHashCode:self.templateHashCode inTripKitContext:self.managedObjectContext];
	return self.segmentTemplate;
}

- (id<STKVehicular>)vehicleFromAllVehicles:(NSArray *)allVehicles
{
  NSString *vehicleUUID = [self vehicleUUID];
  if (vehicleUUID) {
    for (id<STKVehicular> vehicle in allVehicles) {
      if ([vehicle respondsToSelector:@selector(vehicleUUID)]
          && [[vehicle vehicleUUID] isEqualToString:vehicleUUID]) {
        return vehicle;
      }
    }
  }
  return nil;
}

- (void)setVehicle:(id<STKVehicular>)vehicle
{
  if ([vehicle respondsToSelector:@selector(vehicleUUID)]) {
    self.vehicleUUID = [vehicle vehicleUUID];
  } else {
    self.vehicleUUID = nil;
  }
}

- (NSString *)vehicleUUID
{
  return [self dataForKey:@"vehicleUUID"];
}

- (void)setVehicleUUID:(NSString *)vehicleUUID
{
  [self setData:vehicleUUID forKey:@"vehicleUUID"];
}

- (NSDictionary *)bookingData
{
  return [self dataForKey:@"booking"];
}

- (void)setBookingData:(NSDictionary *)data
{
  [self setData:data forKey:@"booking"];
}

- (NSDictionary *)sharedVehicleData
{
  return [self dataForKey:@"sharedVehicle"];
}

- (void)setSharedVehicleData:(NSDictionary *)data
{
  [self setData:data forKey:@"sharedVehicle"];
}

- (NSString *)ticketWebsiteURLString
{
  return [self dataForKey:@"ticketWebsiteURL"];
}

- (void)setTicketWebsiteURLString:(NSString *)ticketWebsiteURLString
{
  [self setData:ticketWebsiteURLString forKey:@"ticketWebsiteURL"];
}

- (NSString *)departurePlatform
{
  return [self dataForKey:@"departurePlatform"];
}

- (void)setDeparturePlatform:(NSString *)departurePlatform
{
  [self setData:departurePlatform forKey:@"departurePlatform"];
}

- (NSNumber *)serviceStops
{
  return [self dataForKey:@"serviceStops"];
}

- (void)setServiceStops:(NSNumber *)serviceStops
{
  [self setData:serviceStops forKey:@"serviceStops"];
}

- (void)setPayload:(id)payload forKey:(NSString *)key
{
  [self setData:payload forKey:key];
}

- (id)payloadForKey:(NSString *)key
{
  return [self dataForKey:key];
}

- (BOOL)timesAreRealTime
{
  return [self hasFlag:SGSegmentFlagTimesAreRealtime];
}

- (void)setTimesAreRealTime:(BOOL)timesAreRealTime
{
  [self setFlag:SGSegmentFlagTimesAreRealtime to:timesAreRealTime];
}

#pragma mark - Data

- (id)dataForKey:(NSString *)key
{
  NSDictionary *dataDictionary = [self mutableDataDictionary];
  if (dataDictionary) {
    return dataDictionary[key];
  } else {
    return nil;
  }
}

- (void)setData:(id)data forKey:(NSString *)key
{
  if ([data conformsToProtocol:@protocol(NSCoding)]) {
    NSMutableDictionary *mutable = [self mutableDataDictionary];
    mutable[key] = data;
    [self setMutableDataDictionary:mutable];

  } else if (data == nil) {
    NSMutableDictionary *mutable = [self mutableDataDictionary];
    [mutable removeObjectForKey:key];
    [self setMutableDataDictionary:mutable];
  }
}

- (void)setMutableDataDictionary:(NSMutableDictionary *)mutable
{
  self.data = [NSKeyedArchiver archivedDataWithRootObject:mutable];
}

- (NSMutableDictionary *)mutableDataDictionary
{
  if ([self.data isKindOfClass:[NSMutableDictionary class]]) { // Deprecated
    return self.data;
  
  } else if ([self.data isKindOfClass:[NSDictionary class]]) { // Deprecated
    return [NSMutableDictionary dictionaryWithDictionary:self.data];
    
  } else if ([self.data isKindOfClass:[NSData class]]) {
    id object = [NSKeyedUnarchiver unarchiveObjectWithData:self.data];
    if ([object isKindOfClass:[NSMutableDictionary class]]) {
      return object;
    } else {
      ZAssert(false, @"Unexpected data: %@", self.data);
    }
  }
  return [NSMutableDictionary dictionaryWithCapacity:1];
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
