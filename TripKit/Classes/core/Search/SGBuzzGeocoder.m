//
//  SGBuzzGeocoder.m
//  TripKit
//
//  Created by Adrian Schönig on 24/02/11.
//  Copyright 2011 Adrian Schönig. All rights reserved.
//

#import "SGBuzzGeocoder.h"

#import "TKTripKit.h"
#import "TripKit/TripKit-Swift.h"

#import "SGImageCacher.h"

#import "SGAutocompletionResult.h"


@interface SGBuzzGeocoder ()

@property (nonatomic, assign) MKMapRect lastRect;
@property (nonatomic, strong) NSCache *resultCache;

@end

@implementation SGBuzzGeocoder

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
              failure:(SGGeocoderFailureBlock)failure
{
  NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
  parameters[@"q"] = inputString;
  parameters[@"allowGoogle"] = @(NO);
  parameters[@"allowYelp"] = @(NO);

  if (!MKMapRectEqualToRect(mapRect, MKMapRectWorld) && !MKMapRectIsNull(mapRect)) {
    MKCoordinateRegion coordinateRegion = MKCoordinateRegionForMapRect(mapRect);
    CLLocationCoordinate2D coordinate = coordinateRegion.center;
    if (CLLocationCoordinate2DIsValid(coordinate)) {
      parameters[@"near"] = [NSString stringWithFormat:@"(%f,%f)", coordinate.latitude, coordinate.longitude];
    }
  }
  
  SVKServer *server = [SVKServer sharedInstance];
  [server requireRegions:^(NSError *error) {
    if (error) {
      DLog(@"Error fetching regions: %@", error);
      if (failure) {
        failure(inputString, error);
      }
      return;
    }
    
    // We pick the region as follows:
    // Provided map rect (if it's not the world) > user's location > international
    SVKRegion *region = nil;
    if (!MKMapRectEqualToRect(mapRect, MKMapRectWorld) && !MKMapRectIsNull(mapRect)) {
      MKCoordinateRegion coordinateRegion = MKCoordinateRegionForMapRect(mapRect);
      region = [TKRegionManager.shared regionContainingCoordinateRegion:coordinateRegion];
      if (! region) {
        region = self.fallbackRegion;
      }
    }
    if (! region) {
      region = [SVKInternationalRegion shared];
    }
    
    __weak typeof(self) weakSelf = self;
    [server hitSkedGoWithMethod:@"GET"
                           path:@"geocode.json"
                     parameters:parameters
                         region:region
                 callbackOnMain:NO
                        success:
     ^(NSInteger status, id responseObject, NSData *data) {
#pragma unused(status, data)
       typeof(weakSelf) strongSelf = weakSelf;
       if (! strongSelf) return;
       
       [strongSelf parseJSON:responseObject
                     success:success];
     }
                        failure:
     ^(NSError *error2) {
       if (failure) {
         failure(inputString, error2);
       }
     }];
  }];
}

#pragma mark - Private methods
  
- (void)parseJSON:(id)json
          success:(SGGeocoderSuccessBlock)success
{
  if (! success) {
    ZAssert(false, @"We need a success block!");
    return;
  }
  
  // analyse result
  NSString *queryString  = [json objectForKey:@"query"];
  NSString *errorMessage = [json objectForKey:@"error"];
  
  if (errorMessage) {
    [SGKLog debug:@"SGBuzzGeocoder" block:^NSString *{
      return [NSString stringWithFormat:@"Returned error: %@", errorMessage];
    }];
    success(queryString, @[]);

  } else {
    NSArray *choices = [json objectForKey:@"choices"];
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:[choices count]];
    
    for (NSDictionary *aChoice in choices) {
			SGKNamedCoordinate *singleResult = [self resultFromDictionary:aChoice
                                                   forSearchTerm:queryString];
			if (singleResult) { // might be a type we don't understand
        [results addObject:singleResult];
			}
    }
    
    success(queryString, results);
  }
}

