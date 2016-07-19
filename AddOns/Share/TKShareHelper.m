//
//  ShareHelper.m
//  TripGo
//
//  Created by Adrian Schoenig on 15/11/2013.
//
//

#import "TKShareHelper.h"

#import <TripKit/TKTripKit.h>

@import SGSearchKit;

@implementation TKShareHelper

#pragma mark - Meet URL

+ (BOOL)isMeetURL:(NSURL *)url
{
  return [[url path] isEqualToString:@"/meet"];
}

+ (NSURL *)meetURLForCoordinate:(CLLocationCoordinate2D)coordinate
                         atTime:(NSDate *)time
{
  return [self meetURLForCoordinate:coordinate atTime:time baseURL:@"http://tripgo.me"];
}

+ (NSURL *)meetURLForCoordinate:(CLLocationCoordinate2D)coordinate
                         atTime:(NSDate *)time
                        baseURL:(NSString *)baseURL
{
  NSString *urlString = [NSString stringWithFormat:@"%@/meet?lat=%.5f&lng=%.5f&at=%.0f", baseURL, coordinate.latitude, coordinate.longitude, [time timeIntervalSince1970]];
  return [NSURL URLWithString:urlString];
}

+ (void)meetingDetailsForURL:(NSURL *)url
               usingGeocoder:(id<SGGeocoder>)geocoder
                     details:(void (^)(CLLocationCoordinate2D coordinate, NSString *name, NSDate *time))detailBlock
{
  // re-construct the parameters
  NSArray *queryComponents = [[url query] componentsSeparatedByString:@"&"];
  NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:queryComponents.count];
  for (NSString *param in queryComponents) {
    NSArray *elements = [param componentsSeparatedByString:@"="];
    if (elements.count == 2) {
      params[elements[0]] = elements[1];
    }
  }
  
  // Time is required
  if (! params[@"at"]) {
    return; // Need nam
  }
  NSDate *time = [NSDate dateWithTimeIntervalSince1970:[params[@"at"] doubleValue]];
  
  // And either need lat+lng or name
  NSString *name = params[@"name"];
  if (name) {
    [self geocodeString:name
          usingGeocoder:geocoder
             completion:
     ^(SGNamedCoordinate * _Nullable destination) {
       if (destination) {
         detailBlock(destination.coordinate, [destination title], time);
       }
     }];

  } else if (params[@"lat"] && params[@"lng"]) {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([params[@"lat"] doubleValue], [params[@"lng"] doubleValue]);
    if (CLLocationCoordinate2DIsValid(coordinate)) {
      detailBlock(coordinate, nil, time);
    }
  }
}

#pragma mark - Query URL

+ (BOOL)isQueryURL:(NSURL *)url
{
  return [[url path] isEqualToString:@"/go"];
}

+ (NSURL *)queryURLForStart:(CLLocationCoordinate2D)start
                        end:(CLLocationCoordinate2D)end
                   timeType:(SGTimeType)timeType
                       time:(nullable NSDate *)time
{
  return [self queryURLForStart:start end:end timeType:timeType time:time baseURL:@"http://tripgo.me"];
}

+ (NSURL *)queryURLForStart:(CLLocationCoordinate2D)start
                        end:(CLLocationCoordinate2D)end
                   timeType:(SGTimeType)timeType
                       time:(nullable NSDate *)time
                    baseURL:(NSString *)baseURL
{
  NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/go?tlat=%.5f&tlng=%.5f", baseURL, end.latitude, end.longitude];
  if (CLLocationCoordinate2DIsValid(start)) {
    [urlString appendFormat:@"&flat=%.5f&flng=%.5f", start.latitude, start.longitude];
  }
  if (time && timeType != SGTimeTypeLeaveASAP) {
    [urlString appendFormat:@"&time=%.0f&type=%ld", [time timeIntervalSince1970], (long)timeType];
  }
  return [NSURL URLWithString:urlString];
}

+ (BOOL)queryDetailsForURL:(NSURL *)url
             usingGeocoder:(id<SGGeocoder>)geocoder
                   success:(void (^)(CLLocationCoordinate2D start, CLLocationCoordinate2D end, NSString *name, SGTimeType timeType, NSDate *time))success
                   failure:(void (^)())failure
{
  // re-construct the parameters
  NSArray *queryComponents = [[url query] componentsSeparatedByString:@"&"];
  NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:queryComponents.count];
  for (NSString *param in queryComponents) {
    NSArray *elements = [param componentsSeparatedByString:@"="];
    if (elements.count == 2) {
      params[elements[0]] = elements[1];
    }
  }
  
  // construct the request
  // mandatory is only 'to'
  if ((!params[@"tlat"] || !params[@"tlng"]) && !params[@"tname"])
    return NO;
  
  NSString *name = params[@"tname"];
  
  CLLocationCoordinate2D start;
  if (params[@"flat"] && params[@"flng"]) {
    start = CLLocationCoordinate2DMake([params[@"flat"] doubleValue], [params[@"flng"] doubleValue]);;
  } else {
    start = kCLLocationCoordinate2DInvalid;
  }
  
  CLLocationCoordinate2D end;
  if (params[@"tlat"] && params[@"tlng"]) {
    end = CLLocationCoordinate2DMake([params[@"tlat"] doubleValue], [params[@"tlng"] doubleValue]);
  } else {
    end = kCLLocationCoordinate2DInvalid;
  }
  
  SGTimeType timeType = SGTimeTypeLeaveASAP;
  NSDate *time = nil;
  if (params[@"type"] && params[@"time"]) {
    NSInteger typeInt = [params[@"type"] integerValue];
    if (typeInt >= 0 && typeInt <= 2) {
      timeType = (SGTimeType) typeInt;
      time = timeType == SGTimeTypeLeaveASAP ? nil : [NSDate dateWithTimeIntervalSince1970:[params[@"time"] doubleValue]];
    }
  }
  
  if (!CLLocationCoordinate2DIsValid(end) && name != nil) {
    [self geocodeString:name
          usingGeocoder:geocoder
             completion:
     ^(SGNamedCoordinate * _Nullable coordinate) {
       if (coordinate) {
         success(start, coordinate.coordinate, [coordinate title], timeType, time);
       } else {
         failure();
       }
     }];
  } else {
    success(start, end, name, timeType, time);
  }
  return YES;
}

