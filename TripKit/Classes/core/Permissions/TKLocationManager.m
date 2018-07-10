//
//  LocationManager.m
//  TripKit
//
//  Created by Adrian Schoenig on 30/08/12.
//
//

#import "TKLocationManager.h"

@import MapKit;

#import "TKTripKit.h"
#import "TripKit/TripKit-Swift.h"

#import "TKAutocompletionResult.h"

NSString *const TKLocationManagerBackgroundUpdatesEnabled = @"TKLocationManagerBackgroundUpdatesEnabled";

NSString *const TKLocationManagerFoundLocationNotification =  @"kTKLocationManagerFoundLocationNotification";

@interface TKLocationManager ()

@property (nonatomic, strong) CLLocationManager *coreLocationManager;
@property (nonatomic, strong) NSMutableArray *mostRecentlyEnteredRegions;
@property (nonatomic, strong) NSMutableArray *regionsWithFiredGPSNotif;
@property (nonatomic, strong) NSMutableDictionary *monitorBlocks;

@property (nonatomic, assign) BOOL wasGpsActive;
@property (nonatomic, assign) CLLocationDistance distanceFilter;

@property (copy, nonatomic) TKPermissionCompletionBlock completionBlock;
@property (nonatomic, strong) CLLocation *bestLocationFix;
@property (nonatomic, strong) TKNamedCoordinate *currentLocationPlaceholder;

@property (nonatomic, strong) NSMutableDictionary *subscriberBlocks;
@property (nonatomic, strong) NSMutableSet        *fetchTimers;

@end

@implementation TKLocationManager

+ (TKLocationManager *)sharedInstance
{
  static dispatch_once_t pred = 0;
  __strong static id _sharedObject = nil;
  dispatch_once(&pred, ^{
    _sharedObject = [[self alloc] init];
  });
  return _sharedObject;
}

- (BOOL)showBackgroundTrackingOption
{
  return [self.coreLocationManager respondsToSelector:@selector(requestAlwaysAuthorization)];
}

- (id)init
{
  self = [super init];
  if (self) {
    self.distanceFilter   = 250; // metres
		self.subscriberBlocks = [NSMutableDictionary dictionaryWithCapacity:5];
		self.fetchTimers      = [NSMutableSet setWithCapacity:5];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

#if TARGET_OS_IPHONE
		[center addObserver:self
							 selector:@selector(appWillResignActive:)
									 name:UIApplicationWillResignActiveNotification
								 object:nil];
		[center addObserver:self
							 selector:@selector(appWillEnterForeground:)
									 name:UIApplicationWillEnterForegroundNotification
								 object:nil];
#endif
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [center addObserver:self
               selector:@selector(userDefaultsDidChange:)
                   name:NSUserDefaultsDidChangeNotification
                 object:userDefaults];
  }
  return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	for (NSTimer *timer in self.fetchTimers) {
		[timer invalidate];
	}
  _coreLocationManager.delegate = nil;
}

- (CLLocation *)lastKnownUserLocation
{
  return self.bestLocationFix;
}

- (id<MKAnnotation>)currentLocationPlaceholder
{
  if (! _currentLocationPlaceholder) {
    _currentLocationPlaceholder = [[TKNamedCoordinate alloc] initWithName:Loc.CurrentLocation address:nil];
  }
  return _currentLocationPlaceholder;
}

#pragma mark - Helpers

- (BOOL)annotationIsCurrentLocation:(id<MKAnnotation>)currentLocation orCloseEnough:(BOOL)closeEnough
{
  if (currentLocation == self.currentLocationPlaceholder) {
    return YES;
  }

  if ([currentLocation isKindOfClass:[MKUserLocation class]]) {
    return YES;
  }
  
  if (closeEnough && self.bestLocationFix) {
    CLLocationCoordinate2D coordinate = [currentLocation coordinate];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    return ([self.bestLocationFix distanceFromLocation:location] < 250);
  } else {
    return NO;
  }
}

- (TKImage *)imageForAnnotation:(id<MKAnnotation>)annotation
{
#pragma unused(annotation)
  return [TKAutocompletionResult imageForType:TKAutocompletionSearchIconPin];
}

- (TKImage *)accessoryImageForAnnotation:(id<MKAnnotation>)annotation
{
#pragma unused(annotation)
  return nil;
}

#pragma mark - TKPermissionManager implementations

- (void)askForPermission:(void (^)(BOOL enabled))completion
{
#if TARGET_OS_IPHONE
  [self.coreLocationManager requestWhenInUseAuthorization];
#else
  [self.coreLocationManager startUpdatingLocation];
#endif
  
  self.completionBlock = completion;
}

