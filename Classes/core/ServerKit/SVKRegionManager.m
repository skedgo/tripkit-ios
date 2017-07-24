//
//  RegionManager.m
//  TripKit
//
//  Created by Adrian Schönig on 24/05/12.
//  Copyright (c) 2012 SkedGo. All rights reserved.
//

#import "SVKRegionManager.h"

#import "TripKit/TripKit-Swift.h"

#import "SVKServerKit.h"

@interface SVKRegionManager ()

@property (nonatomic, strong) NSNumber *regionsHash;
@property (nonatomic, strong) NSArray *regionArray;

@property (nonatomic, strong) NSDictionary *modeDetails;
@property (nonatomic, strong) NSDictionary *requiredForModes;

@end

@implementation SVKRegionManager

NSString *const RegionManagerRegionsUpdatedNotification =  @"SVKRegionManagerRegionsUpdatedNotification";

+ (SVKRegionManager *)sharedInstance {
  DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
    return [[self alloc] init];
  });
}

- (NSArray *)regions
{
  return self.regionArray;
}

- (BOOL)hasRegions
{
  return self.regionArray.count > 0;
}

- (SVKRegion *)regionForCoordinateRegion:(MKCoordinateRegion)coordinateRegion
{
  CLLocationCoordinate2D center = coordinateRegion.center;
  MKCoordinateSpan span = coordinateRegion.span;
  CLLocationCoordinate2D topLeft = [self validCoordinateForLatitude:center.latitude - span.latitudeDelta
                                                          longitude:center.longitude - span.longitudeDelta];
  CLLocationCoordinate2D bottomRight = [self validCoordinateForLatitude:center.latitude + span.latitudeDelta
                                                              longitude:center.longitude + span.longitudeDelta];
  SVKRegion *region = [self regionForCoordinate:topLeft
                                       andOther:bottomRight];
  if (region) {
    return region;
  } else {
    return [SVKInternationalRegion shared];
  }
}

- (CLLocationCoordinate2D)validCoordinateForLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude
{
  if (latitude > 90) {
    latitude = 90;
  } else if (latitude < -90) {
    latitude = -90;
  }

  while (longitude < -180) {
    longitude += 360;
  }
  while (longitude > 180) {
    longitude -= 360;
  }
  return CLLocationCoordinate2DMake(latitude, longitude);
}

- (MKMapRect)MKMapRectForCoordinateRegion:(MKCoordinateRegion)region
{
  MKMapPoint a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                    region.center.latitude + region.span.latitudeDelta / 2,
                                                                    region.center.longitude - region.span.longitudeDelta / 2));
  MKMapPoint b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                    region.center.latitude - region.span.latitudeDelta / 2,
                                                                    region.center.longitude + region.span.longitudeDelta / 2));
  return MKMapRectMake(MIN(a.x,b.x), MIN(a.y,b.y), ABS(a.x-b.x), ABS(a.y-b.y));
}

