//
//  Trip.h
//  TripGo
//
//  Created by Adrian Schönig on 3/03/11.
//  Copyright (c) 2011 SkedGo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "TKSegment.h"
#import "SegmentTemplate.h"
#import "TKRealTimeUpdatable.h"

#import "TKShareURLProvider.h"

#import "STKTripAndSegments.h"
#import "STKVehicular.h"

@class Alert, SVKRegion, StopVisits, TripRequest, TripGroup, BHRoutingRequest;

@interface Trip : NSManagedObject <TKRealTimeUpdatable, SGURLShareable, STKTrip, UIActivityItemSource> {
}

#pragma mark - CoreData elements

@property (nonatomic, strong, nonnull) NSDate * arrivalTime;
@property (nonatomic, strong, nonnull) NSDate * departureTime;
@property (nonatomic, strong, nonnull) NSNumber * minutes; // cache for sorting
@property (nonatomic, strong, nonnull) NSNumber * mainSegmentHashCode;

@property (nonatomic, strong, nonnull) NSNumber * flags;
@property (nonatomic, strong, nullable) NSString * saveURLString;
@property (nonatomic, strong, nullable) NSString * shareURLString;
@property (nonatomic, strong, nullable) NSString * updateURLString;
@property (nonatomic, strong, nullable) NSString * plannedURLString;
@property (nonatomic, strong, nullable) NSString * progressURLString;
@property (nonatomic, strong, nullable) NSString * temporaryURLString;
@property (nonatomic, retain, nonnull) NSNumber * totalCarbon;
@property (nonatomic, retain, nonnull) NSNumber * totalHassle;
@property (nonatomic, retain, nullable) NSNumber * totalPrice;
@property (nonatomic, retain, nullable) NSNumber * totalPriceUSD;
@property (nonatomic, strong, nullable) NSString * currencySymbol;
@property (nonatomic, retain, nullable) NSNumber * totalWalking;
@property (nonatomic, retain, nonnull) NSNumber * totalCalories;
@property (nonatomic, retain, nonnull) NSNumber * totalScore;
@property (nonatomic, assign) BOOL toDelete;

@property (nonatomic, retain, nonnull) NSSet *segmentReferences;
@property (nonatomic, strong, nullable) TripGroup * representedGroup;
@property (nonatomic, strong, nonnull) TripGroup * tripGroup;
@property (nonatomic, strong, nullable) NSManagedObject * tripTemplate;

+ (void)removeTripsBeforeDate:(nonnull NSDate *)date
		 fromManagedObjectContext:(nonnull NSManagedObjectContext *)context;

+ (nullable Trip *)findSimilarTripTo:(nonnull Trip *)trip
                              inList:(nonnull id<NSFastEnumeration>)trips;

- (void)remove;

#pragma mark - Trip properties

@property (nonatomic, readonly, nonnull) TripRequest *request;

- (void)setAsPreferredTrip;

@property (nonatomic, assign) BOOL showNoVehicleUUIDAsLift;

@property (nonatomic, assign) BOOL departureTimeIsFixed;

@property (nonatomic, assign) BOOL hasReminder;

/* Returns whether the annotation is one of the segment changes of this trip
 */
- (BOOL)changesAt:(nonnull id<MKAnnotation>) annotation;

/**
 @note Only includes walking if it's a walking-only trip!
 @return Set of used mode identifiers.
 */
- (nonnull NSSet *)usedModeIdentifiers;

/**
 @return Segments of this trip which do use a private (or shared) vehicle, i.e., those who return something from `usedVehicle`.
 */
- (nonnull NSSet *)vehicleSegments;

/**
 @return if the trip uses a personal vehicle (non shared) which the user might want to assign to one of their vehicles
 */
- (STKVehicleType)usedPrivateVehicleType;

- (BOOL)allowImpossibleSegments;

/**
 @param vehicle The vehicle to assign this trip to. `nil` to reset to a generic vehicle.
 */
- (void)assignVehicle:(nullable id<STKVehicular>)vehicle;

/* Offset in minutes from the specified departure/arrival time.
 * E.g., if you asked for arrive-by, it'll use the arrival time.
 *
 * If the trip does not satisfy the requested time, it's negative.
 */
- (NSTimeInterval)calculateOffset;

/* Duration in seconds from the specified departure/arrival time.
 * E.g., if you asked for arrive-by, it'll use the departure time.
 * Can be negative.
 */
- (NSTimeInterval)calculateDurationFromQuery;

/* Trip duration, i.e., time between departure and arrival. 
 */
- (nonnull NSNumber *)calculateDuration;

- (nonnull NSString *)constructPlainText;

- (nonnull NSString *)debugString;

#pragma mark - Segment accessors

/* Returns all associated segment in their correct order.
 */
- (nonnull NSArray *)segments;

/* The first major segment of the trip
 */
- (nonnull TKSegment *)mainSegment;

/* The first public transport segment of the trip
 */
- (nullable TKSegment *)firstPublicTransport;

/* All public transport segments of the trip
 */
- (nonnull NSArray *)allPublicTransport;

#pragma mark - Traffic light stuff

- (STKTripCostType)primaryCostType;

#pragma mark - Visualising trips on the map

- (BOOL)usesVisit:(nonnull StopVisits *)visit;

- (BOOL)shouldShowVisit:(nonnull StopVisits *)visit;

#pragma mark - Real-time stuff

- (BOOL)timesAreRealTime;

- (nullable Alert *)primaryAlert;

@end

@interface Trip (CoreDataGeneratedAccessors)

- (void)addSegmentReferencesObject:(nonnull SegmentReference *)value;
- (void)removeSegmentReferencesObject:(nonnull SegmentReference *)value;
- (void)addSegmentReferences:(nonnull NSSet *)values;
- (void)removeSegmentReferences:(nonnull NSSet *)values;

@end
