//
//  TKWaypointRouter.m
//  TripGo
//
//  Created by Adrian Schoenig on 7/04/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "TKWaypointRouter.h"

#import "TKTripKit.h"
#import "TripKit/TripKit-Swift.h"

@interface TKWaypointRouter ()

@property (nonatomic, assign) BOOL isActive;

@end

@implementation TKWaypointRouter

- (void)fetchTripReplacingSegment:(TKSegment *)segment
                     withDLSEntry:(DLSEntry *)dlsEntry
             usingPrivateVehicles:(nullable NSArray *)privateVehicles
                       completion:(void(^)(Trip * __nullable trip, NSError * __nullable error))completion
{
  SVKServer *server = [SVKServer sharedInstance];
  [server requireRegions:^(NSError *error) {
    TripRequest *request = segment.trip.request;
    SVKRegion *region = request.startRegion;
    if (error || !region) {
      completion(nil, error);
      return;
    }
    
    NSDictionary *paras = [[self class] waypointParasForReplacing:segment
                                                     withDLSEntry:dlsEntry
                                                         inRegion:region
                                             usingPrivateVehicles:privateVehicles];
    [self fetchTripUsingWaypointParas:paras
                             inRegion:region
                         forTripGroup:segment.trip.tripGroup
                           completion:completion];
  }];
}


#pragma mark - Private methods

- (void)fetchTripUsingWaypointParas:(NSDictionary *)paras
                           inRegion:(SVKRegion *)region
                       forTripGroup:(TripGroup *)tripGroup
                         completion:(TripFactoryCompletionBlock)completion
{
  SVKServer *server = [SVKServer sharedInstance];
  self.isActive = YES;
  [server hitSkedGoWithMethod:@"POST"
                         path:@"waypoint.json"
                   parameters:paras
                       region:region
               callbackOnMain:NO
                      success:
   ^(NSInteger status, id responseObject) {
#pragma unused(status)
     NSManagedObjectContext *publicContext = tripGroup.managedObjectContext;
     [publicContext performBlock:^{
       TKRoutingParser *parser = [[TKRoutingParser alloc] initWithTripKitContext:publicContext];
       [parser parseAndAddResult:responseObject
                   intoTripGroup:tripGroup
                         merging:NO
                      completion:
        ^(NSArray *addedTrips) {
          Trip *trip = [addedTrips firstObject];
          NSAssert(! trip || trip.managedObjectContext == publicContext, @"Context mismatch");
          completion(trip, nil);
        }];
     }];
   }
                             failure:
   ^(NSError *error) {
     [tripGroup.managedObjectContext performBlock:^{
       NSLog(@"Error fetching trip through waypoints: %@", error);
       completion(nil, error);
     }];
   }];
}

+ (NSDictionary *)waypointParasForReplacing:(TKSegment *)prototype
                               withDLSEntry:(DLSEntry *)entry
                                   inRegion:(SVKRegion *)region
                       usingPrivateVehicles:(NSArray *)privateVehicles
{
  NSMutableDictionary *paras = [NSMutableDictionary dictionaryWithCapacity:2];
  paras[@"config"] = [TKSettings defaultDictionary];
  paras[@"vehicles"] = [TKParserHelper vehiclesPayloadForVehicles:privateVehicles];
  
  NSArray *segments = prototype.trip.segments;
  NSMutableArray *arrayParas = [NSMutableArray arrayWithCapacity:segments.count];
  for (TKSegment *segment in segments) {
    if ([segment isContinuation]) {
      continue; // ignore these, entry's endStop and segment's finalSegment take care of these
    }
    
    if (segment == prototype) {
      [arrayParas addObject:
       @{
         @"start": entry.stop.stopCode,
         @"end": entry.endStop.stopCode,
         @"modes": @[ segment.modeIdentifier ],
         @"startTime": @([entry.departure timeIntervalSince1970]),
         @"endTime": @([entry.arrival timeIntervalSince1970]),
         @"serviceTripID": entry.service.code,
         @"operator": entry.service.operatorName,
         @"region": region.name
         }
       ];
    } else if (! [segment isStationary]) {
      NSMutableDictionary *segmentDict = [NSMutableDictionary dictionary];
      segmentDict[@"start"] = [SVKParserHelper requestStringForAnnotation:segment.start];
      
      TKSegment *finalSegment = [segment finalSegmentIncludingContinuation];
      segmentDict[@"end"]   = [SVKParserHelper requestStringForAnnotation:finalSegment.end];
      
      segmentDict[@"modes"] = @[segment.modeIdentifier];
      if (segment.reference.vehicleUUID) {
        segmentDict[@"vehicleUUID"] = segment.reference.vehicleUUID;
      }
      [arrayParas addObject:segmentDict];
    }
  }
  paras[@"segments"] = arrayParas;
  return paras;
}

@end
