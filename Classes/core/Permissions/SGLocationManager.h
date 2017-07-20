//
//  LocationManager.h
//  TripGo
//
//  Created by Adrian Schoenig on 30/08/12.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "SGPermissionManager.h"
#import "SGKCrossPlatform.h"


NS_ASSUME_NONNULL_BEGIN

typedef void (^SGLocationManagerMonitorBlock)(CLRegion * region);
typedef void (^SGLocationManagerLocationBlock)(CLLocation * location);
typedef void (^SGLocationManagerFailureBlock)(NSError * error);

FOUNDATION_EXPORT NSString *const SGLocationManagerBackgroundUpdatesEnabled;


@interface SGLocationManager : SGPermissionManager <CLLocationManagerDelegate>

+ (SGLocationManager *)sharedInstance;

- (BOOL)showBackgroundTrackingOption;

#pragma mark - Helpers

- (BOOL)annotationIsCurrentLocation:(id<MKAnnotation>)currentLocation
                      orCloseEnough:(BOOL)closeEnough;

- (SGKImage *)imageForAnnotation:(id<MKAnnotation>)annotation;

- (nullable SGKImage *)accessoryImageForAnnotation:(id<MKAnnotation>)annotation;

#pragma mark - Fetching locations

- (id<MKAnnotation>)currentLocationPlaceholder;

- (nullable CLLocation *)lastKnownUserLocation;

- (void)updatedLocation:(CLLocation *)newLocation;

- (void)fetchCurrentLocationWithin:(NSTimeInterval)timeInterval
													 success:(SGLocationManagerLocationBlock)success
													 failure:(SGLocationManagerFailureBlock)failure;

/**
 * Subscripes to location updates and trigger the update block whenever
 * the location changes enough.
 *
 * If there's a location fix already, it'll trigger the update before returning!
 */
- (void)subscribeToLocationUpdatesId:(id<NSCopying>)subscriber
														onUpdate:(SGLocationManagerLocationBlock)update;

- (void)unsubscribeFromLocationUpdates:(id<NSCopying>)subscriber;

- (void)considerStoppingToUpdateLocation; // for subclasses only!

/**
 * Tells the location manager to execute the provided block
 * when the device gets close to the specified coordinate.
 */
- (void)monitorRegion:(CLRegion *)region
						inContext:(NSManagedObjectContext *)context
					 onApproach:(SGLocationManagerMonitorBlock)block;

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