- (nullable SGKNamedCoordinate *)resultFromDictionary:(NSDictionary *)aChoice
                                       forSearchTerm:(NSString *)inputString
{
  NSString *class = [aChoice objectForKey:@"class"];
  if ([class isEqualToString:@"Location"] || [class isEqualToString:@"Business"]) {
    return [self simpleResultFromDictionary:aChoice forSearchTerm:inputString];
  } else if ([class isEqualToString:@"StopLocation"]) {
    STKStopCoordinate *stop = [SVKParserHelper stopCoordinateFor:aChoice];
    stop.sortScore = [SGBuzzGeocoder scoreForDictionary:aChoice forSearchTerm:inputString];
    return stop;
  } else {
    return nil;
  }
}

- (SGKNamedCoordinate *)simpleResultFromDictionary:(NSDictionary *)aChoice
                                    forSearchTerm:(NSString *)inputString
{
  
  NSString *name      = aChoice[@"name"];
  NSString *address   = aChoice[@"address"];
  
  SGKNamedCoordinate *result = [[SGKNamedCoordinate alloc] initWithLatitude:[aChoice[@"lat"] doubleValue]
                                                                longitude:[aChoice[@"lng"] doubleValue]
                                                                     name:name
                                                                  address:address];
	
  NSString *urlString  = aChoice[@"URL"];
  result.url           = urlString ? [NSURL URLWithString:urlString] : nil;
  result.phone         = aChoice[@"phone"];
  result.reviewSummary = [aChoice[@"reviewSummaries"] firstObject];

  result.what3words         = aChoice[@"w3w"];
  result.what3wordsInfoURL  = aChoice[@"w3wInfoURL"];

  result.sortScore     = [SGBuzzGeocoder scoreForDictionary:aChoice forSearchTerm:inputString];
	
	return result;
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
  if (string.length == 0) {
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
      completion(cached);
      return;
    }
  }
  
  NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
  parameters[@"q"] = string;
  parameters[@"a"] = @(YES); // auto-complete
	CLLocationCoordinate2D coordinate = MKCoordinateRegionForMapRect(mapRect).center;
  if (CLLocationCoordinate2DIsValid(coordinate)) {
    parameters[@"near"] = [NSString stringWithFormat:@"(%f,%f)", coordinate.latitude, coordinate.longitude];
  }
	
  MKCoordinateRegion coordinateRegion = MKCoordinateRegionForMapRect(mapRect);
  SVKRegion *region = [TKRegionManager.shared regionContainingCoordinateRegion:coordinateRegion];
  if (! region) {
    completion(nil);
    return;
  }
  
  __weak typeof(self) weakSelf = self;
  SVKServer *server = [SVKServer sharedInstance];
  [server hitSkedGoWithMethod:@"GET"
                         path:@"geocode.json"
                   parameters:parameters
                       region:region
               callbackOnMain:NO
                      success:
   ^(NSInteger status, id responseObject, NSData *data) {
#pragma unused(status)
     __strong typeof(weakSelf) strongSelf = weakSelf;
     NSArray *autocompletionResults = nil;
     if (strongSelf && [responseObject isKindOfClass:[NSDictionary class]]) {
       NSArray *results = responseObject[@"choices"];
       NSMutableArray *enhanced = [NSMutableArray arrayWithCapacity:results.count];
       for (id object in results) {
         if ([object isKindOfClass:[NSDictionary class]]) {
           SGAutocompletionResult *result;
           result = [SGBuzzGeocoder autocompletionResultForDictionary:object
                                                        forSearchTerm:string];
           [enhanced addObject:result];
         }
       }
       if (enhanced.count > 0) {
         [strongSelf.resultCache setObject:enhanced forKey:string];
         autocompletionResults = enhanced;
       }
     }
     completion(autocompletionResults);
   }
                      failure:
   ^(NSError *error) {
#pragma unused(error)
     DLog(@"Error during autocompletion: %@", error);
     completion(nil);
   }];
}

