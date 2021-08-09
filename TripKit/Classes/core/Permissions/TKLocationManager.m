//
//  LocationManager.m
//  TripKit
//
//  Created by Adrian Schoenig on 30/08/12.
//
//

#import "TKLocationManager.h"

#import "TKCrossPlatform.h"

@import MapKit;

#import "TKTripKit.h"

#import "TKAutocompletionResult.h"

NSString *const TKLocationManagerFoundLocationNotification =  @"kTKLocationManagerFoundLocationNotification";

@interface TKLocationManager ()

@property (nonatomic, strong) CLLocationManager *coreLocationManager;

@property (nonatomic, assign) CLLocationDistance distanceFilter;

@property (copy, nonatomic) TKPermissionCompletionBlock completionBlock;
@property (nonatomic, strong) CLLocation *bestLocationFix;
@property (nonatomic, strong) id<MKAnnotation> currentLocationPlaceholder;

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
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = kCLLocationCoordinate2DInvalid;
    annotation.title = NSLocalizedStringFromTableInBundle(@"Current Location", @"Shared", [TKTripKit bundle], "Title for user's current location");
    _currentLocationPlaceholder = annotation;
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
			&& self.fetchTimers.count == 0) {
		[self.coreLocationManager stopUpdatingLocation];
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
                           NSLocalizedDescriptionKey: NSLocalizedStringFromTableInBundle(@"Could not determine your current location.", @"Shared", [TKTripKit bundle], @"Error title when GPS failed."),
                           NSLocalizedRecoverySuggestionErrorKey: NSLocalizedStringFromTableInBundle(@"Please try again or set your location manually.", @"Shared", [TKTripKit bundle], @"Error recovery suggestion when GPS fails."),
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
    switch (status) {
      case kCLAuthorizationStatusAuthorizedAlways:
        enabled = YES;
        break;
      default:
        enabled = NO;
        break;
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
  }
	return _coreLocationManager;
}

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
