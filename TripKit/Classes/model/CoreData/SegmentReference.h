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
@protocol TKVehicular;

NS_ASSUME_NONNULL_BEGIN

/// A time-dependent pointer to the time-independent `SegmentTemplate`
/// :nodoc:
@interface SegmentReference : NSManagedObject

#pragma mark CoreData

@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSDate * endTime;
@property (nonatomic, strong) NSNumber * flags;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSNumber * templateHashCode;
@property (nonatomic, retain, nullable) NSNumber * bookingHashCode;
@property (nonatomic, retain, nullable) NSData * data;
@property (nonatomic, retain, nullable) NSArray<NSNumber *> * alertHashCodes;
@property (nonatomic, retain, nullable) SegmentTemplate *segmentTemplate;
@property (nonatomic, retain, null_resettable) Trip *trip;
@property (nonatomic, retain, nullable) Service *service;
@property (nonatomic, retain, nullable) Vehicle *realTimeVehicle;
@property (nonatomic, retain, nullable) NSSet<Vehicle *> *realTimeVehicleAlternatives;

#pragma mark Helper

@property (nonatomic, assign) BOOL timesAreRealTime;
@property (nonatomic, assign, getter = isBicycleAccessible) BOOL bicycleAccessible;

@property (nonatomic, assign, getter = isWheelchairAccessible) BOOL wheelchairAccessible;
@property (nonatomic, assign, getter = isWheelchairInaccessible) BOOL wheelchairInaccessible;

- (null_unspecified SegmentTemplate *)template;

- (void)setVehicle:(nullable id<TKVehicular>)vehicle;
- (nullable id<TKVehicular>)vehicleFromAllVehicles:(NSArray<id<TKVehicular>> *)allVehicles;

@end

/// :nodoc:
@interface SegmentReference (CoreDataGeneratedAccessors)

- (void)addRealTimeVehicleAlternativesObject:(Vehicle *)value;
- (void)removeRealTimeVehicleAlternativesObject:(Vehicle *)value;
- (void)addRealTimeVehicleAlternatives:(NSSet *)values;
- (void)removeRealTimeVehicleAlternatives:(NSSet *)values;

@end

NS_ASSUME_NONNULL_END
