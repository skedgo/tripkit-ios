//
//  StopLocation.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 24/11/12.
//
//

@import Foundation;
@import CoreData;


@class Cell, Shape, StopVisits, Alert, TKNamedCoordinate, TKModeInfo;

NS_ASSUME_NONNULL_BEGIN

/// Represents a public transport location
@interface StopLocation : NSManagedObject

#pragma mark - Class methods

+ (nullable instancetype)fetchStopForStopCode:(NSString *)stopCode
                                inRegionNamed:(nullable NSString *)regionName
                            requireCoordinate:(BOOL)requireCoordinate
                             inTripKitContext:(NSManagedObjectContext *)tripKitContext;

/// :nodoc:
+ (instancetype)fetchOrInsertStopForStopCode:(NSString *)stopCode
                               inRegionNamed:(NSString *)regionName
                          intoTripKitContext:(NSManagedObjectContext *)tripKitContext;

/// :nodoc:
+ (instancetype)fetchOrInsertStopForStopCode:(NSString *)stopCode
                                    modeInfo:(nullable TKModeInfo *)modeInfo
                                  atLocation:(nullable TKNamedCoordinate *)location
                          intoTripKitContext:(NSManagedObjectContext *)tripKitContext;

/// :nodoc:
+ (instancetype)insertStopForStopCode:(NSString *)stopCode
                             modeInfo:(nullable TKModeInfo *)modeInfo
                           atLocation:(nullable TKNamedCoordinate *)location
                   intoTripKitContext:(NSManagedObjectContext *)tripKitContext;

#pragma mark - CoreData fields

@property (nonatomic, retain, nullable) TKNamedCoordinate *location;
@property (nonatomic, retain, nullable) NSString * name;
@property (nonatomic, retain, nullable) NSString * shortName;
@property (nonatomic, copy) NSString * stopCode;
@property (nonatomic, strong, null_resettable) TKModeInfo * stopModeInfo;
@property (nonatomic, retain, nullable) NSNumber * sortScore;
@property (nonatomic, retain, nullable) NSString * filter;
@property (nonatomic, retain, nullable) NSString * regionName;

/// :nodoc:
@property (nonatomic, assign) BOOL toDelete;

@property (nonatomic, retain, nullable) StopLocation *parent;

/// :nodoc:
@property (nonatomic, strong, nullable) NSNumber * wheelchairAccessible;

/// :nodoc:
@property (nonatomic, strong, nullable) Cell *cell;

@property (nonatomic, retain, nullable) NSSet<StopLocation *> *children;
@property (nonatomic, retain, nullable) NSSet<StopVisits *> *visits;
@property (nonatomic, retain, nullable) NSArray<NSNumber *> *alertHashCodes;

#pragma mark - Instance fields

// Non core data properties
@property (nonatomic, strong, nullable) NSDate *lastEarliestDate;

/// :nodoc:
@property (nonatomic, weak, nullable) StopVisits *lastStopVisit;

/// :nodoc:
- (void)remove;

/// :nodoc:
- (nullable NSPredicate *)departuresPredicateFromDate:(nullable NSDate *)date;

/// :nodoc:
- (NSArray<StopLocation *> *)stopsToMatchTo;

/// :nodoc:
- (void)clearVisits;

/// :nodoc:
- (void)setSortScore:(NSNumber *)sortScore;

@end

/// :nodoc:
@interface StopLocation (CoreDataGeneratedAccessors)

- (void)addVisitsObject:(StopVisits *)value;
- (void)removeVisitsObject:(StopVisits *)value;
- (void)addVisits:(NSSet *)values;
- (void)removeVisits:(NSSet *)values;

- (void)addChildrenObject:(StopLocation *)value;
- (void)removeChildrenObject:(StopLocation *)value;
- (void)addChildren:(NSSet *)values;
- (void)removeChildren:(NSSet *)values;

@end

NS_ASSUME_NONNULL_END
