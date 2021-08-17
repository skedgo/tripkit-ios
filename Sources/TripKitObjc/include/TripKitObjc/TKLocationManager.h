//
//  LocationManager.h
//  TripKit
//
//  Created by Adrian Schoenig on 30/08/12.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "TKPermissionManager.h"
#import "TKCrossPlatform.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^TKLocationManagerLocationBlock)(CLLocation * location);
typedef void (^TKLocationManagerFailureBlock)(NSError * error);

@interface TKLocationManager : TKPermissionManager <CLLocationManagerDelegate>

+ (TKLocationManager *)sharedInstance NS_REFINED_FOR_SWIFT;

#pragma mark - Helpers

- (BOOL)annotationIsCurrentLocation:(id<MKAnnotation>)currentLocation
                      orCloseEnough:(BOOL)closeEnough;

#pragma mark - Fetching locations

- (id<MKAnnotation>)currentLocationPlaceholder NS_REFINED_FOR_SWIFT;

- (nullable CLLocation *)lastKnownUserLocation;

- (void)updatedLocation:(CLLocation *)newLocation;

- (void)fetchCurrentLocationWithin:(NSTimeInterval)timeInterval
													 success:(TKLocationManagerLocationBlock)success
													 failure:(TKLocationManagerFailureBlock)failure;

/**
 * Subscripes to location updates and trigger the update block whenever
 * the location changes enough.
 *
 * If there's a location fix already, it'll trigger the update before returning!
 */
- (void)subscribeToLocationUpdatesId:(id<NSCopying>)subscriber
														onUpdate:(TKLocationManagerLocationBlock)update;

- (void)unsubscribeFromLocationUpdates:(id<NSCopying>)subscriber;


@end

NS_ASSUME_NONNULL_END
