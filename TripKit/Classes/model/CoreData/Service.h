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

@property (nonatomic, strong) NSArray<StopVisits *> *sortedVisits;
@property (nonatomic, copy, nullable) NSString *lineName;
@property (nonatomic, copy, nullable) NSString *direction;

- (NSString *)title;

- (nullable NSString *)shortIdentifier;

- (nullable StopVisits *)visitForStopCode:(NSString *)stopCode;

- (NSArray<id<TKDisplayableRoute>> *)shapesForEmbarkation:(nullable StopVisits *)embarkation
                                            disembarkingAt:(nullable StopVisits *)disembarkation;

/// :nodoc:
@property (nonatomic, assign) BOOL isRequestingServiceData;

- (BOOL)looksLikeAnExpress;

@end

NS_ASSUME_NONNULL_END
