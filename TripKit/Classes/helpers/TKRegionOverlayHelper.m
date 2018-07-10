//
//  TKRegionOverlayHelper.m
//  TripGo
//
//  Created by Adrian Schoenig on 15/05/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "TKRegionOverlayHelper.h"

@import ASPolygonKit;

#ifdef TK_NO_MODULE
#import "TripKit.h"
#endif

#import "TripKit/TripKit-Swift.h"
#import "MKPolygon+PolygonFromRectangle.h"

@interface TKRegionOverlayHelper ()

@property (nonatomic, strong) MKPolygon *regionsOverlay;

@end

@implementation TKRegionOverlayHelper

+ (TKRegionOverlayHelper *)sharedInstance {
  DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
    return [[self alloc] init];
  });
}

- (void)clearCache
{
  _regionsOverlay = nil;

  NSURL *cacheFile = [TKRegionOverlayHelper cacheURL];
  [[NSFileManager defaultManager] removeItemAtURL:cacheFile error:nil];
}

- (void)regionsPolygon:(void(^)(MKPolygon * _Nullable polygon))completion
{
  if (self.regionsOverlay.pointCount > 0) {
    completion(self.regionsOverlay);
  } else if (self.regionsOverlay) {
    // we have it, but it's empty, you've made a duplicate call!
    completion(nil);
  } else {
    // try to load locally
    NSArray *polygonsFromCache = [TKRegionOverlayHelper polygonsFromCacheFile];
    if (polygonsFromCache.count > 0) {
      self.regionsOverlay = [MKPolygon polygonFromRectangle:MKMapRectWorld interiorPolygons:polygonsFromCache];
      completion(self.regionsOverlay);
      return;
    }
    
    // generate it
    self.regionsOverlay = [[MKPolygon alloc] init];

    NSArray *regions = [TKRegionManager.shared regions];
    NSMutableArray *polygons = [NSMutableArray arrayWithCapacity:regions.count];
    for (TKRegion *region in regions) {
      [polygons addObject:[region polygon]];
    }

#ifndef RUNNING_OBJC_TEST
    [MKPolygon unionOfPolygons:polygons completionHandler:^(NSArray<MKPolygon *> * _Nonnull regionPolygons) {
      
      // create outside polygon (to show which area we don't cover)
      [TKRegionOverlayHelper savePolygonsToCacheFile:regionPolygons];
      self.regionsOverlay = [MKPolygon polygonFromRectangle:MKMapRectWorld interiorPolygons:regionPolygons];
      completion(self.regionsOverlay);

    }];
#endif
    
  }
}

#pragma mark - Caching on disk

+ (NSURL *)cacheURL
{
  NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory
                                                         inDomains:NSUserDomainMask];
  return [[URLs firstObject] URLByAppendingPathComponent:@"regionOverlay.data"];
}

+ (nullable NSArray *)polygonsFromCacheFile
{
  NSURL *cacheFile = [self cacheURL];
  NSData *data = [NSData dataWithContentsOfURL:cacheFile];
  if (data) {
    id unarchived = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if ([unarchived isKindOfClass:[NSDictionary class]]) {
      NSDictionary *wrapped = (NSDictionary *)unarchived;
      NSInteger regionsHash = [wrapped[@"regionsHash"] integerValue];
      if (regionsHash == [[TKRegionManager.shared regionsHash] integerValue]) {
        return wrapped[@"polygons"];
      }
    }
  }
  return nil;
}

+ (void)savePolygonsToCacheFile:(NSArray *)polygons
{
  if (polygons.count == 0) {
    return;
  }
  
  NSDictionary *wrapped = @{
                            @"polygons": polygons,
                            @"regionsHash": [TKRegionManager.shared regionsHash],
                            };
  
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:wrapped];
  if (data) {
    NSURL *cacheFile = [self cacheURL];
    [data writeToURL:cacheFile atomically:YES];
  }
}


@end

@implementation MKPolygon (NSCoding)

- (void)encodeWithCoder:(NSCoder *)encoder
{
  CLLocationCoordinate2D coords[self.pointCount];
  [self getCoordinates:coords range:NSMakeRange(0, self.pointCount)];

  NSMutableArray *pointArray = [NSMutableArray arrayWithCapacity:self.pointCount];
  for (NSUInteger i = 0; i < self.pointCount; i++) {
    CLLocationCoordinate2D coordinate = coords[i];
    [pointArray addObject:@{
                            @"lat": @(coordinate.latitude),
                            @"lng": @(coordinate.longitude),
                            }];
  }
  [encoder encodeObject:pointArray forKey:@"coordinates"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  NSArray *pointArray = [decoder decodeObjectForKey:@"coordinates"];
  CLLocationCoordinate2D coords[pointArray.count];
  for (NSUInteger i = 0; i < pointArray.count; i++) {
    NSDictionary *encoded = pointArray[i];
    coords[i] = CLLocationCoordinate2DMake([encoded[@"lat"] doubleValue], [encoded[@"lng"] doubleValue]);
  }
  
  self = [MKPolygon polygonWithCoordinates:coords count:pointArray.count];
  if (self) {
  }
  return self;
}

@end
