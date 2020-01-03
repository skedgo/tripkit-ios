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

@interface StopLocation : NSManagedObject

@property (nonatomic, retain, nullable) TKNamedCoordinate *location;
@property (nonatomic, retain, nullable) NSString * name;
@property (nonatomic, retain, nullable) NSString * shortName;
@property (nonatomic, copy) NSString * stopCode;
@property (nonatomic, strong, null_resettable) TKModeInfo * stopModeInfo;
@property (nonatomic, retain, nullable) NSNumber * sortScore;
@property (nonatomic, retain, nullable) NSString * filter;
@property (nonatomic, retain, nullable) NSString * regionName;
@property (nonatomic, assign) BOOL toDelete;
@property (nonatomic, retain, nullable) StopLocation *parent;
@property (nonatomic, strong, nullable) NSNumber * wheelchairAccessible;
@property (nonatomic, strong, nullable) Cell *cell;
@property (nonatomic, retain, nullable) NSSet<StopLocation *> *children;
@property (nonatomic, retain, nullable) NSSet<StopVisits *> *visits;
@property (nonatomic, retain, nullable) NSArray<NSNumber *> *alertHashCodes;

// Non core data properties
@property (nonatomic, strong, nullable) NSDate *lastEarliestDate;
@property (nonatomic, weak, nullable) StopVisits *lastTopVisit;

+ (nullable instancetype)fetchStopForStopCode:(NSString *)stopCode
                                inRegionNamed:(nullable NSString *)regionName
                            requireCoordinate:(BOOL)requireCoordinate
                             inTripKitContext:(NSManagedObjectContext *)tripKitContext;

+ (instancetype)fetchOrInsertStopForStopCode:(NSString *)stopCode
                               inRegionNamed:(NSString *)regionName
                          intoTripKitContext:(NSManagedObjectContext *)tripKitContext;

+ (instancetype)fetchOrInsertStopForStopCode:(NSString *)stopCode
                                    modeInfo:(nullable TKModeInfo *)modeInfo
                                  atLocation:(nullable TKNamedCoordinate *)location
                          intoTripKitContext:(NSManagedObjectContext *)tripKitContext;

+ (instancetype)insertStopForStopCode:(NSString *)stopCode
                             modeInfo:(nullable TKModeInfo *)modeInfo
                           atLocation:(nullable TKNamedCoordinate *)location
                   intoTripKitContext:(NSManagedObjectContext *)tripKitContext;

- (void)remove;

- (nullable NSPredicate *)departuresPredicateFromDate:(nullable NSDate *)date;

- (NSArray<StopLocation *> *)stopsToMatchTo;

- (void)clearVisits;

- (void)setSortScore:(NSNumber *)sortScore;

@end

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
