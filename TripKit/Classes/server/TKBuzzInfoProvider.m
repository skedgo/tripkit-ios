//
//  BHBuzzInfoProvider.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 29/11/12.
//
//

#import "TKBuzzInfoProvider.h"

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



@end