- (BOOL)regionsForCoordinateRegion:(MKCoordinateRegion)coordinateRegion
                 includeCoordinate:(CLLocationCoordinate2D)coordinate
{
  if (!CLLocationCoordinate2DIsValid(coordinateRegion.center)
      || !CLLocationCoordinate2DIsValid(coordinate)) {
    return NO;
  }
  
  MKMapRect mapRect = [self MKMapRectForCoordinateRegion:coordinateRegion];
  for (SVKRegion *region in self.regionArray) {
    if ([region intersectsMapRect:mapRect] && [region containsCoordinate:coordinate]) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)coordinateIsPartOfAnyRegion:(CLLocationCoordinate2D)coordinate
{
	if (self.regionArray.count == 0)
		return YES;
	
  for (SVKRegion *region in self.regionArray) {
    if ([region containsCoordinate:coordinate]) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)mapRectIntersectsAnyRegion:(MKMapRect)mapRect
{
	if (self.regionArray.count == 0
      || MKMapRectSpans180thMeridian(mapRect))
		return YES;
	
  for (SVKRegion *region in self.regionArray) {
    if ([region intersectsMapRect:mapRect]) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)mapRectIsForAnyRegion:(MKMapRect)mapRect
{
  // the region's map rect needs to include the map rect
	if (self.regionArray.count == 0)
		return NO;
	
  mapRect = MKMapRectInset(mapRect, MKMapRectGetWidth(mapRect) * 0.25, MKMapRectGetHeight(mapRect) * 0.25);
  
  for (SVKRegion *region in self.regionArray) {
    if ([region intersectsMapRect:mapRect]) {
      return YES;
    }
  }
  return NO;
}

- (NSString *)titleForModeIdentifier:(NSString *)modeIdentifier
{
  NSDictionary *details = self.modeDetails[modeIdentifier];
  return details[@"title"];
}

- (nullable NSURL *)imageURLForModeIdentifier:(NSString *)modeIdentifier
                                   ofIconType:(SGStyleModeIconType)type
{
  if (!modeIdentifier) {
    return nil;
  }
  
  NSDictionary *details = self.modeDetails[modeIdentifier];
  NSString *iconFileNamePart;
  
  switch (type) {
    case SGStyleModeIconTypeMapIcon:
    case SGStyleModeIconTypeListMainMode:
    case SGStyleModeIconTypeResolutionIndependent:
      iconFileNamePart = details[@"icon"];
      break;
      
    case SGStyleModeIconTypeListMainModeOnDark:
    case SGStyleModeIconTypeResolutionIndependentOnDark:
      iconFileNamePart = details[@"darkIcon"];
      break;
      
    case SGStyleModeIconTypeVehicle:
      iconFileNamePart = details[@"vehicleIcon"];
      break;
      
    case SGStyleModeIconTypeAlert:
      return nil; // not supported for modes
  }
  
  if (! iconFileNamePart) {
    return nil;
  }

  return [SVKServer imageURLForIconFileNamePart:iconFileNamePart
                                     ofIconType:type];
}

- (NSURL *)websiteURLForModeIdentifier:(NSString *)modeIdentifier
{
  NSDictionary *details = self.modeDetails[modeIdentifier];
  NSString *urlString = details[@"URL"];
  if (urlString) {
    return [NSURL URLWithString:urlString];
  } else {
    return nil;
  }
}

- (nullable SGKColor *)colorForModeIdentifier:(NSString *)modeIdentifier
{
  NSDictionary *details = self.modeDetails[modeIdentifier];
  NSDictionary *colorDictionary = details[@"color"];
  if (colorDictionary) {
    return [SVKParserHelper colorForDictionary:colorDictionary];
  } else {
    return nil;
  }
}

- (BOOL)modeIdentifierIsRequired:(NSString *)modeIdentifier
{
  NSDictionary *details = self.modeDetails[modeIdentifier];
  return [details[@"required"] boolValue] == YES;
}

- (NSArray *)impliedModeIdentifiers:(NSString *)modeIdentifier
{
  NSDictionary *details = self.modeDetails[modeIdentifier];
  return details[@"implies"];
}

- (NSArray *)dependentModeIdentifiers:(NSString *)modeIdentifier
{
  return self.requiredForModes[modeIdentifier];
}

#pragma mark - Local cache

- (void)readDataFromCache
{
  NSDictionary *localCache = [SVKRegionManager readLocalCache];
  if (localCache) {
    self.regionArray = localCache[@"regions"];
    self.modeDetails = localCache[@"modeDetails"];
    self.regionsHash = localCache[@"regionsHash"];
    self.requiredForModes = nil;
  }
}

- (void)updateRegions:(NSArray<SVKRegion *> *)regions
          modeDetails:(NSDictionary<NSString *, id>*)modeDetails
             hashCode:(NSInteger)hashCode
{
  // Clean-up old versions
  [[NSUserDefaults sharedDefaults] removeObjectForKey:@"regions"];
  [[NSUserDefaults sharedDefaults] removeObjectForKey:@"modeDetails"];
  
  // Update in-memory data
  self.regionArray = [regions copy];
  self.modeDetails = modeDetails;
  self.regionsHash = @(hashCode);
  self.requiredForModes = nil;
  
  // Update data on disc
  NSDictionary *localCache =
  @{
    @"regions": self.regionArray,
    @"modeDetails": self.modeDetails,
    @"regionsHash": self.regionsHash,
    };
  [SVKRegionManager saveToLocalCache:localCache];
  
  // we only want to post this notification if we actually managed to download some regions
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  [center postNotificationName:RegionManagerRegionsUpdatedNotification object:self];
  
  // also notify the map-managers
  [center postNotificationName:SGMapShouldRefreshOverlayNotification object:self];
}

+ (NSURL *)cacheURL
{
  NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory
                                                         inDomains:NSUserDomainMask];
  return [[URLs firstObject] URLByAppendingPathComponent:@"regions.data"];
}

+ (nullable NSDictionary *)readLocalCache
{
  NSURL *cacheFile = [self cacheURL];
  NSData *data = [NSData dataWithContentsOfURL:cacheFile];
  if (data) {
    // For backwards comaptibility with old files
    [NSKeyedUnarchiver setClass:[SVKRegion class] forClassName:@"Region"];
    [NSKeyedUnarchiver setClass:[SVKRegion class] forClassName:@"SGRegion"];
    [NSKeyedUnarchiver setClass:[SVKRegion class] forClassName:@"SVKRegion"];
    
    @try {
      id unarchived = [NSKeyedUnarchiver unarchiveObjectWithData:data];
      if ([unarchived isKindOfClass:[NSDictionary class]]) {
        return unarchived;
      }
    }
    @catch (NSException *exception) {
      [SGKLog warn:@"SVKRegionManager" text:@"Couldn't read locally cached data"];
    }
  }
  return nil;
}

+ (void)saveToLocalCache:(NSDictionary *)localCache
{
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:localCache];
  if (data) {
    NSURL *cacheFile = [self cacheURL];
    [data writeToURL:cacheFile atomically:YES];
  }
}


#pragma mark - Lazy accessors

- (NSDictionary *)modeDetails
{
  if (_modeDetails.count == 0) {
    [self readDataFromCache];
  }
  return _modeDetails;
}

- (NSDictionary *)requiredForModes
{
  if (_requiredForModes.count == 0) {
    [self readDataFromCache];
  
    NSDictionary *modeDetails = self.modeDetails;
    
    // build the reverse mapping
    NSMutableDictionary *requiredFor = [NSMutableDictionary dictionaryWithCapacity:modeDetails.count];
    for (NSString *modeIdentifier in [modeDetails allKeys]) {
      NSDictionary *details = modeDetails[modeIdentifier];
      NSArray *implies = details[@"implies"];
      for (NSString *impliedMode in implies) {
        NSMutableArray *requiredForModes = requiredFor[impliedMode];
        if (! requiredForModes) {
          requiredForModes = [NSMutableArray arrayWithCapacity:modeDetails.count];
          requiredFor[impliedMode] = requiredForModes;
        }
        [requiredForModes addObject:modeIdentifier];
      }
    }
    _requiredForModes = requiredFor;
  }
  return _requiredForModes;
}

- (NSArray *)regionArray
{
  if (_regionArray.count == 0) {
    [self readDataFromCache];
  }
  return _regionArray;
}

@end
