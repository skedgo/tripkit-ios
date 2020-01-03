//
//  BHBuzzRealTime.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 2/11/12.
//
//

#import "TKBuzzRealTime.h"

#import <TripKit/TripKit-Swift.h>

@interface TKBuzzRealTime ()

@property (nonatomic, strong) TKRouter *helperRouter;

@end

@implementation TKBuzzRealTime

- (void)updateTrip:(Trip *)trip
           success:(void (^)(Trip *trip, BOOL tripUpdated))success
           failure:(void (^)(NSError *error))failure {
  if (trip == nil) {
    ZAssert(false, @"Don't call this without a trip");
    return;
  }
  
  if (trip.request == nil) {
    DLog(@"Not updating trip as it doesn't have a request (anymore): %@", trip);
    return;
  }

  [self.helperRouter updateTrip:trip
             completionWithFlag:
   ^(Trip * updatedTrip, BOOL wasUpdated) {
     if (updatedTrip == trip) {
       success(trip, wasUpdated);
     } else {
       failure(nil);
     }
  }];
}

+ (void)updateDLSEntries:(NSSet<DLSEntry *> *)entries
                inRegion:(TKRegion *)region
                 success:(void (^)(NSSet<DLSEntry *> *entries))success
                 failure:(void (^)(NSError *error))failure
{
  NSMutableArray *servicesParamsArray     = [NSMutableArray arrayWithCapacity:entries.count];
  NSMutableDictionary *objectsLookup = [NSMutableDictionary dictionaryWithCapacity:entries.count];
  NSManagedObjectContext *context = nil;
  for (DLSEntry *entry in entries) {
    Service *service = entry.service;
    if (! [service wantsRealTimeUpdates]) {
      continue;
    }
    if (context == nil) {
      context = service.managedObjectContext;
    } else {
      ZAssert(context == service.managedObjectContext, @"Context mismatches");
    }

    NSString *operatorName = service.operatorName ?: @"";
    [servicesParamsArray addObject:@{
                                     @"serviceTripID" : service.code,
                                     @"operator"      : operatorName,
                                     @"startStopCode" : entry.stop.stopCode,
                                     @"startTime"     : @([entry.originalTime timeIntervalSince1970]),
                                     @"endStopCode"   : entry.endStop.stopCode,
                                     }];
    [objectsLookup setValue:entry forKey:service.code];
  }

  if (context == nil) {
    ZAssert(servicesParamsArray.count == 0, @"Should only get there if there's nothing to do");
    success(entries);
    return;
  }
  
  [TKBuzzRealTime fetchUpdatesForServiceParas:servicesParamsArray
                                    forRegion:region
                                      success:
   ^(id responseObject) {
     [context performBlock:^{
       [TKBuzzRealTime updateObjects:objectsLookup
                  withResponseObject:responseObject];
       success(entries);
     }];
   }
                                      failure:failure];
}

+ (void)updateEmbarkations:(NSSet<StopVisits *> *)embarkations
                  inRegion:(TKRegion *)region
                   success:(void (^)(NSSet<StopVisits *> *embarkations))success
                   failure:(void (^)(NSError *error))failure
{
  NSMutableArray *servicesParamsArray     = [NSMutableArray arrayWithCapacity:embarkations.count];
  NSMutableDictionary *objectsLookup = [NSMutableDictionary dictionaryWithCapacity:embarkations.count];
  NSManagedObjectContext *context = nil;
  for (StopVisits *visit in embarkations) {
    Service *service = visit.service;
    if (! [service wantsRealTimeUpdates]) {
      continue;
    }
    if (context == nil) {
      context = service.managedObjectContext;
    } else {
      ZAssert(context == service.managedObjectContext, @"Context mismatches");
    }
    
    NSString *operatorName = service.operatorName ?: @"";
    [servicesParamsArray addObject:@{
                                     @"serviceTripID" : service.code,
                                     @"operator"      : operatorName,
                                     @"startStopCode" : visit.stop.stopCode,
                                     @"startTime"     : @([visit.originalTime timeIntervalSince1970]),
                                     }];
    [objectsLookup setValue:visit forKey:service.code];
  }
  
  if (context == nil) {
    ZAssert(servicesParamsArray.count == 0, @"Should only get there if there's nothing to do");
    success(embarkations);
    return;
  }
  
  [TKBuzzRealTime fetchUpdatesForServiceParas:servicesParamsArray
                                    forRegion:region
                                      success:
   ^(id responseObject) {
     [context performBlock:^{
       [TKBuzzRealTime updateObjects:objectsLookup
                  withResponseObject:responseObject];
       success(embarkations);
     }];
   }
                                      failure:failure];
}

