//
//  StopVisits.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 24/11/12.
//
//

@import Foundation;
@import CoreData;
@import SkedGoKit;

#import "TKRealTimeUpdatable.h"
#import "TKShareURLProvider.h"

typedef NS_ENUM(NSInteger, StopVisitRealTime) {
  StopVisitRealTime_NotApplicable, // We don't have real-time for this kind of service
  StopVisitRealTime_NotAvailable,  // Services like this can have real-time, but this doesn't
  StopVisitRealTime_OnTime,
  StopVisitRealTime_Early,
  StopVisitRealTime_Late,
};


@class Service, Shape, StopLocation;

@interface StopVisits : NSManagedObject <STKDirectionalTimePoint, TKRealTimeUpdatable, SGURLShareable, UIActivityItemSource>

@property (nonatomic, retain) NSDate * arrival;
@property (nonatomic, retain) NSNumber * bearing;
@property (nonatomic, retain) NSDate * departure;
@property (nonatomic, retain) NSDate * originalTime;
@property (nonatomic, retain) NSNumber * flags;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSNumber * isActive;
@property (nonatomic, retain) NSDate * regionDay;
@property (nonatomic, retain) NSString * searchString;
@property (nonatomic, assign) BOOL toDelete;
@property (nonatomic, retain) Service *service;
@property (nonatomic, retain) StopLocation *stop;
@property (nonatomic, retain) NSSet *shapes;

// KVO
@property (nonatomic, strong) NSDate *time;

+ (NSArray<StopVisits *> *)fetchStopVisitsForStopLocation:(StopLocation *)stopLocation
                                         startingFromDate:(NSDate *)earliestDate;

- (void)remove;

+ (NSArray<NSSortDescriptor *> *)defaultSortDescriptors;

+ (NSPredicate *)departuresPredicateForStops:(NSArray<StopLocation *> *)stops
                                    fromDate:(NSDate *)date
                                      filter:(NSString *)filter;

- (void)adjustRegionDay;

- (NSString *)smsString;

// Frequency information, platform, service name
- (NSString *)secondaryInformation;

- (StopVisitRealTime)realTimeStatus;

- (NSString *)realTimeInformation:(BOOL)withOriginalTime;

- (NSDate *)countdownDate;

- (SGKGrouping)groupingWithPrevious:(StopVisits *)previous
                              next:(StopVisits *)next;

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
