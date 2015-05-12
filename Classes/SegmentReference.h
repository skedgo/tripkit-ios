//
//  SegmentReference.h
//  TripGo
//
//  Created by Adrian Schönig on 10/05/12.
//  Copyright (c) 2012 SkedGo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Trip, SegmentTemplate, Service;
@protocol STKVehicular;

@interface SegmentReference : NSManagedObject

#pragma mark CoreData

@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSDate * endTime;
@property (nonatomic, strong) NSNumber * flags;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSNumber * templateHashCode;
@property (nonatomic, retain) NSDictionary *data;
@property (nonatomic, assign) BOOL toDelete;
@property (nonatomic, retain) NSArray * alertHashCodes;
@property (nonatomic, retain) SegmentTemplate *segmentTemplate;
@property (nonatomic, retain) Trip *trip;
@property (nonatomic, retain) Service *service;

#pragma mark Helper

@property (nonatomic, copy) NSString *vehicleUUID;
@property (nonatomic, copy) NSDictionary *bookingData;
@property (nonatomic, copy) NSDictionary *sharedVehicleData;

@property (nonatomic, assign) BOOL timesAreRealTime;

+ (void)removeOrphansFromManagedObjectContext:(NSManagedObjectContext *)context;

- (void)remove;

- (SegmentTemplate *)template;

- (void)setVehicle:(id<STKVehicular>)vehicle;
- (id<STKVehicular>)vehicleFromAllVehicles:(NSArray *)allVehicles;

@end
