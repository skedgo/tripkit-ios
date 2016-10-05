//
//  Trip.h
//  TripGo
//
//  Created by Adrian Schönig on 9/03/11.
//  Copyright (c) 2011 SkedGo. All rights reserved.
//

@import CoreData;
@import MapKit;
@import SGCoreKit;

#import "TripGroup.h"

@class SVKRegion, SGNamedCoordinate, Trip;

NS_ASSUME_NONNULL_BEGIN

@interface TripRequest : NSManagedObject

@property (nonatomic, retain) SGNamedCoordinate *fromLocation;
@property (nonatomic, retain) SGNamedCoordinate *toLocation;
@property (nonatomic, retain, nullable) NSString *purpose;
@property (nonatomic, retain, nullable) TripGroup *preferredGroup;
@property (nonatomic, strong, nullable) NSDate * arrivalTime;
@property (nonatomic, strong, nullable) NSDate * departureTime;
@property (nonatomic, strong) NSDate * timeCreated;
@property (nonatomic, strong) NSNumber * timeType;
@property (nonatomic, assign) BOOL expandForFavorite;
@property (nonatomic, assign) BOOL toDelete;

@property (nonatomic, strong, nullable) NSSet <TripGroup *> * tripGroups;

/**
 * Non Core Data property
 */

@property (nonatomic, readonly, nullable) NSSet <Trip *> * trips;
@property (nonatomic, readonly) SGTimeType type;
@property (nonatomic, readonly) NSDate *time;
@property (nonatomic, weak, nullable) TripRequest *replacement;
@property (nonatomic, assign) TripGroupVisibility defaultVisibility;

+ (TripRequest *)insertRequestIntoTripKitContext:(NSManagedObjectContext *)context;

+ (TripRequest *)insertRequestFrom:(id<MKAnnotation>)fromLocation
                                to:(id<MKAnnotation>)toLocation
													 forTime:(nullable NSDate *)time
                        ofTimeType:(SGTimeType)timeType
                intoTripKitContext:(NSManagedObjectContext *)context;

+ (NSString *)timeStringForTime:(nullable NSDate *)time
                     ofTimeType:(SGTimeType)timeType
                       timeZone:(NSTimeZone *)timeZone;

- (TripRequest *)insertedEmptyCopy;

- (void)remove;

- (BOOL)resultsInSameQueryAs:(TripRequest *)other;

@property (nonatomic, strong, nullable) TripGroup *lastSelection;
@property (nonatomic, strong, nullable) Trip *preferredTrip;

- (void)adjustVisibilityForMinimizedModeIdentifiers:(NSSet *)minimized
                              hiddenModeIdentifiers:(NSSet *)hidden;

/**
 @return The region the complete trip takes place in. Can be international if it spanning more than one region.
 */
- (SVKRegion *)spanningRegion;

/**
 @return The local region this trip takes place in. Cannot be international and thus might be nil.
 */
- (nullable SVKRegion *)localRegion;

- (NSArray <NSString *> *)applicableModeIdentifiers;

- (nullable NSTimeZone *)departureTimeZone;

- (nullable NSTimeZone *)arrivalTimeZone;

- (NSString *)timeSorterTitle;

- (NSString *)timeString;

/* Set the time and type for this request.
 */
- (void)setTime:(NSDate *)time forType:(SGTimeType)type;

- (BOOL)hasTrips;

/**
 @return If any trip has pricing information. Also returns `YES` if there are no trips.
 */
- (BOOL)priceInformationAvailable;

- (NSArray<NSSortDescriptor *> *)sortDescriptorsAccordingToSelectedOrder;

- (NSArray<NSSortDescriptor *> *)sortDescriptorsWithPrimary:(STKTripCostType)primary;


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
