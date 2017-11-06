//
//  TKParserHelper.m
//  TripKit
//
//  Created by Adrian Schoenig on 7/04/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "TKParserHelper.h"



#import <TripKit/TKTripKit.h>
#import <TripKit/TripKit-Swift.h>

@implementation TKParserHelper

#pragma mark - Segments

+ (NSNumber *)segmentTypeForString:(NSString *)typeString
{
  if ([typeString isEqualToString:@"scheduled"]) {
    return @(TKSegmentTypeScheduled);
  } else if ([typeString isEqualToString:@"unscheduled"]) {
    return @(TKSegmentTypeUnscheduled);
  } else if ([typeString isEqualToString:@"stationary"]) {
    return @(TKSegmentTypeStationary);
  } else {
    ZAssert(true, @"Encountered unknown segment type: '%@'", typeString);
    return nil;
  }
}

#pragma mark - Creating our classes

+ (void)updateVehiclesForSegmentReference:(SegmentReference *)reference
                           primaryVehicle:(NSDictionary *)primaryVehicleDict
                      alternativeVehicles:(NSArray *)alternativeVehicleDicts
{
  NSParameterAssert(reference);
  if (primaryVehicleDict) {
    if (reference.realTimeVehicle) {
      [TKAPIToCoreDataConverter updateVehicle:reference.realTimeVehicle fromDictionary:primaryVehicleDict];
    } else {
      Vehicle *vehicle = [TKAPIToCoreDataConverter insertNewVehicle:primaryVehicleDict
                                                   inTripKitContext:reference.managedObjectContext];
      reference.realTimeVehicle = vehicle;
    }
  }
  
  if (alternativeVehicleDicts.count > 0) {
    for (NSDictionary *alternativeVehicleDict in alternativeVehicleDicts) {
      Vehicle *existingVehicle = nil;
      NSString *alternativeIdentifier = alternativeVehicleDict[@"id"];
      for (Vehicle *existingAlternative in reference.realTimeVehicleAlternatives) {
        if ([existingAlternative.identifier isEqualToString:alternativeIdentifier]) {
          existingVehicle = existingAlternative;
          break;
        }
      }
      if (existingVehicle) {
        [TKAPIToCoreDataConverter updateVehicle:existingVehicle fromDictionary:alternativeVehicleDict];
      } else {
        Vehicle *newAlternative = [TKAPIToCoreDataConverter insertNewVehicle:alternativeVehicleDict
                                                            inTripKitContext:reference.managedObjectContext];
        [reference addRealTimeVehicleAlternativesObject:newAlternative];
      }
    }
  }
}

+ (NSArray *)insertNewShapes:(NSArray *)shapesArray
                  forService:(Service *)service
                withModeInfo:(ModeInfo *)modeInfo
{
  return [self insertNewShapes:shapesArray
                    forService:service
                  withModeInfo:modeInfo
              orTripKitContext:nil];
}

