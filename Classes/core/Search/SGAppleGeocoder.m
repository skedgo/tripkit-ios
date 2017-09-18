//
//  BHAppleGeocoder.m
//  TripKit
//
//  Created by Adrian Schönig on 17/04/12.
//  Copyright (c) 2012 SkedGo. All rights reserved.
//

#import "SGAppleGeocoder.h"

#import "TKTripKit.h"
#import "TripKit/TripKit-Swift.h"

#import "SGAutocompletionResult.h"


// #define SGAppleGeocoderNoisy 1

@interface SGAppleGeocoder ()

@property (nonatomic, assign) MKMapRect lastRect;
@property (nonatomic, strong) NSCache *resultCache;

@property (nonatomic, copy) NSString *latestQuery;

@end

@implementation SGAppleGeocoder

#pragma mark - Public methods.

- (id)init
{
  self = [super init];
  if (self) {
    self.lastRect = MKMapRectNull;
    self.resultCache = [[NSCache alloc] init];
  }
  return self;
}

- (void)geocodeString:(NSString *)inputString
           nearRegion:(MKMapRect)mapRect
              success:(SGGeocoderSuccessBlock)success
              failure:(nullable SGGeocoderFailureBlock)failure
{
  // Use Local Search API (which falls back to CLGeocoer)
#ifdef SGAppleGeocoderNoisy
  DLog(@"Using MKLocalSearch API");
#endif
  MKCoordinateRegion coordinateRegion = MKCoordinateRegionForMapRect(mapRect);
  [self fetchLocalSearchObjectsForString:inputString
                              nearRegion:coordinateRegion
                           limitToNearby:NO
                       forAutocompletion:NO
                                 success:success
                                 failure:failure];
}

#pragma mark - SGAutocompletionDataProvider

- (SGAutocompletionDataProviderResultType)resultType
{
  return SGAutocompletionDataProviderResultTypeLocation;
}

- (void)autocompleteSlowly:(NSString *)string
                forMapRect:(MKMapRect)mapRect
                completion:(SGAutocompletionDataResultBlock)completion
{
  if (! string || string.length == 0) {
    completion(nil);
  }
  
  BOOL isWorld = MKMapRectEqualToRect(mapRect, MKMapRectWorld);
  if (!isWorld) {
    // grow the map rect so we get more results
    CLLocationCoordinate2D center = MKCoordinateForMapPoint(mapRect.origin);
    double widthGrowth  = fmax(mapRect.size.width, MKMapPointsPerMeterAtLatitude(center.latitude) * 15000);
    double heightGrowth = fmax(mapRect.size.height, MKMapPointsPerMeterAtLatitude(center.latitude) * 15000);
    mapRect = MKMapRectInset(mapRect, -1 * widthGrowth,  -1 * heightGrowth);
  }
  
  if (MKMapRectIsNull(self.lastRect) || ! MKMapRectContainsRect(self.lastRect, mapRect)) {
    // invalidate cache
    [self.resultCache removeAllObjects];
    self.lastRect = mapRect;
  } else {
    NSArray *cached = [self.resultCache objectForKey:string];
    if (cached) {
      completion(cached);
      return;
    }
  }
  
  
  self.latestQuery = string;
  
  __weak typeof (self) weakSelf = self;
 [self fetchLocalSearchObjectsForString:string
                             nearRegion:MKCoordinateRegionForMapRect(self.lastRect)
                          limitToNearby:!isWorld
                      forAutocompletion:YES
                                success:
   ^(NSString *query, NSArray *results) {
     __strong typeof (weakSelf) strongSelf = weakSelf;
     NSArray *autocompletionResults = nil;
     if (strongSelf && [query isEqualToString:strongSelf.latestQuery]) {
       NSMutableArray *array = [NSMutableArray arrayWithCapacity:results.count];
       for (id<MKAnnotation> annotation in results) {
         SGAutocompletionResult *result = [strongSelf autocompletionResultForAnnotation:annotation
                                                                          forSearchTerm:string
                                                                             nearRegion:MKCoordinateRegionForMapRect(mapRect)];
         if (result) {
           [array addObject:result];
         }
       }
       
       // Apple can be acting up and "brandon av" finds "brandon avenue" but "brandon ave"
       // or "brandon avenue" does not find it. So we also look for matches in the cache.
       [strongSelf addCachedResults:array forQuery:query];
       
       if (array.count > 0) {
         [strongSelf.resultCache setObject:array forKey:string];
         autocompletionResults = array;
       }
     }
     completion(autocompletionResults);
   }
                                 failure:
   ^(NSString *query, NSError *error) {
#pragma unused(query, error)
     completion(nil);
   }];
}