#pragma mark - Public methods

- (void)fetchCurrentLocationWithin:(NSTimeInterval)timeInterval
													 success:(TKLocationManagerLocationBlock)success
													 failure:(TKLocationManagerFailureBlock)failure
{
	if (nil == success) {
		return;
	}
	
	if (timeInterval <= 0
      || [self location:self.bestLocationFix isInTheLastSeconds:90]) {
		[self performSuccess:success orFailure:failure];
		
	} else {
    // make sure we are updating
    [self.coreLocationManager startUpdatingLocation];
    self.wasGpsActive = YES;
    
		// schedule a timer
		NSDictionary *userInfo;
		if (nil != failure) userInfo = @{@"success": success, @"failure": failure};
		else								userInfo = @{@"success": success};
		
		NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:timeInterval
																											target:self
																										selector:@selector(fetchTimerFired:)
																										userInfo:userInfo
																										 repeats:NO];
		[self.fetchTimers addObject:timer];
  }
}

- (void)subscribeToLocationUpdatesId:(id<NSCopying>)subscriber
														onUpdate:(TKLocationManagerLocationBlock)update
{
  if (! self.isAuthorized) {
    return;
  }
  
	[self.subscriberBlocks setObject:update forKey:subscriber];
	
	// if we have a location already, tell em
	if (self.bestLocationFix) {
		update(self.bestLocationFix);
	}
	
	// make sure we are updating
	[self.coreLocationManager startUpdatingLocation];
	self.wasGpsActive = YES;
}

- (void)unsubscribeFromLocationUpdates:(id<NSCopying>)subscriber
{
  if (!subscriber) {
    ZAssert(false, @"Nil subscriber alert!");
    return;
  }
  
	[self.subscriberBlocks removeObjectForKey:subscriber];
	
	[self considerStoppingToUpdateLocation];
}

- (void)updatedLocation:(CLLocation *)newLocation
{
	self.bestLocationFix = newLocation;
}

- (void)setBestLocationFix:(CLLocation *)bestLocationFix
{
	_bestLocationFix = bestLocationFix;
	
	// is the new one good enough to tell everyone about it?
	if (bestLocationFix
			&& [self location:bestLocationFix isInTheLastSeconds:60]
			&& bestLocationFix.horizontalAccuracy < 500) {
		
		// tell all the fetchers
		[self tellAllFetchers];
		
		// tell all the subscribers
		for (TKLocationManagerLocationBlock subscribers in self.subscriberBlocks.allValues) {
			subscribers(bestLocationFix);
		}

		[self considerStoppingToUpdateLocation];
	}
}

#pragma mark - Location update helpers

- (void)considerStoppingToUpdateLocation
{
	if (self.subscriberBlocks.count == 0
			&& self.fetchTimers.count == 0
			&& self.mostRecentlyEnteredRegions.count == 0) {
		[self.coreLocationManager stopUpdatingLocation];
		self.wasGpsActive = NO;
	}
}

- (void)fetchTimerFired:(NSTimer *)timer
{
	if (NO == [self.fetchTimers containsObject:timer])
		return; // we called the success block already

	// process for this timer
	[self.fetchTimers removeObject:timer];
	[self performSuccess:timer.userInfo[@"success"]
						 orFailure:timer.userInfo[@"failure"]];
	
	[self considerStoppingToUpdateLocation];
}

- (void)performSuccess:(TKLocationManagerLocationBlock)success
						 orFailure:(TKLocationManagerFailureBlock)failure
{
	if (self.bestLocationFix) {
		success(self.bestLocationFix);
	} else if (failure) {
    NSDictionary *info = @{
                           NSLocalizedDescriptionKey: NSLocalizedStringFromTableInBundle(@"Could not determine your current location.", @"Shared", [TKStyleManager bundle], @"Error title when GPS failed."),
                           NSLocalizedRecoverySuggestionErrorKey: NSLocalizedStringFromTableInBundle(@"Please try again or set your location manually.", @"Shared", [TKStyleManager bundle], @"Error recovery suggestion when GPS fails."),
                           };
		NSError *error = [NSError errorWithDomain:@"SkedGo-Shared"
                                         code:198364
                                     userInfo:info];
		failure(error);
	}
}


- (BOOL)location:(CLLocation *)location isInTheLastSeconds:(NSTimeInterval)seconds
{
  if (!location) {
    return NO;
  }
  NSDate* eventDate = location.timestamp;
  NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
  return fabs(howRecent) < seconds;
}


