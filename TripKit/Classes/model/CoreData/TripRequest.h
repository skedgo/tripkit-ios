//
//  Trip.h
//  TripKit
//
//  Created by Adrian Schönig on 9/03/11.
//  Copyright (c) 2011 SkedGo. All rights reserved.
//

@import CoreData;
@import MapKit;

#import <TripKit/TripGroup.h>

@class TKRegion, TKNamedCoordinate, Trip;

NS_ASSUME_NONNULL_BEGIN

@interface TripRequest : NSManagedObject

@property (nonatomic, retain) TKNamedCoordinate *fromLocation;
@property (nonatomic, retain) TKNamedCoordinate *toLocation;
@property (nonatomic, retain, nullable) NSString *purpose;
@property (nonatomic, retain, nullable) TripGroup *preferredGroup;
@property (nonatomic, strong, nullable) NSDate * arrivalTime;
@property (nonatomic, strong, nullable) NSDate * departureTime;
@property (nonatomic, strong) NSDate * timeCreated;
@property (nonatomic, strong) NSNumber * timeType;
@property (nonatomic, assign) BOOL expandForFavorite;
@property (nonatomic, retain) NSArray<NSString *> *excludedStops;

@property (nonatomic, strong, nullable) NSSet <TripGroup *> * tripGroups;

/**
 * Non Core Data property
 */

@property (nonatomic, assign) TKTripGroupVisibility defaultVisibility;

- (BOOL)resultsInSameQueryAs:(TripRequest *)other;

@property (nonatomic, strong, nullable) TripGroup *lastSelection;
@property (nonatomic, strong, nullable) Trip *preferredTrip;

- (void)adjustVisibilityForMinimizedModeIdentifiers:(NSSet *)minimized
                              hiddenModeIdentifiers:(NSSet *)hidden;

/**
 @return The region the complete trip takes place in. Can be international if it spanning more than one region.
 */
- (TKRegion *)spanningRegion;

/**
 @return The local region this trip starts in. Cannot be international and thus might be nil.
 */
- (nullable TKRegion *)startRegion;

/**
 @return The local region this trip ends in. Cannot be international and thus might be nil.
 */
- (nullable TKRegion *)endRegion;

- (NSArray <NSString *> *)applicableModeIdentifiers;

- (nullable NSTimeZone *)departureTimeZone;

- (nullable NSTimeZone *)arrivalTimeZone;

- (NSString *)timeSorterTitle;

- (BOOL)hasTrips;

/**
 @return If any trip has pricing information. Also returns `YES` if there are no trips.
 */
- (BOOL)priceInformationAvailable;

- (NSString *)debugString;

@end

@interface TripRequest (CoreDataGeneratedAccessors)

- (void)addTripGroupObject:(TripGroup *)value;
- (void)removeTripGroupObject:(TripGroup *)value;
- (void)addTripGroups:(NSSet *)values;
- (void)removeTripGroups:(NSSet *)values;

- (void)addRouteObject:(Trip *)value;
- (void)removeRouteObject:(Trip *)value;
- (void)addRoutes:(NSSet <Trip *> *)values;
- (void)removeRoutes:(NSSet <Trip *> *)values;
@end

NS_ASSUME_NONNULL_END
