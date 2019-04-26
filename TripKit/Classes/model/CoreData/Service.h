//
//  Service.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 24/11/12.
//
//

@import Foundation;
@import CoreData;

@class Alert, TKRegion, Shape, StopVisits, SegmentReference, Vehicle, TKModeInfo;
@protocol TKDisplayableRoute;

NS_ASSUME_NONNULL_BEGIN

@interface Service : NSManagedObject

@property (nonatomic, retain) NSString * code;
@property (nonatomic, retain, nullable) id color;
@property (nonatomic, retain) NSNumber * flags;
@property (nonatomic, retain, nullable) TKModeInfo * modeInfo;
@property (nonatomic, retain, nullable) NSString * name;
@property (nonatomic, retain, nullable) NSString * number;
@property (nonatomic, retain, nullable) NSString * operatorName;
@property (nonatomic, retain, nullable) NSNumber * frequency;
@property (nonatomic, assign) BOOL toDelete;
@property (nonatomic, retain, nullable) Service *continuation;
@property (nonatomic, retain, nullable) Service *progenitor;
@property (nonatomic, retain, nullable) NSSet<SegmentReference*>* segments;
@property (nonatomic, retain, nullable) Shape *shape;
@property (nonatomic, retain, nullable) Vehicle *vehicle;
@property (nonatomic, retain, nullable) NSSet<Vehicle*>* vehicleAlternatives;
@property (nonatomic, retain, nullable) NSSet<StopVisits*>* visits;
@property (nonatomic, retain, nullable) NSArray<NSNumber *> *alertHashCodes;

// non-core data properties
@property (nonatomic, assign, getter = isRealTime) BOOL realTime;
@property (nonatomic, assign, getter = isRealTimeCapable) BOOL realTimeCapable;
@property (nonatomic, assign, getter = isCancelled) BOOL cancelled;
@property (nonatomic, assign, getter = isBicycleAccessible) BOOL bicycleAccessible;
@property (nonatomic, assign, getter = isWheelchairAccessible) BOOL wheelchairAccessible;
@property (nonatomic, strong) NSArray<StopVisits *> *sortedVisits;
@property (nonatomic, copy, nullable) NSString *lineName;
@property (nonatomic, copy, nullable) NSString *direction;

- (void)remove;

- (nullable Alert *)sampleAlert;

- (NSArray<Alert *> *)allAlerts;

- (NSString *)title;

- (nullable NSString *)shortIdentifier;

- (nullable StopVisits *)visitForStopCode:(NSString *)stopCode;

- (NSArray<id<TKDisplayableRoute>> *)shapesForEmbarkation:(nullable StopVisits *)embarkation
                                            disembarkingAt:(nullable StopVisits *)disembarkation;

@property (nonatomic, assign) BOOL isRequestingServiceData;

- (BOOL)looksLikeAnExpress;

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

NS_ASSUME_NONNULL_END
