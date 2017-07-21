//
//  SegmentReference.h
//  TripKit
//
//  Created by Adrian Schönig on 10/05/12.
//  Copyright (c) 2012 SkedGo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Trip, SegmentTemplate, Service, Vehicle;
@protocol STKVehicular;

@interface SegmentReference : NSManagedObject

#pragma mark CoreData

@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSDate * endTime;
@property (nonatomic, strong) NSNumber * flags;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSNumber * templateHashCode;
@property (nonatomic, retain) id data; // NSData (or NSDictionary)
@property (nonatomic, assign) BOOL toDelete;
@property (nonatomic, retain) NSArray<NSString *> * alertHashCodes;
@property (nonatomic, retain) SegmentTemplate *segmentTemplate;
@property (nonatomic, retain) Trip *trip;
@property (nonatomic, retain) Service *service;
@property (nonatomic, retain) Vehicle *realTimeVehicle;
@property (nonatomic, retain) NSSet *realTimeVehicleAlternatives;

#pragma mark Helper

@property (nonatomic, copy) NSString *vehicleUUID;
@property (nonatomic, copy) NSDictionary *bookingData;
@property (nonatomic, copy) NSDictionary *sharedVehicleData;
@property (nonatomic, copy) NSString *ticketWebsiteURLString;
@property (nonatomic, copy) NSString *departurePlatform;
@property (nonatomic, copy) NSNumber *serviceStops;

@property (nonatomic, assign) BOOL timesAreRealTime;
@property (nonatomic, assign, getter = isBicycleAccessible) BOOL bicycleAccessible;
@property (nonatomic, assign, getter = isWheelchairAccessible) BOOL wheelchairAccessible;

+ (void)removeOrphansFromManagedObjectContext:(NSManagedObjectContext *)context;

- (void)remove;

- (SegmentTemplate *)template;

- (void)setVehicle:(id<STKVehicular>)vehicle;
- (id<STKVehicular>)vehicleFromAllVehicles:(NSArray<id<STKVehicular>> *)allVehicles;

- (void)setPayload:(id)payload forKey:(NSString *)key;
- (id)payloadForKey:(NSString *)key;

@end

@interface SegmentReference (CoreDataGeneratedAccessors)

- (void)addRealTimeVehicleAlternativesObject:(Vehicle *)value;
- (void)RealTimeVehicleAlternatives:(Vehicle *)value;
- (void)addRealTimeVehicleAlternatives:(NSSet *)values;
- (void)removeRealTimeVehicleAlternatives:(NSSet *)values;

@end
