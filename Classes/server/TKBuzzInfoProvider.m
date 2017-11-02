//
//  BHBuzzInfoProvider.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 29/11/12.
//
//

#import "TKBuzzInfoProvider.h"

#import <TripKit/TKTripKit.h>
#import <TripKit/TripKit-Swift.h>

@implementation TKBuzzInfoProvider


- (void)downloadContentOfService:(Service *)service
							forEmbarkationDate:(NSDate *)date
												inRegion:(SVKRegion *)regionOrNil
											completion:(SGServiceCompletionBlock)completion
{
  NSParameterAssert(service);
  NSParameterAssert(date);
  NSParameterAssert(completion);
  
  ZAssert(service.managedObjectContext.parentContext != nil || [NSThread isMainThread], @"Not on the right thread!");
  

  ZAssert(service.managedObjectContext, @"Service with a context needed.");
  
  if (service.isRequestingServiceData) {
    return; // don't send multiple requests
  }
  
  service.isRequestingServiceData = YES;
	SVKServer *server = [SVKServer sharedInstance];
  [server requireRegions:
   ^(NSError *error) {
     if (error) {
       DLog(@"Error fetching regions: %@", error);
       completion(service, NO);
       return;
     }
     
     SVKRegion *region = regionOrNil ?: service.region;
     if (! region) {
       completion(service, NO);
       return;
     }
     
     NSString *operatorName = service.operatorName ?: @"";
     
     // construct the parameters
     ZAssert(service && service.managedObjectContext, @"Service with a context needed.");
     NSDictionary *paras = @{
                             @"region"						: region.name,
                             @"serviceTripID"	    : service.code,
                             @"operator"	        : operatorName,
                             @"embarkationDate"	  : @([date timeIntervalSince1970]),
                             @"encode"						: @(YES)
                             };
     
     // now send it off to the server
     __weak typeof(self) weakSelf = self;
     [server hitSkedGoWithMethod:@"GET"
                            path:@"service.json"
                      parameters:paras
                          region:region
                  callbackOnMain:NO
                         success:
      ^(NSInteger status, id responseObject, NSData *data) {
#pragma unused(status, data)
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }
        
        [service.managedObjectContext performBlock:^{
          service.isRequestingServiceData = NO;
          if (! responseObject[@"error"]) {
            ZAssert(service && service.managedObjectContext, @"Service with a context needed.");
            [strongSelf addContentToService:service
                               fromResponse:responseObject];
            completion(service, YES);
            
          } else {
            completion(service, NO);
          }
        }];
      }
                         failure:
      ^(NSError *operationError) {
#pragma unused(operationError)
        DLog(@"Error response: %@", operationError);
        [service.managedObjectContext performBlock:^{
          service.isRequestingServiceData = NO;
          completion(service, NO);
        }];
      }];
   }];
}

+ (NSError *)errorForUserForBrokenStop
{
  NSDictionary *info = @{
                         NSLocalizedDescriptionKey: NSLocalizedStringFromTableInBundle(@"Could not find transit stop.", @"TripKit", [TKTripKit bundle], "Error title when server could not find a given transit stop."),
                         NSLocalizedRecoverySuggestionErrorKey: NSLocalizedStringFromTableInBundle(@"Search for this stop again or try again later..", @"TripKit", [TKTripKit bundle], "Error recovery suggestion for when when server could not find a given transit stop."),
                         };
  return [NSError errorWithDomain:@"com.buzzhives.TripKit" code:831571 userInfo:info];
}