#pragma mark - Region monitoring related methods

- (void)resetMonitoredRegions
{
	if ([self.coreLocationManager.monitoredRegions count]) {
		for (CLRegion *aRegion in self.coreLocationManager.monitoredRegions) {
			[self.coreLocationManager stopMonitoringForRegion:aRegion];
			[self.monitorBlocks removeObjectForKey:aRegion.identifier];
		}
	}
	
	if (self.monitorBlocks.count == 0) {
		self.monitorBlocks = nil;
	}
}

- (void)monitorRegion:(CLRegion *)region
						inContext:(NSManagedObjectContext *)context
					 onApproach:(TKLocationManagerMonitorBlock)block
{
#pragma unused(context)
	[self.monitorBlocks setObject:block forKey:region.identifier];
	
	[self.coreLocationManager startMonitoringForRegion:region];
}

- (void)stopMonitoringCoordinate:(CLLocationCoordinate2D)coordinate
											withRadius:(CLLocationDistance)radius
									 AndIdentifier:(NSString *)identifier
{
	// Region to stop monitoring.
	CLRegion *region = [[CLCircularRegion alloc] initWithCenter:coordinate
                                                       radius:radius
                                                   identifier:identifier];
	
	// Unregister the region with the location manager.
	[self.coreLocationManager stopMonitoringForRegion:region];
	
	// Remove the reference to the block dictionary.
	if ([self.monitorBlocks objectForKey:identifier] == nil) {
		// Region crossing has occured and dealt with.
		return;
	} else {
		// Region pcrossing has been detected, but user is yet to
		// actually enter the region, i.e., the standard location
		// service is yet to affirm the user is within the region.
		[self.monitorBlocks removeObjectForKey:identifier];
		if ([self.monitorBlocks count] == 0) {
			self.monitorBlocks = nil;
		}
				
		NSMutableArray *regionsToBeRemoved = [NSMutableArray array];
		
		for (CLRegion *aRegion in self.mostRecentlyEnteredRegions) {
			// This check is needed as the region object generated at the
			// start of this method call possesses different address than
			// the region object residing in the mostRecentlyEnteredREgions
			// array.
			if ([aRegion.identifier isEqualToString:region.identifier]) {
				[regionsToBeRemoved addObject:aRegion];
			}
		}
		
		[self.mostRecentlyEnteredRegions removeObjectsInArray:regionsToBeRemoved];
		
		if (self.mostRecentlyEnteredRegions.count == 0) {
			self.mostRecentlyEnteredRegions = nil;
			[self considerStoppingToUpdateLocation];
		}
	}
}

#pragma mark - Notifications

- (void)appWillResignActive:(NSNotification *)notification
{
#pragma unused(notification)
	for (NSTimer *timer in self.fetchTimers) {
		[timer invalidate];
		
		// keep them in there, so we can do something with them when we get back
	}
}

- (void)appWillEnterForeground:(NSNotification *)notification
{
#pragma unused(notification)
	[self tellAllFetchers];
}

- (void)userDefaultsDidChange:(NSNotification *)notification
{
#pragma unused(notification)
#if TARGET_OS_IPHONE
  if ([[NSUserDefaults standardUserDefaults] boolForKey:TKLocationManagerBackgroundUpdatesEnabled]) {
    [self.coreLocationManager requestAlwaysAuthorization];
  }
#endif
}

#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
#pragma unused(manager)
  if (status != kCLAuthorizationStatusNotDetermined // ignore this status as it doesn't tell
                                                    // us anything useful here.
      && self.completionBlock) {
    
    BOOL enabled;
#if TARGET_OS_IPHONE
    switch (status) {
      case kCLAuthorizationStatusAuthorizedWhenInUse:
      case kCLAuthorizationStatusAuthorizedAlways:
        enabled = YES;
        break;
      default:
        enabled = NO;
        break;
    }
#else
    if (@available(macOS 10.12, *)) {
      switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
          enabled = YES;
          break;
        default:
          enabled = NO;
          break;
      }
    } else {
      enabled = NO;
    }
