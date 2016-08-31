//
//  Service.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 24/11/12.
//
//

@import Foundation;
@import CoreData;
@import SGCoreKit;

#import "TKRealTimeUpdatable.h"

@class Alert, SVKRegion, Shape, StopVisits, SegmentReference, Vehicle;
@protocol STKDisplayableRoute;

@interface Service : NSManagedObject <TKRealTimeUpdatable>

@property (nonatomic, retain) NSString * code;
@property (nonatomic, retain) id color;
@property (nonatomic, retain) NSNumber * flags;
@property (nonatomic, retain) ModeInfo * modeInfo;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * number;
@property (nonatomic, retain) NSString * operatorName;
@property (nonatomic, retain) NSNumber * frequency;
@property (nonatomic, assign) BOOL toDelete;
@property (nonatomic, retain) Service *continuation;
@property (nonatomic, retain) Service *progenitor;
@property (nonatomic, retain) NSSet<SegmentReference*>* segments;
@property (nonatomic, retain) Shape *shape;
@property (nonatomic, retain) Vehicle *vehicle;
@property (nonatomic, retain) NSSet<Vehicle*>* vehicleAlternatives;
@property (nonatomic, retain) NSSet<StopVisits*>* visits;

// non-core data properties
@property (nonatomic, assign, getter = isRealTime) BOOL realTime;
@property (nonatomic, assign, getter = isRealTimeCapable) BOOL realTimeCapable;
@property (nonatomic, assign, getter = isCancelled) BOOL cancelled;
@property (nonatomic, strong) NSArray<StopVisits *> *sortedVisits;
@property (nonatomic, copy) NSString *lineName;
@property (nonatomic, copy) NSString *direction;

+ (instancetype)fetchExistingServiceWithCode:(NSString *)serviceCode
                            inTripKitContext:(NSManagedObjectContext *)context;

+ (void)removeServicesBeforeDate:(NSDate *)date
				fromManagedObjectContext:(NSManagedObjectContext *)context;

- (void)remove;

- (Alert *)sampleAlert;
- (NSString *)modeTitle;
- (UIImage *)modeImageOfType:(SGStyleModeIconType)type;
- (NSURL *)modeImageURLForType:(SGStyleModeIconType)type;

- (SVKRegion *)region;
- (NSString *)title;

- (NSString *)shortIdentifier;

- (StopVisits *)visitForStopCode:(NSString *)stopCode;

- (NSArray<id<STKDisplayableRoute>> *)shapesForEmbarkation:(StopVisits *)embarkation
                                            disembarkingAt:(StopVisits *)disembarkation;

- (BOOL)hasServiceData;

@property (nonatomic, assign) BOOL isRequestingServiceData;

- (BOOL)looksLikeAnExpress;

- (BOOL)isFrequencyBased;

@end

@interface Service (CoreDataGeneratedAccessors)

- (void)addSegmentsObject:(SegmentReference *)value;
- (void)removeSegmentsObject:(SegmentReference *)value;
- (void)addSegments:(NSSet *)values;
- (void)removeSegments:(NSSet *)values;

- (void)addVisitsObject:(StopVisits *)value;
- (void)removeVisitsObject:(StopVisits *)value;
- (void)addVisits:(NSSet *)values;
- (void)removeVisits:(NSSet *)values;

- (void)addVehicleAlternativesObject:(Vehicle *)value;
- (void)VehicleAlternatives:(Vehicle *)value;
- (void)addVehicleAlternatives:(NSSet *)values;
- (void)removeVehicleAlternatives:(NSSet *)values;

@end