- (id<MKAnnotation>)annotationForAutocompletionResult:(SGAutocompletionResult *)result
{
  if ([result.object conformsToProtocol:@protocol(MKAnnotation)]) {
    return result.object;
  } else {
    ZAssert(false, @"Unexpected object: %@", result.object);
    return nil;
  }
}

#pragma mark - Private methods.

- (void)addCachedResults:(NSMutableArray *)array forQuery:(NSString *)query
{
  if (query.length <= 1) {
    return;
  }
  
  NSString *subquery = query;
  do {
    subquery = [subquery substringToIndex:subquery.length - 1];
    NSArray *cached = [self.resultCache objectForKey:subquery];
    if (cached.count > 0) {
      for (SGAutocompletionResult *cachedResult in cached) {
        id<MKAnnotation> annotation = cachedResult.object;
        NSString *subtitle = [annotation respondsToSelector:@selector(subtitle)] ? [annotation subtitle] : nil;
        NSUInteger titleScore = [SGAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:query
                                                                                     candidate:annotation.title];
        NSUInteger addressScore = [SGAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:query
                                                                                       candidate:subtitle];
        NSUInteger stringScore = MIN(100, (NSInteger) (titleScore / 3 + addressScore));
        if (stringScore > 0) {
          // this result is still good. make sure there's no duplicate
          BOOL isDuplicate = NO;
          for (SGAutocompletionResult *result in array) {
            if ([result.title isEqualToString:cachedResult.title]
                || (result.subtitle && cachedResult.subtitle && [result.subtitle isEqualToString:cachedResult.subtitle])) {
              isDuplicate = YES;
              break;
            }
          }
          if (!isDuplicate) {
            [array addObject:cachedResult];
          }
        }
      }
      return;
    }
  } while (subquery.length > 1);
}

- (SGAutocompletionResult *)autocompletionResultForAnnotation:(id<MKAnnotation>)annotation
                                                forSearchTerm:(NSString *)inputString
                                                   nearRegion:(MKCoordinateRegion)coordinateRegion
{
  SGAutocompletionResult *result = [[SGAutocompletionResult alloc] init];
  result.object = annotation;
  result.title    = [annotation title];
  result.subtitle = [annotation respondsToSelector:@selector(subtitle)] ? [annotation subtitle] : nil;
  result.image    = [SGAutocompletionResult imageForType:SGAutocompletionSearchIconPin];

  result.score = [SGAppleGeocoder scoreForAnnotation:annotation forSearchTerm:inputString nearRegion:coordinateRegion];

  return result;
}

+ (NSUInteger)scoreForAnnotation:(id<MKAnnotation>)annotation
                   forSearchTerm:(NSString *)inputString
                      nearRegion:(MKCoordinateRegion)coordinateRegion
{
  return [TKGeocodingResultScorer calculateScoreForAnnotation:annotation searchTerm:inputString nearRegion:coordinateRegion allowLongDistance:NO minimum:15 maximum:75];
}

