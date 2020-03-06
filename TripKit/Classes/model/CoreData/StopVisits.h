//
//  StopVisits.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 24/11/12.
//
//

@import Foundation;
@import CoreData;

typedef NS_CLOSED_ENUM(NSInteger, TKStopVisitRealTime) {
  TKStopVisitRealTimeNotApplicable, // We don't have real-time for this kind of service
  TKStopVisitRealTimeNotAvailable,  // Services like this can have real-time, but this doesn't
  TKStopVisitRealTimeOnTime,
  TKStopVisitRealTimeEarly,
  TKStopVisitRealTimeLate,
  TKStopVisitRealTimeCancelled
};


@class Service, Shape, StopLocation;

NS_ASSUME_NONNULL_BEGIN

/// Represents a public transport service stopping at a particular stop (at a particular time)
@interface StopVisits : NSManagedObject

#pragma mark - Class methods

+ (NSArray<NSSortDescriptor *> *)defaultSortDescriptors;

+ (NSPredicate *)departuresPredicateForStops:(NSArray<StopLocation *> *)stops
                                    fromDate:(NSDate *)date
                                      filter:(nullable NSString *)filter;

#pragma mark - CoreData fields

/// - warn: Ambiguous. Use .timing instead
/// :nodoc:
@property (nonatomic, retain, nullable) NSDate * arrival; // DEPRECATED_MSG_ATTRIBUTE("Ambiguous. Use .timing instead");

@property (nonatomic, retain, nullable) NSNumber * bearing;

/// - warn: Ambiguous. Use .timing instead
/// :nodoc:
@property (nonatomic, retain, nullable) NSDate * departure; // DEPRECATED_MSG_ATTRIBUTE("Ambiguous. Use .timing instead");

@property (nonatomic, retain, nullable) NSDate * originalTime;

/// :nodoc:
@property (nonatomic, retain) NSNumber * flags;

@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSNumber * isActive;
@property (nonatomic, retain, nullable) NSDate * regionDay;
@property (nonatomic, retain, nullable) NSString * searchString;

/// :nodoc:
@property (nonatomic, assign) BOOL toDelete;

@property (nonatomic, retain) Service *service;
@property (nonatomic, retain) StopLocation *stop;
@property (nonatomic, retain, nullable) NSSet *shapes;

#pragma mark - Instance fields + methods

/// Frequency information, platform, service name
@property (nonatomic, readonly) NSString *secondaryInformation;

@property (nonatomic, readonly) TKStopVisitRealTime realTimeStatus;

/// Time to count down to in a departures timetable. This is `nil` for frequency-based services, or if this is the final arrival at a stop.
@property (nonatomic, readonly, nullable) NSDate *countdownDate;

/// :nodoc:
- (void)remove;

/// :nodoc:
- (void)adjustRegionDay;

- (NSString *)realTimeInformation:(BOOL)withOriginalTime;

/**
 Compares two visits based on which one comes before another one.
 
 @param other `StopVisit` of the same service (or connected service) to compare to
 
 @return ascending if self is before other, same if they are equal, descending if self is after other.
 */
- (NSComparisonResult)compare:(StopVisits *)other;

@end

/// :nodoc:
@interface StopVisits (CoreDataGeneratedAccessors)

- (void)addShapesObject:(Shape *)value;
- (void)removeShapesObject:(Shape *)value;
- (void)addShapes:(NSSet *)values;
- (void)removeShapes:(NSSet *)values;

@end

NS_ASSUME_NONNULL_END
