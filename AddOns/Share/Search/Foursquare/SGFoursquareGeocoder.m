//
//  SGFoursquareGeocoder.m
//  TripGo
//
//  Created by Adrian Schoenig on 26/05/2014.
//
//

#import "SGFoursquareGeocoder.h"

@import AFNetworking;

#ifdef TK_NO_FRAMEWORKS
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
#endif


#import "SGAutocompletionResult.h"

@interface SGFoursquareGeocoder ()

@property (nonatomic, copy) NSString *clientID;
@property (nonatomic, copy) NSString *clientSecret;

@property (nonatomic, assign) MKMapRect lastRect;
@property (nonatomic, strong) NSCache *resultCache;

@property (nonatomic, copy) NSString *latestQuery;

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@end

@implementation SGFoursquareGeocoder

// https://api.foursquare.com/v2/venues/search?ll=40.7,-74&client_id=CLIENT_ID&client_secret=CLIENT_SECRET&v=YYYYMMDD

- (id)initWithClientID:(NSString *)clientID clientSecret:(NSString *)clientSecret
{
  self = [super init];
  if (self) {
    self.clientID = clientID;
    self.clientSecret = clientSecret;
    self.lastRect = MKMapRectNull;
    self.resultCache = [[NSCache alloc] init];
  }
  return self;
}

#pragma mark - SGBaseGeocoder

