//
//  Trip.h
//  TripKit
//
//  Created by Adrian Schönig on 3/03/11.
//  Copyright (c) 2011 SkedGo. All rights reserved.
//

@import Foundation;
@import CoreData;

#import "TKSegment.h"
#import "TKRealTimeUpdatable.h"


@class Alert, SVKRegion, StopVisits, TripRequest, TripGroup, BHRoutingRequest;

@interface Trip : NSManagedObject <TKRealTimeUpdatable> {
}

#pragma mark - CoreData elements

@property (nonatomic, copy, nonnull) NSDate * arrivalTime;
@property (nonatomic, copy, nonnull) NSDate * departureTime;
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

@property (nonatomic, strong, nullable) NSURL *shareURL;

@property (nonatomic, strong, nullable, readonly) NSURL *saveURL;

/**
 Checks if trip is in a usable state for CoreData. Bit of an ugly check to use
 in rare cases before accessing nonnull fields on a Trip object that might have
 seen disappeared from CoreData (and would then crash when using from Swift).
 */
@property (nonatomic, readonly) BOOL isValid;

- (void)setAsPreferredTrip;

@property (nonatomic, assign) BOOL showNoVehicleUUIDAsLift;

@property (nonatomic, assign) BOOL departureTimeIsFixed;

@property (nonatomic, assign) BOOL hasReminder;

@property (nonatomic, assign) BOOL missedBookingWindow;


- (void)removeFromRequest;

- (void)moveToRequest:(nonnull TripRequest *)request markAsPreferred:(BOOL)preferred;

/* Returns whether the annotation is one of the segment changes of this trip
 */
- (BOOL)changesAt:(nonnull id<MKAnnotation>) annotation;

/**
 @note Only includes walking if it's a walking-only trip!
 @return Set of used mode identifiers.
 */
- (nonnull NSSet *)usedModeIdentifiers;

- (BOOL)allowImpossibleSegments;

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

- (nonnull NSDictionary<NSNumber *, NSString *> *)accessibleCostValues;

- (nonnull NSString *)debugString;

#pragma mark - Segment accessors

/* Returns all associated segment in their correct order.
 */
- (nonnull NSArray<TKSegment *> *)segments;

/* The first major segment of the trip, according to segment properties (use mainSegment() instead)
 */
- (nonnull TKSegment *)inferMainSegment;

/* Call this before changing the segments of a trip.
 */
- (void)clearSegmentCaches;

/* The first public transport segment of the trip
 */
- (nullable TKSegment *)firstPublicTransport;

/* All public transport segments of the trip
 */
- (nonnull NSArray<TKSegment *> *)allPublicTransport;

#pragma mark - Visualising trips on the map

- (BOOL)usesVisit:(nonnull StopVisits *)visit;

- (BOOL)shouldShowVisit:(nonnull StopVisits *)visit;

#pragma mark - Real-time stuff

- (BOOL)isImpossible;

- (BOOL)timesAreRealTime;

- (nullable Alert *)primaryAlert;

@end

@interface Trip (CoreDataGeneratedAccessors)

- (void)addSegmentReferencesObject:(nonnull SegmentReference *)value;
- (void)removeSegmentReferencesObject:(nonnull SegmentReference *)value;
- (void)addSegmentReferences:(nonnull NSSet *)values;
- (void)removeSegmentReferences:(nonnull NSSet *)values;

@end
