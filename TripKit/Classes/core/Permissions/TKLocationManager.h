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

typedef void (^TKLocationManagerMonitorBlock)(CLRegion * region);
typedef void (^TKLocationManagerLocationBlock)(CLLocation * location);
typedef void (^TKLocationManagerFailureBlock)(NSError * error);

FOUNDATION_EXPORT NSString *const TKLocationManagerBackgroundUpdatesEnabled;


@interface TKLocationManager : TKPermissionManager <CLLocationManagerDelegate>

+ (TKLocationManager *)sharedInstance NS_REFINED_FOR_SWIFT;

- (BOOL)showBackgroundTrackingOption;

#pragma mark - Helpers

- (BOOL)annotationIsCurrentLocation:(id<MKAnnotation>)currentLocation
                      orCloseEnough:(BOOL)closeEnough;

- (TKImage *)imageForAnnotation:(id<MKAnnotation>)annotation;

- (nullable TKImage *)accessoryImageForAnnotation:(id<MKAnnotation>)annotation;

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

- (void)considerStoppingToUpdateLocation; // for subclasses only!

/**
 * Tells the location manager to execute the provided block
 * when the device gets close to the specified coordinate.
 */
- (void)monitorRegion:(CLRegion *)region
						inContext:(NSManagedObjectContext *)context
					 onApproach:(TKLocationManagerMonitorBlock)block;

/**
 * Tells the location manager to stop monitoring the region
 * associated with the given coordinate, radius and identifier.
 */
- (void)stopMonitoringCoordinate:(CLLocationCoordinate2D)coordinate
											withRadius:(CLLocationDistance)radius
									 AndIdentifier:(NSString *)identifier;

- (void)resetMonitoredRegions;

@end

NS_ASSUME_NONNULL_END