+ (void)updateServices:(NSSet<Service *> *)services
              inRegion:(TKRegion *)region
               success:(void (^)(NSSet<Service *> *services))success
               failure:(void (^)(NSError *error))failure
{
  NSMutableArray *servicesParamsArray     = [NSMutableArray arrayWithCapacity:services.count];
  NSMutableDictionary *servicesLookupDict = [NSMutableDictionary dictionaryWithCapacity:services.count];
  NSManagedObjectContext *context = nil;
  for (Service *service in services) {
    if (! [service wantsRealTimeUpdates]) {
      continue;
    }
    if (context == nil) {
      context = service.managedObjectContext;
    } else {
      ZAssert(context == service.managedObjectContext, @"Context mismatches");
    }
    NSString *operatorName = service.operatorName ?: @"";
    [servicesParamsArray addObject:@{
                                     @"serviceTripID" : service.code,
                                     @"operator"      : operatorName
                                     }];
    [servicesLookupDict setValue:service forKey:service.code];
  }
  
  if (context == nil) {
    ZAssert(servicesParamsArray.count == 0, @"Should only get there if there's nothing to do");
    success(services);
    return;
  }
  
  [TKBuzzRealTime fetchUpdatesForServiceParas:servicesParamsArray
                                    forRegion:region
                                      success:
   ^(id responseObject) {
     [context performBlock:^{
       [TKBuzzRealTime updateObjects:servicesLookupDict
              withResponseObject:responseObject];
       success(services);
     }];
   }
                                      failure:failure];
}

+ (void)fetchUpdatesForServiceParas:(NSArray *)serviceParas
                          forRegion:(TKRegion *)region
                            success:(void (^)(id __nullable responseObject))success
                            failure:(void (^)(NSError * __nullable error))failure
{
  if (!region) {
    failure(nil);
    return;
  }
	if (! region.name) {
		ZAssert(false, @"Bad region with no name: %@", region);
		failure([NSError errorWithCode:kTKErrorTypeInternal message:@"Region has no name."]);
		return;
	}
  if (serviceParas.count == 0) {
    success(nil);
    return;
  }
  
  
	
	// construct the parameters
	NSDictionary *paras = @{
		@"region"   : region.name,
		@"block"    : @(NO),
		@"services" : serviceParas,
	};
	
	// now send it off to the server
	TKServer *server = [TKServer sharedInstance];
  [server hitSkedGoWithMethod:@"POST"
                         path:@"latest.json"
                   parameters:paras
                       region:region
               callbackOnMain:NO
                      success:
   ^(NSInteger status, id responseObject, NSData *data) {
#pragma unused(status, data)
     success(responseObject);
   }
                             failure:
   ^(NSError *error) {
     DLog(@"Error response: %@", error);
     failure(error);
   }];
}

#pragma mark - Private helpers