+ (NSArray *)insertNewShapes:(NSArray *)shapesArray
                  forService:(Service *)requestedService
                withModeInfo:(ModeInfo *)modeInfo
            orTripKitContext:(NSManagedObjectContext *)context
{
  if (context == nil) {
    ZAssert(requestedService, @"If you don't supply a context, you need to supply a service!");
    context = requestedService.managedObjectContext;
    ZAssert(context, @"We need a context!");
  }
  
  NSMutableArray *addedShapes = [NSMutableArray arrayWithCapacity:shapesArray.count];
  
  int waypointGroupCount = 0;
  
  Service *previousService = nil;
  Service *currentService = nil;
  
  for (NSDictionary *shapeDict in shapesArray) {
    // is there any content in this shape?
    NSString *encodedWaypoints = shapeDict[@"encodedWaypoints"];
    if (encodedWaypoints.length == 0)
      continue;
    
    // get information about the service if there's any in there
    NSString *serviceCode = shapeDict[@"serviceTripID"];
    if (serviceCode && NO == [serviceCode isEqualToString:previousService.code]) {
      // we need a new service
      if ([serviceCode isEqualToString:requestedService.code]) {
        currentService = requestedService;
      } else {
        // see if we have an object for this already
        currentService = [Service fetchExistingServiceWithCode:serviceCode inTripKitContext:context];
        if (! currentService) {
          currentService = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Service class])
                                                         inManagedObjectContext:context];
          currentService.code = serviceCode;
        }
        currentService.color = [SVKParserHelper colorForDictionary:[shapeDict objectForKey:@"serviceColor"]];
        currentService.frequency  = shapeDict[@"frequency"];
        currentService.lineName   = shapeDict[@"serviceName"];
        currentService.direction  = shapeDict[@"serviceDirection"];
        currentService.number     = shapeDict[@"serviceNumber"];
      }
    } else {
      // just use the existing service
      currentService = requestedService;
    }
    
    if (previousService != currentService) {
      currentService.progenitor = previousService;
    }
    
    // create the new shape
    Shape *shape = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Shape class]) inManagedObjectContext:context];
    shape.index = waypointGroupCount++;
    shape.travelled = shapeDict[@"travelled"];
    shape.title = shapeDict[@"name"];
    shape.encodedWaypoints = encodedWaypoints;
    shape.isDismount = [shapeDict[@"dismount"] boolValue];
    shape.isHop = [shapeDict[@"hop"] boolValue];
    shape.metres = shapeDict[@"metres"];
    [shape setSafety: shapeDict[@"safe"]];
    if (nil == shape.travelled)
      shape.travelled = @(YES);
    
    // associate it with the service
    currentService.shape = shape;
    
    // remember the existing visits
    NSMutableDictionary *existingVisits = [NSMutableDictionary dictionaryWithCapacity:currentService.visits.count];
    for (StopVisits *visit in currentService.visits) {
      if (! [visit isKindOfClass:[DLSEntry class]] // ignore DLS entries
          && visit.stop.stopCode) {
        [existingVisits setValue:visit forKey:visit.stop.stopCode];
      } else {
        DLog(@"A stop visit without a stop code for it's stop snuck in: %@", visit.stop);
      }
    }
    
    // add the stops (if we have any)
    int index = 0;
    for (NSDictionary *stopDict in [shapeDict objectForKey:@"stops"]) {
      ZAssert(currentService, @"When you try to add stops, you need a service!");
      
      // try to re-use existing visits
      NSString *stopCode = [stopDict objectForKey:@"code"];
      StopVisits *existingVisit = [existingVisits objectForKey:stopCode];
      StopVisits *visit = existingVisit;
      if (! visit) {
        visit = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([StopVisits class]) inManagedObjectContext:context];
        visit.service   = currentService;
      }
      visit.index = @(index++);
      
      // when we re-use an existing visit, we need to be conservative
      // as to not overwrite a previous arrival/departure with a new 'nil'
      // value. this can happen, say, with the 555 loop where 'circular quay'
      // is both the first and last stop. we don't want to overwrite the
      // initial departure with the nil value when the service gets back there
      // at the end of its loop.
      NSNumber *bearing = [stopDict objectForKey:@"bearing"];
      if (bearing)
        visit.bearing   = bearing;
      
      NSNumber *arrivalRaw = [stopDict objectForKey:@"arrival"];
      NSNumber *departureRaw = [stopDict objectForKey:@"departure"];
      if (arrivalRaw || departureRaw) {
        if (arrivalRaw) {
          visit.arrival = [NSDate dateWithTimeIntervalSince1970:arrivalRaw.longValue];
          
        }
        if (departureRaw) {
          // we use 'time' to allow KVO
          visit.time = [NSDate dateWithTimeIntervalSince1970:departureRaw.longValue];
        }
        
        // keep original time before we touch it with real-time data
        visit.originalTime = [visit time];
        
        // frequency-based entries don't have times, so they don't have a region-day either
        [visit adjustRegionDay];
      }
      
      // hook-up to shape
      [visit addShapesObject:shape];
      
      if (! existingVisit) {
        // we added a new visit
        SGKNamedCoordinate *coordinate = [[SGKNamedCoordinate alloc] initWithLatitude:[stopDict[@"lat"] doubleValue]
                                                                          longitude:[stopDict[@"lng"] doubleValue]
                                                                               name:stopDict[@"name"]
                                                                            address:nil];
        
        // we used to fetchOrInsert here, but the duplicate checking is remarkably slow
        StopLocation *stop = [StopLocation insertStopForStopCode:stopCode
                                                        modeInfo:modeInfo
                                                      atLocation:coordinate
                                              intoTripKitContext:context];
        stop.shortName = stopDict[@"shortName"];
        stop.wheelchairAccessible = stopDict[@"wheelchairAccessible"];
        
        ZAssert(! visit.stop || visit.stop == stop, @"We shouldn't have a stop already! %@", visit.stop);
        visit.stop = stop;
      }
      
      ZAssert(visit.stop, @"Visit needs a stop!");
    }
    
    [addedShapes addObject:shape];
    previousService = currentService;
  }
  return addedShapes;
}

#pragma mark - Adjusting our classes

+ (void)adjustService:(Service *)service forRealTimeStatusString:(NSString *)realTimeStatus
{
  // update the real-time status
  if ([realTimeStatus isEqualToString:@"IS_REAL_TIME"]) {
    service.realTime				= YES;
    service.realTimeCapable = YES;
    service.cancelled			  = NO;
  } else if ([realTimeStatus isEqualToString:@"CAPABLE"]) {
    service.realTime				= NO;
    service.realTimeCapable = YES;
    service.cancelled			  = NO;
  } else if ([realTimeStatus isEqualToString:@"CANCELLED"]) {
    service.realTime				= NO;
    service.realTimeCapable	= YES;
    service.cancelled				= YES;
  }
}



@end
