//
//  StopLocation.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 24/11/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import <TripKit/TKTripKit.h>

@class ModeInfo;
@class Cell, SVKRegion, Shape, StopVisits, SGNamedCoordinate;

@interface StopLocation : NSManagedObject <STKStopAnnotation, UIActivityItemSource>

@property (nonatomic, retain) SGNamedCoordinate *location;

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * shortName;
@property (nonatomic, retain) NSString * stopCode;
@property (nonatomic, strong) ModeInfo * stopModeInfo;
@property (nonatomic, retain) NSNumber * sortScore;
@property (nonatomic, retain) NSString * filter;
@property (nonatomic, retain) NSString * regionName;
@property (nonatomic, assign) BOOL toDelete;
@property (nonatomic, retain) StopLocation *parent;
@property (nonatomic, strong) Cell *cell;
@property (nonatomic, retain) NSSet<StopLocation *> *children;
@property (nonatomic, retain) NSSet<StopVisits *> *visits;

@property (nonatomic, strong) NSDate *lastEarliestDate;

@property (nonatomic, weak) StopVisits *lastTopVisit;

+ (instancetype)fetchStopForStopCode:(NSString *)stopCode
                       inRegionNamed:(NSString *)regionName
                   requireCoordinate:(BOOL)requireCoordinate
                    inTripKitContext:(NSManagedObjectContext *)tripKitContext;

+ (instancetype)fetchOrInsertStopForStopCode:(NSString *)stopCode
                               inRegionNamed:(NSString *)regionName
                          intoTripKitContext:(NSManagedObjectContext *)tripKitContext;

+ (instancetype)fetchOrInsertStopForStopCode:(NSString *)stopCode
                                    modeInfo:(ModeInfo *)modeInfo
                                  atLocation:(SGNamedCoordinate *)location
                          intoTripKitContext:(NSManagedObjectContext *)tripKitContext;

+ (instancetype)insertStopForStopCode:(NSString *)stopCode
                             modeInfo:(ModeInfo *)modeInfo
                           atLocation:(SGNamedCoordinate *)location
                   intoTripKitContext:(NSManagedObjectContext *)tripKitContext;

+ (NSString *)platformForStopCode:(NSString *)stopCode
                    inRegionNamed:(NSString *)regionName
                 inTripKitContext:(NSManagedObjectContext *)tripKitContext;

- (NSString *)modeTitle;
- (UIImage *)modeImageOfType:(SGStyleModeIconType)type;
- (NSURL *)modeImageURLForType:(SGStyleModeIconType)type;

- (void)remove;

- (NSPredicate *)departuresPredicateFromDate:(NSDate *)date;

- (StopVisits *)lastDeparture;

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