- (void)geocodeString:(NSString *)inputString
           nearRegion:(MKMapRect)mapRect
              success:(SGGeocoderSuccessBlock)success
              failure:(nullable SGGeocoderFailureBlock)failure
{
  MKCoordinateRegion coordinateRegion = MKCoordinateRegionForMapRect(mapRect);
  CLLocationCoordinate2D center = coordinateRegion.center;
  CLLocationDistance radius = 50000; // 50km
  
  NSDictionary *paras = @{@"ll": [NSString stringWithFormat:@"%.3f,%.3f", center.latitude, center.longitude],
                          @"query": inputString,
                          @"intent": @"browse",
                          @"radius": @(radius),
                          @"client_id": self.clientID,
                          @"client_secret": self.clientSecret,
                          @"limit": @(20),
                          @"v": @"20140526"};
  
  __weak typeof (self) weakSelf = self;
  [self.sessionManager GET:@"search"
                parameters:paras
                   success:
   ^(NSURLSessionDataTask *task, id responseObject) {
#pragma unused(task)
     typeof (weakSelf) strongSelf = weakSelf;
     if (strongSelf) {
       NSArray *venues = responseObject[@"response"][@"venues"];
       NSArray *results = [strongSelf resultsForResultArray:venues
                                              forSearchTerm:inputString
                                                 nearRegion:coordinateRegion
                                     asAutocompletionResult:NO];
       success(inputString, results);
     }
   }
                   failure:
   ^(NSURLSessionDataTask *task, NSError *error) {
#pragma unused(task, error)
     DLog(@"Foursquare failed with error: %@", error);
     if (failure) {
       failure(inputString, nil); // fail without showing error as this might be an internal issue, e.g., quota exceeded
     }
   }];
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
    return;
  }
  
  if (MKMapRectIsNull(self.lastRect) || ! MKMapRectContainsRect(self.lastRect, mapRect)) {
    // invalidate cache
    [self.resultCache removeAllObjects];
    self.lastRect = mapRect;
  } else {
    NSArray *cached = [self.resultCache objectForKey:string];
    if (cached) {
      completion(nil);
      return;
    }
  }
  
  __weak typeof(self) weakSelf = self;
  [self autocompletionResultForString:string
                           nearRegion:MKCoordinateRegionForMapRect(mapRect)
                           completion:
   ^(NSArray *results) {
     __strong typeof(weakSelf) strongSelf = weakSelf;
     if (strongSelf) {
       if (results.count > 0) {
         [strongSelf.resultCache setObject:results forKey:string];
       }
       completion(results);
     }
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


#pragma mark - Private methods

- (SGAutocompletionResult *)autocompletionResultForAnnotation:(SGKNamedCoordinate *)annotation
                                                forSearchTerm:(NSString *)inputString
                                                   nearRegion:(MKCoordinateRegion)coordinateRegion
{
  SGAutocompletionResult *result = [[SGAutocompletionResult alloc] init];
  result.object = annotation;
  result.title = [annotation title];
  NSString *address = [annotation respondsToSelector:@selector(subtitle)] ? [annotation subtitle] : nil;
  result.subtitle = [address isEqualToString:@"(null)"]?nil:address;
  result.image = [SGStyleManager imageNamed:@"icon-search-poweredByFoursquare_36x36"];
  result.score    = [SGFoursquareGeocoder scoreForAnnotation:annotation forSearchTerm:inputString nearRegion:coordinateRegion];

  return result;
}

+ (NSUInteger)scoreForAnnotation:(SGKNamedCoordinate *)annotation
                   forSearchTerm:(NSString *)inputString
                      nearRegion:(MKCoordinateRegion)coordinateRegion
{
  NSUInteger titleScore = [SGAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:inputString
                                                                               candidate:[annotation title]];
  NSUInteger subtitleScore = [SGAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:inputString
                                                                                  candidate:[annotation subtitle]];
  
  if (titleScore == 0 && subtitleScore == 0) {
    [SGKLog debug:@"SGFoursquareGeocoder" block:^NSString * {
      return [NSString stringWithFormat:@"Ignoring due to 0 title score (input was %@): %@", inputString, [annotation title]];
    }];
    return 0;
  }

  NSUInteger distanceScore = [SGAutocompletionResult scoreBasedOnDistanceFromCoordinate:[annotation coordinate]
                                                                               toRegion:coordinateRegion
                                                                           longDistance:NO];
  NSUInteger rawScore = (titleScore * 3 + distanceScore) / 4;

  if ([annotation isSuburb]) {
    rawScore = MIN((NSUInteger)100, rawScore * 2);
  }

  // Even verified results can be not great matches, so we keep the maximum fixed, but
  // raise the lower end. Overall, we want foursquare to have a lower maximum than
  // Apple as Apple tends to provide better exact matches.
  NSUInteger minimum, maximum;
  NSNumber *isVerified = [annotation attributionIsVerified];
  if ([isVerified boolValue]) {
    minimum = 33;
    maximum = 66;
  } else {
    minimum = 15;
    maximum = 66;
  }
  
  return [SGAutocompletionResult rangedScoreForScore:rawScore
                                      betweenMinimum:minimum andMaximum:maximum];
}

- (NSArray *)resultsForResultArray:(NSArray *)venues
                     forSearchTerm:(NSString *)inputString
                        nearRegion:(MKCoordinateRegion)coordinateRegion
            asAutocompletionResult:(BOOL)asAutocompletionResult
{
  NSMutableArray *coordinates = [NSMutableArray arrayWithCapacity:venues.count];
  for (NSDictionary *venueDict in venues) {
    NSString *name = venueDict[@"name"];
    if (! [self nameIsGood:name]) {
      [SGKLog debug:@"SGFoursquareGeocoder" block:^NSString * {
        return [NSString stringWithFormat:@"Ignoring result with bad name (input was %@): %@", inputString, name];
      }];
      continue;
    }
    
    BOOL isSuburb = NO;
    NSArray *categories = venueDict[@"categories"];
    if (categories.count == 0) {
      continue; // Unverified and often garbage.
    }
    for (NSDictionary *category in categories) {
      if ([category[@"name"] isEqualToString:@"States & Municipalities"]) {
        isSuburb = YES;
        break;
      }
    }
    
    NSDictionary *locationDict = venueDict[@"location"];
    NSString *addressString = locationDict[@"address"];
    
    CLLocationDegrees latitude = [locationDict[@"lat"] floatValue];
    CLLocationDegrees longitude = [locationDict[@"lng"] floatValue];
    SGKNamedCoordinate *namedCoordinate = [[SGKNamedCoordinate alloc] initWithLatitude:latitude
                                                                           longitude:longitude
                                                                                name:name
                                                                             address:addressString];
    namedCoordinate.isSuburb = isSuburb;
    
    NSString *venueID = venueDict[@"id"];
    [namedCoordinate setAttributionWithActionTitle:@"Show on Foursquare"
                                           website:[NSString stringWithFormat:@"http://foursquare.com/venue/%@", venueID]
                                    appActionTitle:@"Open in Foursquare app"
                                           appLink:[NSString stringWithFormat:@"foursquare://venues/%@", venueID]
                                        isVerified:venueDict[@"verified"]];
    
    NSUInteger score = [SGFoursquareGeocoder scoreForAnnotation:namedCoordinate
                                                  forSearchTerm:inputString
                                                     nearRegion:coordinateRegion];
    if (score == 0) {
      continue;
    }
    namedCoordinate.sortScore = score;
    
    [coordinates addObject:namedCoordinate];
  }
  
  NSUInteger max = asAutocompletionResult ? 5 : 10;
  NSArray *filtered = [SGBaseGeocoder filteredMergedAndPruned:coordinates
                                              limitedToRegion:coordinateRegion
                                                  withMaximum:max];
  
  if (asAutocompletionResult) {
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:filtered.count];
    for (SGKNamedCoordinate *coordinate in filtered) {
      SGAutocompletionResult *result = [self autocompletionResultForAnnotation:coordinate
                                                                 forSearchTerm:inputString
                                                                    nearRegion:coordinateRegion];
      [results addObject:result];
    }
    return results;
  
  } else {
    return filtered;
  }
}

- (BOOL)nameIsGood:(NSString *)name
{
  NSArray *foursquareCrap = @[@"platform", @"station", @"concourse", @"wharf", @"<=>", @"interchange", @"terminal", @"bus stop"];
  NSString *lowerName = [name lowercaseString];
  for (NSString *crap in foursquareCrap) {
    if ([lowerName rangeOfString:crap].location != NSNotFound) {
      return NO;
    }
  }
  return YES;
}

- (void)autocompletionResultForString:(NSString *)inputString
                           nearRegion:(MKCoordinateRegion)coordinateRegion
                           completion:(SGAutocompletionDataResultBlock)completion
{
  self.latestQuery = inputString;

  NSDictionary *paras = @{@"ll": [NSString stringWithFormat:@"%.3f,%.3f", coordinateRegion.center.latitude, coordinateRegion.center.longitude],
                          @"query": inputString,
                          @"client_id": self.clientID,
                          @"client_secret": self.clientSecret,
                          @"limit": @(20), // ask for more, so that we can filter what we think is best
                          @"v": @"20140526"};
  
  __weak typeof (self) weakSelf = self;

  [self.sessionManager GET:@"suggestcompletion"
                parameters:paras
                   success:
   ^(NSURLSessionDataTask *task, id responseObject) {
#pragma unused(task)
     __strong typeof (weakSelf) strongSelf = weakSelf;
     if (strongSelf) {
       NSArray *results = nil;
       if ([inputString isEqualToString:strongSelf.latestQuery]) {
         NSArray *minivenues = responseObject[@"response"][@"minivenues"];
         results = [strongSelf resultsForResultArray:minivenues
                                       forSearchTerm:inputString
                                          nearRegion:coordinateRegion
                              asAutocompletionResult:YES];
       }
       if (results.count > 0) {
         completion(results);
       } else {
         [self exploreAutocompletionResultForString:self.latestQuery
                                         nearRegion:coordinateRegion
                                         completion:completion];
       }
     }
   }
                   failure:
   ^(NSURLSessionDataTask *task, NSError *error) {
#pragma unused(task, error)
     [self exploreAutocompletionResultForString:self.latestQuery
                                     nearRegion:coordinateRegion
                                     completion:completion];
   }];
}

- (void)exploreAutocompletionResultForString:(NSString *)inputString
                                  nearRegion:(MKCoordinateRegion)coordinateRegion
                                  completion:(SGAutocompletionDataResultBlock)completion
{
  self.latestQuery = inputString;
  
  NSDictionary *paras = @{@"ll": [NSString stringWithFormat:@"%.3f,%.3f", coordinateRegion.center.latitude, coordinateRegion.center.longitude],
                          @"query": inputString,
                          @"client_id": self.clientID,
                          @"client_secret": self.clientSecret,
                          @"limit": @(20), // ask for more, so that we can filter what we think is best
                          @"v": @"20140526"};
  
  __weak typeof (self) weakSelf = self;

  [self.sessionManager GET:@"explore"
                parameters:paras
                   success:
   ^(NSURLSessionDataTask *task, id responseObject) {
#pragma unused(task)
     __strong typeof (weakSelf) strongSelf = weakSelf;
     if (strongSelf) {
       NSArray *results = nil;
       if ([inputString isEqualToString:strongSelf.latestQuery]) {
         NSArray *groups = responseObject[@"response"][@"groups"];
         NSMutableArray *venues = [[NSMutableArray alloc] init];
         for (NSDictionary *dict in groups) {
           for (NSDictionary *item in dict[@"items"]) {
             [venues addObject:item[@"venue"]];
           }
         }
         results = [strongSelf resultsForResultArray:venues
                                       forSearchTerm:inputString
                                          nearRegion:coordinateRegion
                              asAutocompletionResult:YES];
       }
        completion(results);
     }
   }
                   failure:
   ^(NSURLSessionDataTask *task, NSError *error) {
#pragma unused(task, error)
      completion(nil);
   }];
}

#pragma mark - Lazy accessors

- (AFHTTPSessionManager *)sessionManager
{
  if (! _sessionManager) {
    _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.foursquare.com/v2/venues/"]];
    _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
  }
  
  return _sessionManager;
}

@end