+ (void)fillInStop:(StopLocation *)stop
             named:(nullable NSString *)name
        completion:(void (^)(NSError *))completion
{
  NSParameterAssert(stop);
  NSParameterAssert(completion);
  
  // now send it off to the server
  SVKServer *server = [SVKServer sharedInstance];
  
  [server requireRegions:^(NSError *error) {
    if (error) {
      DLog(@"Error filling in stop: %@", error.localizedDescription);
      completion(error);
      return;
    }
    
    SVKRegion *region = stop.region;
    if (! region) {
      // We have regions, but this stop doesn't match any known region
      completion([TKBuzzInfoProvider errorForUserForBrokenStop]);
      return;
    }
    
    // construct the parameters
    NSMutableDictionary *paras = [NSMutableDictionary dictionary];
    paras[@"region"] = stop.regionName;
    paras[@"code"] = stop.stopCode;
    paras[@"name"] = stop.name ?: name;
    paras[@"modeInfo"] = stop.stopModeInfo;
    
    if (stop.location) {
      CLLocationCoordinate2D coordinate = stop.coordinate;
      if (CLLocationCoordinate2DIsValid(coordinate)) {
        paras[@"lat"] = @(coordinate.latitude);
        paras[@"lng"] = @(coordinate.longitude);
      }
    }
    
    [server hitSkedGoWithMethod:@"POST"
                           path:@"stopFinder.json"
                     parameters:paras
                         region:region
                 callbackOnMain:NO
                        success:
     ^(NSInteger status, id responseObject, NSData *data) {
#pragma unused(status, data)
        // set the stop properties
       [stop.managedObjectContext performBlock:^{
         BOOL success = [TKBuzzInfoProvider addStop:stop fromResponse:responseObject];
         ZAssert(success, @"Error processing: %@", responseObject);
         completion(nil);
       }];
     }
                               failure:
     ^(NSError *anotherError) {
       dispatch_async(dispatch_get_main_queue(), ^{
         DLog(@"Error response: %@", anotherError);
         completion(anotherError);
       });
     }];
  }];
}

- (void)addContentToService:(Service *)service
               fromResponse:(NSDictionary *)responseDict
{
  NSParameterAssert(service);
  NSParameterAssert(responseDict);
  
  ZAssert(service.managedObjectContext.parentContext != nil || [NSThread isMainThread], @"Not on the right thread!");
  
  NSManagedObjectContext *context = service.managedObjectContext;
  
  // real time status
  NSString *realTimeStatus = responseDict[@"realTimeStatus"];
  if (realTimeStatus) {
    [TKParserHelper adjustService:service
          forRealTimeStatusString:realTimeStatus];
  }
  
  // real time vehicles
  [TKAPIToCoreDataConverter updateVehiclesForService:service
                                      primaryVehicle:responseDict[@"realtimeVehicle"]
                                 alternativeVehicles:responseDict[@"realtimeVehicleAlternatives"]];
  
  // alert
  [TKAPIToCoreDataConverter updateOrAddAlerts:responseDict[@"alerts"]
                             inTripKitContext:context];
  
  // mode info
  ModeInfo *modeInfo = [ModeInfo modeInfoForDictionary:responseDict[@"modeInfo"]];
  
  // accessibility
  if ([responseDict[@"wheelchairAccessible"] boolValue]) {
    service.wheelchairAccessible = true;
  }
  if ([responseDict[@"bicycleAccessible"] boolValue]) {
    service.bicycleAccessible = true;
  }
  
  // parse the shapes
  NSArray *shapesArray = responseDict[@"shapes"];
  [TKParserHelper insertNewShapes:shapesArray
                       forService:service
                     withModeInfo:modeInfo];
}

#pragma mark - Private methods

+ (BOOL)addStop:(StopLocation *)stop
   fromResponse:(id)responseObject
{
  if ([responseObject count] == 0) {
    return NO;
  }
  ZAssert(stop.managedObjectContext.parentContext != nil || [NSThread isMainThread], @"Not on the right thread!");
  
  NSManagedObjectContext *tripKitContext = stop.managedObjectContext;
  
  NSArray *groups = responseObject[@"groups"];
  if (groups) {
    for (NSDictionary *groupDict in groups) {
      NSString *key = groupDict[@"key"];
      if (! [key isEqualToString:stop.stopCode])
        continue;
      
      NSArray *stopList = groupDict[@"stops"];
      for (NSDictionary *stopDict in stopList) {
        NSString *code = stopDict[@"code"];
        
        // is this our stop?
        if ([stop.stopCode isEqualToString:code]) {
          [TKAPIToCoreDataConverter updateStopLocation:stop
                                        fromDictionary:stopDict];
          
        } else {
          // we always add all the stops, because the cell is new
          StopLocation *newStop = [TKAPIToCoreDataConverter insertNewStopLocation:stopDict
                                                                 inTripKitContext:tripKitContext];
          
          // make sure we have an ID
          NSError *error = nil;
          [tripKitContext obtainPermanentIDsForObjects:@[newStop] error:&error];
          ZAssert(! error, @"Error obtaining permanent ID for '%@': %@", newStop, error);
        }
      }
      return stopList.count > 0;
    }
    return NO;
  
  } else {
    [TKAPIToCoreDataConverter updateStopLocation:stop fromDictionary:responseObject];
    return YES;
  }
}

@end
