//
//  StopLocation.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 24/11/12.
//
//

@import Foundation;
@import CoreData;

@import SGCoreKit;

@class Cell, Shape, StopVisits, Alert;

NS_ASSUME_NONNULL_BEGIN

@interface StopLocation : NSManagedObject <STKStopAnnotation, UIActivityItemSource>

@property (nonatomic, retain, nullable) SGNamedCoordinate *location;

@property (nonatomic, retain, nullable) NSString * name;
@property (nonatomic, retain, nullable) NSString * shortName;
@property (nonatomic, retain) NSString * stopCode;
@property (nonatomic, strong) ModeInfo * stopModeInfo;
@property (nonatomic, retain, nullable) NSNumber * sortScore;
@property (nonatomic, retain, nullable) NSString * filter;
@property (nonatomic, retain, nullable) NSString * regionName;
@property (nonatomic, assign) BOOL toDelete;
@property (nonatomic, retain, nullable) StopLocation *parent;
@property (nonatomic, strong, nullable) Cell *cell;
@property (nonatomic, retain, nullable) NSSet<StopLocation *> *children;
@property (nonatomic, retain, nullable) NSSet<StopVisits *> *visits;

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
                                    modeInfo:(nullable ModeInfo *)modeInfo
                                  atLocation:(nullable SGNamedCoordinate *)location
                          intoTripKitContext:(NSManagedObjectContext *)tripKitContext;

+ (instancetype)insertStopForStopCode:(NSString *)stopCode
                             modeInfo:(nullable ModeInfo *)modeInfo
                           atLocation:(nullable SGNamedCoordinate *)location
                   intoTripKitContext:(NSManagedObjectContext *)tripKitContext;

+ (nullable NSString *)platformForStopCode:(NSString *)stopCode
                             inRegionNamed:(NSString *)regionName
                          inTripKitContext:(NSManagedObjectContext *)tripKitContext;

- (NSString *)modeTitle;
- (nullable UIImage *)modeImageOfType:(SGStyleModeIconType)type;
- (nullable NSURL *)modeImageURLForType:(SGStyleModeIconType)type;

- (void)remove;

- (nullable NSPredicate *)departuresPredicateFromDate:(nullable NSDate *)date;

- (nullable StopVisits *)lastDeparture;

- (NSArray<StopLocation *> *)stopsToMatchTo;

- (NSArray<Alert *> *)alertsIncludingChildren;

- (void)clearVisits;

- (void)setSortScore:(NSNumber *)sortScore;

- (SVKRegion *)region;

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