#endif
    
    if (enabled) {
      [self.coreLocationManager startUpdatingLocation];
    }
    self.completionBlock(enabled);
    self.completionBlock = nil;
  }
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
#pragma unused(manager)
  CLLocation *newLocation = [locations lastObject];
  
	// region monitoring stuff
  if (newLocation.horizontalAccuracy < 500.0 && [self location:newLocation isInTheLastSeconds:60]) {
		// This block of codes activates standard location service to
		// solve the arruacy problem, which arises from the use of
		// region monitoring API.
		
		NSArray *regionsToRaiseNotif = [self.mostRecentlyEnteredRegions copy];
		
		for (CLCircularRegion *aRegion in regionsToRaiseNotif) {
			NSString *narrowIdentifier = [aRegion.identifier stringByAppendingString:@"-narrower"];
			CLCircularRegion *narrowRegion = [[CLCircularRegion alloc] initWithCenter:aRegion.center
                                                                         radius:500
                                                                     identifier:narrowIdentifier];
			
			// check if the new location lies inside the region.
			if ([narrowRegion containsCoordinate:newLocation.coordinate]) {
				
				// user is notified of the region crossing, so remove the region from the array.
				[self.regionsWithFiredGPSNotif addObject:aRegion];
				[self.mostRecentlyEnteredRegions removeObject:aRegion];
				if (self.mostRecentlyEnteredRegions.count == 0) {
					// users are notified of all region crossings.
					self.mostRecentlyEnteredRegions = nil;
					
					// we want to stop the location services once we've entered the last region.
					// note that this might interfere with other view controllers using the GPS.
					[self considerStoppingToUpdateLocation];
				}
				
				// region is approaching, execute the approaching block.
				TKLocationManagerMonitorBlock block = [self.monitorBlocks objectForKey:aRegion.identifier];
				// user is notified of the region crossing, so remove the block from the dictionary
				[self.monitorBlocks removeObjectForKey:aRegion.identifier];
				if (self.monitorBlocks.count == 0) {
					self.monitorBlocks = nil;
				}

				if (nil == block) {
//					NSLog(@"Trying to execute region monitoring block, but didn't find one (we probably just executed it): %@", aRegion.identifier);
					continue;
				}
				// now execute the block (which might trigger getting a new location again, so we do this last).
				block(aRegion);
			}
		}
	}
	
	// standard current location stuff
	
	// can we ignore the new location?
	// we do so if the one is still recent, new one is not more accurate and too close to old => ignore
	if (self.bestLocationFix
			&& [self location:self.bestLocationFix isInTheLastSeconds:60]
			&& [newLocation distanceFromLocation:self.bestLocationFix] < self.distanceFilter
			&& newLocation.horizontalAccuracy > self.bestLocationFix.horizontalAccuracy) {
		return;
	}
	
	// go ahead with the new
	// note that this can trigger informing everyone
	self.bestLocationFix = newLocation;
}

#pragma mark - Lazy accessors

- (CLLocationManager *)coreLocationManager
{
  if (nil == _coreLocationManager) {
    self.coreLocationManager = [[CLLocationManager alloc] init];
    _coreLocationManager.delegate = self;
    _coreLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
		
    // Set a movement threshold for new events.
    _coreLocationManager.distanceFilter = self.distanceFilter;
    
    // Pretent that we just received an update
    CLLocation *location = [_coreLocationManager location];
    if (location) {
      [self locationManager:_coreLocationManager didUpdateLocations:@[location]];
    }
    
    // Reset monitored regions
    for (CLRegion *monitored in [_coreLocationManager monitoredRegions]) {
      [_coreLocationManager stopMonitoringForRegion:monitored];
    }
  }
	return _coreLocationManager;
}

- (NSMutableArray *)mostRecentlyEnteredRegions
{
	if (_mostRecentlyEnteredRegions == nil) {
		_mostRecentlyEnteredRegions = [NSMutableArray array];
	}
	return _mostRecentlyEnteredRegions;
}

- (NSMutableArray *)regionsWithFiredGPSNotif
{
	if (_regionsWithFiredGPSNotif == nil) {
		_regionsWithFiredGPSNotif = [NSMutableArray array];
	}
	
	return _regionsWithFiredGPSNotif;
}

- (NSMutableDictionary *)monitorBlocks
{
	if (_monitorBlocks == nil) {
    _monitorBlocks = [NSMutableDictionary dictionary];
	}
	return _monitorBlocks;
}

#pragma mark - Private methods for testing purposes.

- (void)tellAllFetchers
{
	for (NSTimer *timer in self.fetchTimers) {
		if (YES == timer.isValid) {
			NSDictionary *timerInfo = timer.userInfo;
			if (nil != timerInfo) {
				[self performSuccess:timerInfo[@"success"]
									 orFailure:timerInfo[@"failure"]];
			}
		}
	}
	[self.fetchTimers removeAllObjects];
}

@end