- (id<MKAnnotation>)annotationForAutocompletionResult:(SGAutocompletionResult *)result
{
  if ([result.object isKindOfClass:[NSDictionary class]]) {
    return [self resultFromDictionary:result.object
                        forSearchTerm:nil];
  } else {
    ZAssert(false, @"Unexpected object: %@", result.object);
    return nil;
  }
}

#pragma mark - Private helpers

+ (SGKImage *)imageForStopType:(NSString *)stopType
{
  NSParameterAssert(stopType);
  
  NSString *imageName = [NSString stringWithFormat:@"icon-map-info-%@", stopType];
#if TARGET_OS_IPHONE
  return [[SGImageCacher sharedInstance] monochromeImageForName:imageName];
#else
  return [SGStyleManager imageNamed:imageName];
#endif
}



+ (SGAutocompletionResult *)autocompletionResultForDictionary:(NSDictionary *)json
                                                forSearchTerm:(NSString *)inputString
{
  SGAutocompletionResult *result = [[SGAutocompletionResult alloc] init];
  result.object = [NSMutableDictionary dictionaryWithDictionary:json];
  
  // we need to keep the region name so that we can check for duplicates properly later on
  
  NSString *class = json[@"class"];
  if ([class isEqualToString:@"StopLocation"]) {
    result.title = json[@"name"];
    result.subtitle = json[@"services"];
    NSString *stopType = json[@"stopType"];
    result.image = stopType ? [self imageForStopType:stopType] : [SGAutocompletionResult imageForType:SGAutocompletionSearchIconPin];
    result.accessoryButtonImage = [SGStyleManager imageNamed:@"icon-search-timetable"];

  } else {
    NSString *name = json[@"name"];
    NSString *address = json[@"address"];
    result.title = name ?: address;
    result.subtitle = name ? address : nil;
    
    if (nil != json[@"w3w"]) {
      result.image = [SGStyleManager imageNamed:@"icon-search-what3words"];
      
    } else {
      result.image = [SGAutocompletionResult imageForType:SGAutocompletionSearchIconPin];
    }
  }

  result.isInSupportedRegion = @(YES);
  result.score = [SGBuzzGeocoder scoreForDictionary:json forSearchTerm:inputString];
  return result;
}


+ (NSInteger)scoreForDictionary:(NSDictionary *)json
                  forSearchTerm:(NSString *)inputString
{
  NSString *class = json[@"class"];
  if ([class isEqualToString:@"StopLocation"]) {
    // score is only based on popularity of the bus stop
    NSInteger popularity = [json[@"popularity"] integerValue];
    // everything above this is pretty good, just small bonus points on top
#define GOOD_SCORE 1000
    NSUInteger popularityScore = (MIN(popularity, GOOD_SCORE)) / (GOOD_SCORE / 100);
    popularityScore = [SGAutocompletionResult rangedScoreForScore:popularityScore
                                                   betweenMinimum:30
                                                       andMaximum:80];
    if (popularity > GOOD_SCORE) {
      NSUInteger moreThanGood = popularityScore / GOOD_SCORE;
      NSUInteger bonus = [SGAutocompletionResult rangedScoreForScore:moreThanGood betweenMinimum:0 andMaximum:10];
      popularityScore += bonus;
    }
    
    return popularityScore;

  } else if (inputString) {
    // other things are scored based on name but with a lower maximum as we aren't that good at it
    NSString *name = json[@"name"];
    NSUInteger titleScore = [SGAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:inputString
                                                                                 candidate:name];
    return [SGAutocompletionResult rangedScoreForScore:titleScore
                                        betweenMinimum:0
                                            andMaximum:50];
    
  } else {
    // fall back to server's popularity
    NSInteger popularity = [json[@"popularity"] integerValue];
    return [SGAutocompletionResult rangedScoreForScore:popularity
                                        betweenMinimum:0
                                            andMaximum:50];
  }
}

@end
