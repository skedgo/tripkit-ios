//
//  ShareHelper.m
//  TripGo
//
//  Created by Adrian Schoenig on 15/11/2013.
//
//

#import "TKShareHelper.h"

@implementation TKShareHelper

#pragma mark - Meet URL

+ (BOOL)isMeetURL:(NSURL *)url
{
  return [[url path] isEqualToString:@"/meet"];
}

+ (NSURL *)meetURLForCoordinate:(CLLocationCoordinate2D)coordinate
                         atTime:(NSDate *)time
{
  NSString *urlString = [NSString stringWithFormat:@"http://tripgo.me/meet?lat=%.5f&lng=%.5f&at=%.0f", coordinate.latitude, coordinate.longitude, [time timeIntervalSince1970]];
  return [NSURL URLWithString:urlString];
}

+ (void)meetingDetailsForURL:(NSURL *)url
                     details:(void (^)(CLLocationCoordinate2D coordinate, NSDate *time))detailBlock
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
  if (! params[@"lat"] || ! params[@"lng"] || ! params[@"at"])
    return;
  
  CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([params[@"lat"] doubleValue], [params[@"lng"] doubleValue]);
  if (! CLLocationCoordinate2DIsValid(coordinate)) {
    return;
  }
  
  NSDate *time = [NSDate dateWithTimeIntervalSince1970:[params[@"at"] doubleValue]];
  detailBlock(coordinate, time);
}

#pragma mark - Query URL

+ (BOOL)isQueryURL:(NSURL *)url
{
  return [[url path] isEqualToString:@"/go"];
}

+ (NSURL *)queryURLForStart:(CLLocationCoordinate2D)start
                        end:(CLLocationCoordinate2D)end
                   timeType:(SGTimeType)timeType
                       time:(NSDate *)time
{
  NSMutableString *urlString = [NSMutableString stringWithFormat:@"http://tripgo.me/go?tlat=%.5f&tlng=%.5f", end.latitude, end.longitude];
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
                completion:(void (^)(CLLocationCoordinate2D start, CLLocationCoordinate2D end, NSString *name, SGTimeType timeType, NSDate *time))completion
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
      [geocoder geocodeString:name nearRegion:MKMapRectWorld success:^(NSString * _Nonnull query, NSArray<SGNamedCoordinate *> * _Nonnull results) {
#pragma unused(query)
        id <MKAnnotation>to = [SGBaseGeocoder pickBestFromResults:results];
        CLLocationCoordinate2D newEnd = [to coordinate];
        
        completion(start, newEnd, name, timeType, time);
      } failure:^(NSString * _Nonnull query, NSError * _Nullable error) {
#pragma unused(query, error)
        // Ignore silently
      }];
  } else {
    completion(start, end, name, timeType, time);
  }
  return YES;
}


#pragma mark - Stops

+ (BOOL)isStopURL:(NSURL *)url {
  return [[url path] containsString:@"/stop"];
}

+ (NSURL *)stopURLForStopCode:(NSString *)stopCode
                inRegionNamed:(NSString *)regionName
                       filter:(NSString *)filter
{
  NSString *addendum;
  if (filter) {
    addendum = [filter stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
  } else {
    addendum = @"";
  }
  
  NSString *escapedStopCode = [stopCode stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
  NSString *urlString = [NSString stringWithFormat:@"http://tripgo.me/stop/%@/%@/%@", regionName, escapedStopCode, addendum];
  return [NSURL URLWithString:urlString];
}

+ (void)stopDetailsForURL:(NSURL *)url
                  details:(void (^)(NSString *stopCode, NSString *regionName, NSString *filter))detailBlock {
  // re-construct the parameters
  NSArray *queryComponents = [[url path] componentsSeparatedByString:@"/"];
  
  NSString *regionName = queryComponents[2];
  NSString *stopCode = queryComponents[3];
  NSString *filter = queryComponents.count == 5?queryComponents[4]:nil;

  // construct the request
  if (! regionName || ! stopCode)
    return;
  
  detailBlock(stopCode, regionName, filter);
}


#pragma mark - Services

+ (BOOL)isServicesURL:(NSURL *)url {
  return [[url path] isEqualToString:@"/service"];
}

+ (NSURL *)serviceURLForServiceID:(NSString *)serviceID
                       atStopCode:(NSString *)stopCode
                    inRegionNamed:(NSString *)regionName
{
  NSString *escapedStopCode = [stopCode stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
  NSString *escapedServiceID = [serviceID stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
  NSString *urlString = [NSString stringWithFormat:@"http://tripgo.me/service?regionName=%@&stopCode=%@&serviceID=%@", regionName, escapedStopCode, escapedServiceID];
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