+ (void)updateObjects:(NSDictionary *)serviceIDToObjectDict
   withResponseObject:(id)responseObject
{
	ZAssert(serviceIDToObjectDict, @"Method requires map");
	
	NSArray *servicesArray = responseObject[@"services"];
	if (servicesArray.count == 0) {
    [TKLog verbose:@"TKBuzzRealTime" text:@"Received no results."];
		return;
	}
	
	for (NSDictionary *serviceDict in servicesArray) {
		NSString *serviceID = serviceDict[@"serviceTripID"];
		id object           = serviceIDToObjectDict[serviceID];

    DLSEntry *dls;
    StopVisits *visit;
    Service *service;
    if ([object isKindOfClass:[DLSEntry class]]) {
      dls = object;
      service = dls.service;
    } else if ([object isKindOfClass:[StopVisits class]]) {
      visit = object;
      service = visit.service;
    } else if ([object isKindOfClass:[Service class]]) {
      service = object;
    }
    
    
		if (! service) {
			DLog(@"No matching service for code: %@", serviceID);
			continue;
		}
		
		if (! service.managedObjectContext) {
			DLog(@"Service has no context: %@", service);
			continue;
		}
		
		// Parse the vehicle
    NSDictionary *vehicleDict = serviceDict[@"realtimeVehicle"];
    NSArray *alternativeVehiclesArray = serviceDict[@"realtimeVehicleAlternatives"];
    [TKAPIToCoreDataConverter updateVehiclesForService:service primaryVehicle:vehicleDict alternativeVehicles:alternativeVehiclesArray];
				
		if (dls || visit) {
			// we have supplied a start stop code, so we only want to update that
			
			NSNumber *startTime = serviceDict[@"startTime"];
			if (! startTime)
				continue;
			if (startTime.integerValue <= 0) {
        		[TKLog info:@"TKBuzzRealTime" format:@"Ignoring bad start time '%@' in response object:\n%@", startTime, responseObject];
				continue;
			}
			NSDate *departure = [NSDate dateWithTimeIntervalSince1970:startTime.integerValue];
			
      if (visit) {
        visit.departure = departure;
        [visit triggerRealTimeKVO];
        service.realTime = YES;

      } else if (dls) {
        NSTimeInterval previousDuration = [dls.arrival timeIntervalSinceDate:dls.departure];
        dls.departure = departure;
        NSNumber *endTime = serviceDict[@"endTime"];
        if (endTime && endTime.integerValue > 0) {
          dls.arrival = [NSDate dateWithTimeIntervalSince1970:endTime.integerValue];
        } else {
          dls.arrival = [dls.departure dateByAddingTimeInterval:previousDuration];
        }
        service.realTime = YES;
      }
			
		} else {
			// we want to update all the stops in the service
			
			// first turn it into look-up dictionaries
			NSArray *stops                  = serviceDict[@"stops"];
			if (! stops)
				continue;
      service.realTime = YES;

      NSMutableDictionary *arrivals   = [NSMutableDictionary dictionaryWithCapacity:stops.count];
			NSMutableDictionary *departures = [NSMutableDictionary dictionaryWithCapacity:stops.count];
			for (NSDictionary *stopDict in stops) {
				NSString *code = stopDict[@"stopCode"];
				NSNumber *time = stopDict[@"arrival"];
				if (time) {
          arrivals[code] = [NSDate dateWithTimeIntervalSince1970:time.integerValue];
				}
				time = stopDict[@"departure"];
				if (time) {
          departures[code] = [NSDate dateWithTimeIntervalSince1970:time.integerValue];
				}
			}
			
			// next update all the stops
			NSTimeInterval delay = 0;
			for (StopVisits *aVisit in service.sortedVisits) {
				NSString *visitCode = aVisit.stop.stopCode;
				NSDate *newArrival = arrivals[visitCode];
				if (newArrival) {
          if (aVisit.arrival) delay = [newArrival timeIntervalSinceDate:aVisit.arrival];
					aVisit.arrival = newArrival;
				}
				NSDate *newDeparture = departures[visitCode];
				if (newDeparture) {
          if (aVisit.departure) delay = [newDeparture timeIntervalSinceDate:aVisit.departure];
					// use time for KVO
					aVisit.departure = newDeparture;
          [aVisit triggerRealTimeKVO];
				}
				if (! newArrival && aVisit.arrival && fabs(delay) < 1) {
					aVisit.arrival = [aVisit.arrival dateByAddingTimeInterval:delay];
				}
				if (! newDeparture && aVisit.departure && fabs(delay) < 1) {
					// use time for KVO
					aVisit.departure = [aVisit.departure dateByAddingTimeInterval:delay];
          [aVisit triggerRealTimeKVO];
				}
			}
		}
	}
}

#pragma mark - Lazy accessors

- (TKRouter *)helperRouter
{
  if (!_helperRouter) {
    _helperRouter = [[TKRouter alloc] init];
  }
  return _helperRouter;
}

@end
