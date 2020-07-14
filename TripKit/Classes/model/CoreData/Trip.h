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


@class Alert, TKRegion, StopVisits, TripRequest, TripGroup, BHRoutingRequest;

@interface Trip : NSManagedObject {
}

+ (nullable Trip *)findSimilarTripTo:(nonnull Trip *)trip
                              inList:(nonnull id<NSFastEnumeration>)trips;

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

@property (nonatomic, assign) BOOL isCanceled;

/**
 @note Only includes walking if it's a walking-only trip!
 @return Set of used mode identifiers.
 */
- (nonnull NSSet<NSString *> *)usedModeIdentifiers;

@property (readonly) BOOL allowImpossibleSegments;

/* Offset in minutes from the specified departure/arrival time.
 * E.g., if you asked for arrive-by, it'll use the arrival time.
 *
 * If the trip does not satisfy the requested time, it's negative.
 */
- (NSTimeInterval)calculateOffset;

/* Trip duration, i.e., time between departure and arrival. 
 */
- (nonnull NSNumber *)calculateDuration;

- (nonnull NSString *)constructPlainText;

- (nonnull NSDictionary<NSNumber *, NSString *> *)accessibleCostValues;

- (nonnull NSString *)debugString;

#pragma mark - Segment accessors

/* Returns all associated segment in their correct order.
 */
@property (nonnull, readonly) NSArray<TKSegment *> *segments;

/* The first major segment of the trip, according to segment properties (use mainSegment() instead)
 */
- (nullable TKSegment *)inferMainSegment;

/* Call this before changing the segments of a trip.
 */
- (void)clearSegmentCaches;

/* The first public transport segment of the trip
 */
@property (readonly, nullable) TKSegment *firstPublicTransport;

/* All public transport segments of the trip
 */
@property (nonnull, readonly) NSArray<TKSegment *> *allPublicTransport;

#pragma mark - Visualising trips on the map

- (BOOL)usesVisit:(nonnull StopVisits *)visit;

- (BOOL)shouldShowVisit:(nonnull StopVisits *)visit;

#pragma mark - Real-time stuff

@property (readonly) BOOL isImpossible;

@property (readonly) BOOL timesAreRealTime;

@property (nullable, readonly) Alert *primaryAlert;

@end
