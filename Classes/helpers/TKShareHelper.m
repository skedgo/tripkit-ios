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
  NSString *urlString = [NSString stringWithFormat:@"http://tripgo.me/go?flat=%.5f&flng=%.5f&tlat=%.5f&tlng=%.5f&time=%.0f&type=%ld", start.latitude, start.longitude, end.latitude, end.longitude,  [time timeIntervalSince1970], (long)timeType];
  return [NSURL URLWithString:urlString];
}

+ (void)queryDetailsForURL:(NSURL *)url
                   details:(void (^)(CLLocationCoordinate2D start, CLLocationCoordinate2D end, SGTimeType timeType, NSDate *time))detailBlock
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
  if (! params[@"flat"] || ! params[@"flng"] || ! params[@"time"]
      || ! params[@"tlat"] || ! params[@"tlng"] || ! params[@"type"])
    return;
  
  CLLocationCoordinate2D start = CLLocationCoordinate2DMake([params[@"flat"] doubleValue], [params[@"flng"] doubleValue]);
  if (! CLLocationCoordinate2DIsValid(start)) {
    return;
  }

  CLLocationCoordinate2D end = CLLocationCoordinate2DMake([params[@"tlat"] doubleValue], [params[@"tlng"] doubleValue]);
  if (! CLLocationCoordinate2DIsValid(end)) {
    return;
  }

  NSInteger typeInt = [params[@"type"] integerValue];
  if (typeInt < 0 || typeInt > 2)
    return;
  
  SGTimeType timeType = (SGTimeType) typeInt;
  NSDate *time = timeType == SGTimeTypeLeaveASAP ? nil : [NSDate dateWithTimeIntervalSince1970:[params[@"time"] doubleValue]];
  detailBlock(start, end, timeType, time);
}


#pragma mark - Stops

+ (BOOL)isStopURL:(NSURL *)url {
  return [[url path] isEqualToString:@"/stop"];
}

+ (NSURL *)stopURLForStopCode:(NSString *)stopCode
                inRegionNamed:(NSString *)regionName
                       filter:(NSString *)filter
{
  NSString *addendum = filter ? [NSString stringWithFormat:@"%@", [filter stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]] : @"";
//  NSString *urlString = [NSString stringWithFormat:@"http://tripgo.me/stop/%@/%@/%@", regionName, [stopCode stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding], addendum];
  NSString *urlString = [NSString stringWithFormat:@"http://tripgo.me/stop?regionName=%@&stopCode=%@&filter=%@", regionName, [stopCode stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding], addendum];
  return [NSURL URLWithString:urlString];
}

+ (void)stopDetailsForURL:(NSURL *)url
                  details:(void (^)(NSString *stopCode, NSString *regionName, NSString *filter))detailBlock {
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
  if (! params[@"stopCode"] || ! params[@"regionName"])
    return;
  
  NSString *regionName = params[@"regionName"];
  NSString *stopCode = [params[@"stopCode"] stringByRemovingPercentEncoding];
  NSString *filter = [params[@"filter"] stringByRemovingPercentEncoding];

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
  NSString *urlString = [NSString stringWithFormat:@"http://tripgo.me/service?regionName=%@&stopCode=%@&serviceID=%@", regionName, [stopCode stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding], [serviceID stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
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
