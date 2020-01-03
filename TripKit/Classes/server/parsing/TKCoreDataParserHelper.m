//
//  TKCoreDataParserHelper.m
//  TripKit
//
//  Created by Adrian Schoenig on 7/04/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "TKCoreDataParserHelper.h"

#import <TripKit/TripKit-Swift.h>

@implementation TKCoreDataParserHelper

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
                withModeInfo:(nullable TKModeInfo *)modeInfo
               clearRealTime:(BOOL)clearRealTime
{
  return [self insertNewShapes:shapesArray
                    forService:service
                  relativeTime:nil
                  withModeInfo:modeInfo
              orTripKitContext:nil
                 clearRealTime:clearRealTime];
}

+ (NSArray *)insertNewShapes:(NSArray *)shapesArray
                  forService:(nullable Service *)requestedService
                relativeTime:(nullable NSDate *)relativeTime
                withModeInfo:(nullable TKModeInfo *)modeInfo
            orTripKitContext:(nullable NSManagedObjectContext *)context
               clearRealTime:(BOOL)clearRealTime
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
  
  int index = 0;
  
  for (NSDictionary *shapeDict in shapesArray) {
    // is there any content in this shape?
    NSString *encodedWaypoints = shapeDict[@"encodedWaypoints"];
    if (encodedWaypoints.length == 0)
      continue;
    
    // get information about the service if there's any in there
    NSString *serviceCode = shapeDict[@"serviceTripID"];
    BOOL fillService = NO;
    if (serviceCode && previousService && NO == [previousService.code isEqualToString:serviceCode]) {
      // we need a new service
      if ([serviceCode isEqualToString:requestedService.code]) {
        currentService = requestedService;
        
      } else {
        currentService = [Service fetchOrInsertServiceWithCode:serviceCode inTripKitContext:context];
        fillService = YES;
      }
    } else {
      // just use the existing service
      currentService = requestedService;
    }
    
    if (fillService || currentService.code == nil) {
      currentService.code = serviceCode;
      currentService.color = [TKParserHelper colorForDictionary:[shapeDict objectForKey:@"serviceColor"]] ?: requestedService.color;
      currentService.frequency  = shapeDict[@"frequency"];
      currentService.lineName   = shapeDict[@"serviceName"];
      currentService.direction  = shapeDict[@"serviceDirection"];
      currentService.number     = shapeDict[@"serviceNumber"];
      currentService.modeInfo   = modeInfo;
    }
    
    if (previousService != currentService) {
      currentService.progenitor = previousService;
    }
    
    if (clearRealTime) {
      [currentService setRealTime:NO];
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
    if (nil == shape.travelled) {
      shape.travelled = @(YES);
    }
    
    if ([shape.travelled boolValue]) {
      // we only associate the travelled section here, which isn't great
      // but better than only associating the last one...
      currentService.shape = shape;
    }
    
    // remember the existing visits
    NSMutableDictionary *existingVisits = [NSMutableDictionary dictionaryWithCapacity:currentService.visits.count];
    for (StopVisits *visit in currentService.visits) {
      if ([visit isKindOfClass:[DLSEntry class]]) {
        continue;
      }
      
      if (visit.stop.stopCode) {
        [existingVisits setValue:visit forKey:visit.stop.stopCode];
      } else {
        DLog(@"A stop visit without a stop code for its stop snuck in: %@", visit.stop);
      }
    }
    
    // add the stops (if we have any)
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
      
      [self configureVisit:visit fromShapeStopDict:stopDict timesRelativeToDate:relativeTime];
      
      // hook-up to shape
      [visit addShapesObject:shape];
      
      if (! existingVisit) {
        // we added a new visit
        TKNamedCoordinate *coordinate = [TKParserHelper namedCoordinateForDictionary:stopDict];
        
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
    if (previousService != currentService && currentService && previousService) {
      index = 0;
    }
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