+ (void)geocodeString:(NSString *)string
        usingGeocoder:(id<SGGeocoder>)geocoder
           completion:(void(^)( SGNamedCoordinate * _Nullable coordinate))completion
{
  [geocoder geocodeString:string
               nearRegion:MKMapRectWorld
                  success:
   ^(NSString * _Nonnull query, NSArray<SGNamedCoordinate *> * _Nonnull results) {
#pragma unused(query)
    dispatch_async(dispatch_get_main_queue(), ^{
      id<MKAnnotation> annotation = [SGBaseGeocoder pickBestFromResults:results];
      if (annotation) {
        SGNamedCoordinate *coordinate = [SGNamedCoordinate namedCoordinateForAnnotation:annotation];
        coordinate.name = string;
        completion(coordinate);
      } else {
        completion(nil);
      }
    });
  } failure:
   ^(NSString * _Nonnull query, NSError * _Nullable error) {
#pragma unused(query, error)
     completion(nil);
  }];
  
}

#pragma mark - Stops

+ (BOOL)isStopURL:(NSURL *)url {
  return [[url path] containsString:@"/stop"];
}

+ (NSURL *)stopURLForStopCode:(NSString *)stopCode
                inRegionNamed:(NSString *)regionName
                       filter:(NSString *)filter
{
  return [self stopURLForStopCode:stopCode inRegionNamed:regionName filter:filter baseURL:@"http://tripgo.me"];
}

+ (NSURL *)stopURLForStopCode:(NSString *)stopCode
                inRegionNamed:(NSString *)regionName
                       filter:(NSString *)filter
                      baseURL:(NSString *)baseURL
{
  NSString *addendum;
  if (filter) {
    addendum = [filter stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
  } else {
    addendum = @"";
  }
  
  NSString *escapedStopCode = [stopCode stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
  NSString *urlString = [NSString stringWithFormat:@"%@/stop/%@/%@/%@", baseURL, regionName, escapedStopCode, addendum];
  return [NSURL URLWithString:urlString];
}

+ (BOOL)stopDetailsForURL:(NSURL *)url
                  details:(void (^)(NSString *stopCode, NSString *regionName, NSString *filter))detailBlock {
  // re-construct the parameters
  NSArray *queryComponents = [[url path] componentsSeparatedByString:@"/"];
  
  NSString *regionName = queryComponents[2];
  NSString *stopCode = queryComponents[3];
  NSString *filter = queryComponents.count == 5 ? queryComponents[4] : nil;

  // construct the request
  if (! regionName || ! stopCode)
    return NO;
  
  detailBlock(stopCode, regionName, filter);
  return YES;
}


#pragma mark - Services

+ (BOOL)isServicesURL:(NSURL *)url {
  return [[url path] isEqualToString:@"/service"];
}

+ (NSURL *)serviceURLForServiceID:(NSString *)serviceID
                       atStopCode:(NSString *)stopCode
                    inRegionNamed:(NSString *)regionName
{
  return [self serviceURLForServiceID:serviceID atStopCode:stopCode inRegionNamed:regionName baseURL:@"http://tripgo.me"];
}

+ (NSURL *)serviceURLForServiceID:(NSString *)serviceID
                       atStopCode:(NSString *)stopCode
                    inRegionNamed:(NSString *)regionName
                          baseURL:(NSString *)baseURL
{
  NSString *escapedStopCode = [stopCode stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
  NSString *escapedServiceID = [serviceID stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
  NSString *urlString = [NSString stringWithFormat:@"%@/service?regionName=%@&stopCode=%@&serviceID=%@", baseURL, regionName, escapedStopCode, escapedServiceID];
  return [NSURL URLWithString:urlString];
}

+ (void)serviceDetailsForURL:(NSURL *)url
                     details:(void (^)(NSString *stopCode, NSString *regionName, NSString *serviceID))detailBlock {
  // re-construct the parameters
  NSArray *queryComponents = [[url query] componentsSeparatedByString:@"&"];
  NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:queryComponents.count];
  for (NSString *param in queryComponents) {
    NSArray *elements = [param componentsSeparatedByString:@"="];
    if (elements.count == 2) {
      params[elements[0]] = elements[1];
    }
  }
  
  // construct the request
  if (! params[@"stopCode"] || ! params[@"regionName"] || ! params[@"serviceID"])
    return;
  
  NSString *regionName = params[@"regionName"];
  NSString *stopCode = [params[@"stopCode"] stringByRemovingPercentEncoding];
  NSString *servideId = [params[@"serviceID"] stringByRemovingPercentEncoding];
  
  detailBlock(stopCode, regionName, servideId);
}

@end
