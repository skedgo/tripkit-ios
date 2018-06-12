//
//  StopVisits.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 24/11/12.
//
//

@import Foundation;
@import CoreData;

#import "TKRealTimeUpdatable.h"

typedef NS_ENUM(NSInteger, StopVisitRealTime) {
  StopVisitRealTimeNotApplicable, // We don't have real-time for this kind of service
  StopVisitRealTimeNotAvailable,  // Services like this can have real-time, but this doesn't
  StopVisitRealTimeOnTime,
  StopVisitRealTimeEarly,
  StopVisitRealTimeLate,
  StopVisitRealTimeCancelled
};


@class Service, Shape, StopLocation;

NS_ASSUME_NONNULL_BEGIN

@interface StopVisits : NSManagedObject <TKRealTimeUpdatable>

@property (nonatomic, retain, nullable) NSDate * arrival;
@property (nonatomic, retain, nullable) NSNumber * bearing;
@property (nonatomic, retain, nullable) NSDate * departure;
@property (nonatomic, retain, nullable) NSDate * originalTime;
@property (nonatomic, retain) NSNumber * flags;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSNumber * isActive;
@property (nonatomic, retain, nullable) NSDate * regionDay;
@property (nonatomic, retain, nullable) NSString * searchString;
@property (nonatomic, assign) BOOL toDelete;
@property (nonatomic, retain) Service *service;
@property (nonatomic, retain) StopLocation *stop;
@property (nonatomic, retain, nullable) NSSet *shapes;

+ (NSArray<StopVisits *> *)fetchStopVisitsForStopLocation:(StopLocation *)stopLocation
                                         startingFromDate:(NSDate *)earliestDate;

- (void)remove;

+ (NSArray<NSSortDescriptor *> *)defaultSortDescriptors;

+ (NSPredicate *)departuresPredicateForStops:(NSArray<StopLocation *> *)stops
                                    fromDate:(NSDate *)date
                                      filter:(nullable NSString *)filter;

- (void)adjustRegionDay;

- (NSString *)smsString;

// Frequency information, platform, service name
- (NSString *)secondaryInformation;

- (StopVisitRealTime)realTimeStatus;

- (nullable NSString *)realTimeInformation:(BOOL)withOriginalTime;

- (nullable NSDate *)countdownDate;

/**
 Compares two visits based on which one comes before another in the same service.
 
 @warning This throws an error if the visits are incomparable, i.e., if they are from
 
 @param other `StopVisit` of the same service to compare to
 
 @return ascending if self is before other, same if they are equal, descending if self is after other.
 */
- (NSComparisonResult)compare:(StopVisits *)other;

@end

@interface StopVisits (CoreDataGeneratedAccessors)

- (void)addShapesObject:(Shape *)value;
- (void)removeShapesObject:(Shape *)value;
- (void)addShapes:(NSSet *)values;
- (void)removeShapes:(NSSet *)values;

@end

NS_ASSUME_NONNULL_END
