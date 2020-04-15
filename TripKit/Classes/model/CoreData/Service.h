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

/// Represents a public transport service
@interface Service : NSManagedObject

#pragma mark - Instance fields + methods

@property (nonatomic, assign, getter = isRealTime) BOOL realTime;
@property (nonatomic, assign, getter = isRealTimeCapable) BOOL realTimeCapable;
@property (nonatomic, assign, getter = isCanceled) BOOL canceled;
@property (nonatomic, assign, getter = isBicycleAccessible) BOOL bicycleAccessible;

/// :nodoc:
@property (nonatomic, assign, getter = isWheelchairAccessible) BOOL wheelchairAccessible;
/// :nodoc:
@property (nonatomic, assign, getter = isWheelchairInaccessible) BOOL wheelchairInaccessible;

@property (nonatomic, strong) NSArray<StopVisits *> *sortedVisits;
@property (nonatomic, copy, nullable) NSString *lineName;
@property (nonatomic, copy, nullable) NSString *direction;

- (nullable Alert *)sampleAlert;

- (NSArray<Alert *> *)allAlerts;

- (NSString *)title;

- (nullable NSString *)shortIdentifier;

- (nullable StopVisits *)visitForStopCode:(NSString *)stopCode;

- (NSArray<id<TKDisplayableRoute>> *)shapesForEmbarkation:(nullable StopVisits *)embarkation
                                            disembarkingAt:(nullable StopVisits *)disembarkation;

/// :nodoc:
@property (nonatomic, assign) BOOL isRequestingServiceData;

- (BOOL)looksLikeAnExpress;

@end

/// :nodoc:
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