- (void)fetchLocalSearchObjectsForString:(NSString *)inputString
															nearRegion:(MKCoordinateRegion)coordinateRegion
                           limitToNearby:(BOOL)limit
                       forAutocompletion:(BOOL)forAutocompletion
                                 success:(SGGeocoderSuccessBlock)success
                                 failure:(nullable SGGeocoderFailureBlock)failure
{
  ZAssert(success, @"We need a success block!");
  
	NSString *fullSearchString = [SGLocationHelper expandAbbreviationInAddressString:inputString];
#ifdef SGAppleGeocoderNoisy
  DLog(@"Apple LocalSearch is in action with search string %@", fullSearchString);
#endif

	// Setup search parameters.
	MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
	request.naturalLanguageQuery = fullSearchString;
	if (CLLocationCoordinate2DIsValid(coordinateRegion.center)) {
		request.region = coordinateRegion;
	}
  CLLocation *centerLocation = [[CLLocation alloc] initWithLatitude:coordinateRegion.center.latitude longitude:coordinateRegion.center.longitude];
	
	// Now instantiate a local search object.
	MKLocalSearch *localSearch = [[MKLocalSearch alloc] initWithRequest:request];
	
	// Start the search
	[localSearch startWithCompletionHandler:
	 ^(MKLocalSearchResponse *response, NSError *error)
	{
		if (error) {
#ifdef SGAppleGeocoderNoisy
			DLog(@"Failed in performing local search, error:%@", error);
      DLog(@"Trying CLGeocoder...");
#endif
      [self fetchCLGeocoderObjectsForString:inputString
                                 nearRegion:coordinateRegion
                                    success:success
                                    failure:failure];
      
		} else {
      // Local search has successfully returned results.
      NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:[response.mapItems count]];
      for (MKMapItem *mapItem in response.mapItems) {
        if (limit && [centerLocation distanceFromLocation:mapItem.placemark.location] > 100000) {
          continue;
        }
        
        SGKNamedCoordinate *singleResult = [self resultFromMapItem:mapItem];
        if (singleResult) {
          singleResult.sortScore = [SGAppleGeocoder scoreForAnnotation:singleResult
                                                         forSearchTerm:inputString
                                                            nearRegion:coordinateRegion];
          
          [results addObject:singleResult];
        }
      }

      NSUInteger max = forAutocompletion ? 5 : 10;
      NSArray *filtered = [SGBaseGeocoder filteredMergedAndPruned:results
                                                  limitedToRegion:coordinateRegion
                                                      withMaximum:max];
      success(inputString, filtered);
		}
	}];
}

- (void)fetchCLGeocoderObjectsForString:(NSString *)inputString
                             nearRegion:(MKCoordinateRegion)coordinateRegion
                                success:(SGGeocoderSuccessBlock)success
                                failure:(nullable SGGeocoderFailureBlock)failure
{
  ZAssert(success, @"We need a success block!");

#ifdef SGAppleGeocoderNoisy
  DLog(@"Apple geocoder is in action");
#endif
  
  CLGeocoder *geocoder = [[CLGeocoder alloc] init];

  // Use 5 km radius around the coordinate
  CLRegion *region = nil;
	CLLocationCoordinate2D coordinate = coordinateRegion.center;
  if (CLLocationCoordinate2DIsValid(coordinate)) {
    region = [[CLCircularRegion alloc] initWithCenter:coordinate
                                               radius:5000
                                           identifier:[NSString stringWithFormat:@"%@-%f-%f", inputString, coordinate.latitude, coordinate.longitude]];
  }
	
	// Perform geocoding.
  [geocoder geocodeAddressString:inputString inRegion:region completionHandler:
	 ^(NSArray *placemarks, NSError *error)
	{
    if (error) {
#ifdef SGAppleGeocoderNoisy
      DLog(@"Failed in performing CLGeocoder search, error:%@", error);
#endif
      if (failure) {
        failure(inputString, error);
        return;
      }

    } else {
      // go into a background thread to do the augmentation there
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // Geocoding operation successfully returns results.
        NSMutableArray *results = [NSMutableArray arrayWithCapacity:placemarks.count];
        for (CLPlacemark *placemark in placemarks) {
          NSString *name = [SGLocationHelper nameFromPlacemark:placemark];
          SGKNamedCoordinate *singleResult = [self resultFromPlacemark:placemark
                                                             withName:name
                                                                phone:nil
                                                                  url:nil];
          if (singleResult) {
            [results addObject:singleResult];
          }
        }

        NSArray *filtered = [SGBaseGeocoder filteredMergedAndPruned:results
                                                    limitedToRegion:coordinateRegion
                                                        withMaximum:10];

        dispatch_async(dispatch_get_main_queue(), ^{
          success(inputString, filtered);
        });
      });
		}
  }];
}

- (nullable SGKNamedCoordinate *)resultFromMapItem:(MKMapItem *)mapItem
{
  return [self resultFromPlacemark:mapItem.placemark
                          withName:mapItem.name
                             phone:mapItem.phoneNumber
                               url:mapItem.url];
}


- (nullable SGKNamedCoordinate *)resultFromPlacemark:(CLPlacemark *)placemark
                                           withName:(NSString *)name
                                              phone:(NSString *)phone
                                                url:(NSURL *)url
{
#pragma unused(name) // we ignore the name and use the data from the placemark
  if (! placemark) {
		return nil;
	}
  
  SGKNamedCoordinate *result = [[SGKNamedCoordinate alloc] initWithPlacemark:placemark];
  result.phone = phone;
  result.url   = url;
  return result;
}

@end
