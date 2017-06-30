//
//  TKRoutingParser.m
//  TripGo
//
//  Created by Adrian Schoenig on 7/04/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "TKRoutingParser.h"

#import <TripKit/TKTripKit.h>
#import <TripKit/TripKit-Swift.h>

@interface TKRoutingParser ()

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation TKRoutingParser

- (id)initWithTripKitContext:(NSManagedObjectContext *)context
{
  self = [super init];
  if (self) {
    _context = context;
  }
  return self;
}

#pragma mark - Results

- (SegmentTemplate *)insertNewSegmentTemplate:(NSDictionary *)dict
                                   forService:(Service *)service
{
  // Get the visibility and keep only those templates which are visible
  STKTripSegmentVisibility visibility = [TKParserHelper segmentVisibilityType:dict[@"visibility"]];
  if (visibility == STKTripSegmentVisibilityHidden) {
    return nil;
  }
  
  SegmentTemplate *template = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SegmentTemplate class]) inManagedObjectContext:self.context];
  template.action           = dict[@"action"];
  template.visibility       = @(visibility);
  template.segmentType      = [TKParserHelper segmentTypeForString:dict[@"type"]];
  template.hashCode         = dict[@"hashCode"];
  template.bearing          = dict[@"travelDirection"];
  template.modeIdentifier   = dict[@"modeIdentifier"];
  template.modeInfo         = [ModeInfo modeInfoForDictionary:dict[@"modeInfo"]];
  template.miniInstruction  = [STKMiniInstruction miniInstructionForDictionary:dict[@"mini"]];
  template.notesRaw         = dict[@"notes"];
  template.smsMessage       = dict[@"smsMessage"];
  template.smsNumber        = dict[@"smsNumber"];
  template.durationWithoutTraffic = dict[@"durationWithoutTraffic"];
  template.metres           = dict[@"metres"];
  template.metresFriendly   = dict[@"metresSafe"];
  
  if (template.segmentType.integerValue == TKSegmentTypeScheduled) {
    template.scheduledStartStopCode = dict[@"stopCode"];
    template.scheduledEndStopCode   = dict[@"endStopCode"];
    service.operatorName            = dict[@"serviceOperator"];
  }
  
  // additional info
  template.continuation   = [dict[@"isContinuation"] boolValue];
  template.hasCarParks    = [dict[@"hasCarParks"] boolValue];
  
  // set start, intermediary waypoints and end
  
  if (YES == [template isStationary]) {
    // stationary segments just have a single location
    template.startLocation = [SVKParserHelper namedCoordinateForDictionary:dict[@"location"]];
    template.endLocation   = template.startLocation;
    
  } else {
    
    SGKNamedCoordinate *start = nil;
    SGKNamedCoordinate *end = nil;
    
    // all the waypoints
    // they should ways be in a 'shapes' array now, but also support the old 'streets' and 'line'
    NSArray *shapesArray = dict[@"shapes"];
    if (nil == shapesArray)
      shapesArray = dict[@"streets"];
    if (nil == shapesArray)
      shapesArray = dict[@"line"];
    
    NSArray *shapes = [TKParserHelper insertNewShapes:shapesArray
                                           forService:service
                                         withModeInfo:template.modeInfo
                                     orTripKitContext:self.context];
    for (Shape *shape in shapes) {
      shape.template = template;
      if (YES == shape.travelled.boolValue) {
        if (start == nil) // only if no previous travelled segment!
          start = [[SGKNamedCoordinate alloc] initWithCoordinate:shape.start.coordinate];
        // end ALSO if there's a previous travelled segment
        end   = [[SGKNamedCoordinate alloc] initWithCoordinate:shape.end.coordinate];
      }
    }
    
    // set the start and end
    if (! start) {
      start = [SVKParserHelper namedCoordinateForDictionary:dict[@"from"]];
    }
    if (! end) {
      end   = [SVKParserHelper namedCoordinateForDictionary:dict[@"to"]];
    }
    
    ZAssert(nil != start, @"Got no start waypoint!");
    start.address = dict[@"from"][@"address"];
    template.startLocation = start;
    
    ZAssert(nil != start, @"Got no end waypoint!");
    end.address = dict[@"to"][@"address"];
    template.endLocation = end;
  }
  
  return template;
}

#pragma mark - Public method

- (TripRequest *)parseAndAddResultBlocking:(NSDictionary *)json
{
  __block TripRequest *result = nil;
  
  [self.context performBlockAndWait:^{
    // create an empty request
    TripRequest *request = [TripRequest insertEmptyIntoContext:self.context];
    
    // parse everything
    NSArray *added = [self parseAndAddResult:json
                                  forRequest:request
                                 orTripGroup:nil
                                orUpdateTrip:nil
                allowDuplicatingExistingTrip:YES];
    if (added.count == 0) {
      return;
    }
    
    BOOL success = [TKRoutingParser populate:request start:nil end:nil leaveAfter:nil arriveBy:nil];
    if (! success) {
      return;
    }
    result = request;
  }];
  return result;
}

- (void)parseAndAddResult:(NSDictionary *)json
               completion:(void (^)(TripRequest * _Nullable request))completion
{
  [self.context performBlock:^{
    // create an empty request
    TripRequest *request = [TripRequest insertEmptyIntoContext:self.context];
    
    // parse everything
    NSArray *added = [self parseAndAddResult:json
                                  forRequest:request
                                 orTripGroup:nil
                                orUpdateTrip:nil
                allowDuplicatingExistingTrip:YES];
    if (added.count == 0) {
      [request remove];
      DLog(@"Error parsing request: %@", json);
      completion(nil);
      return;
    }
    
    BOOL success = [TKRoutingParser populate:request start:nil end:nil leaveAfter:nil arriveBy:nil];
    if (! success) {
      [request remove];
      DLog(@"Got trip without a segment from JSON: %@", json);
      completion(nil);
      return;
    }
    completion(request);
  }];
}

- (void)parseAndAddResult:(NSDictionary *)json
            intoTripGroup:(TripGroup *)tripGroup
                  merging:(BOOL)mergeWithExistingTrips
               completion:(void (^)(NSArray<Trip *> *addedTrips))completion
{
  [self.context performBlock:^{
    TripGroup *group = (TripGroup *)[self.context objectWithID:tripGroup.objectID];
    
    NSArray *result = [self parseAndAddResult:json
                                   forRequest:nil
                                  orTripGroup:group
                                 orUpdateTrip:nil
                 allowDuplicatingExistingTrip:!mergeWithExistingTrips];
    completion(result);
  }];
}

- (void)parseAndAddResult:(NSDictionary *)json
               forRequest:(TripRequest *)request
                  merging:(BOOL)mergeWithExistingTrips
               completion:(void (^)(NSArray<Trip *> *addedTrips))completion
{
  [self.context performBlock:^{
    NSArray *result = [self parseAndAddResult:json
                                   forRequest:request
                                  orTripGroup:nil
                                 orUpdateTrip:nil
                 allowDuplicatingExistingTrip:!mergeWithExistingTrips];
    completion(result);
  }];
}

- (void)parseAndAddResult:(NSDictionary *)keyToTripGroups
     withSegmentTemplates:(NSArray *)segmentTemplatesJson
                andAlerts:(nullable NSArray *)alertJson
               completion:(void (^)(NSDictionary *keyToAddedTrips))completion
{
  [self.context performBlock:^{
    // create an empty request
    NSMutableDictionary *keyToTrips = [NSMutableDictionary dictionaryWithCapacity:keyToTripGroups.count];
    
    [keyToTripGroups enumerateKeysAndObjectsUsingBlock:
     ^(id<NSCopying> key, NSArray *tripGroupsArray, BOOL *stop) {
#pragma unused(stop)
       TripRequest *request = [TripRequest insertEmptyIntoContext:self.context];
       
       NSArray *newTrips = [self parseAndAddResultWithTripGroups:tripGroupsArray
                                                segmentTemplates:segmentTemplatesJson
                                                          alerts:alertJson
                                                      forRequest:request
                                                     orTripGroup:nil
                                                    orUpdateTrip:nil
                                    allowDuplicatingExistingTrip:YES];
       if (newTrips.count > 0) {
         keyToTrips[key] = newTrips;
       }
     }];
    completion(keyToTrips);
  }];
}

- (void)parseJSON:(NSDictionary *)json
     updatingTrip:(Trip *)trip
       completion:(void (^)(Trip *updatedTrip))completion
{
  [self.context performBlock:^{
    [self parseAndAddResult:json
                 forRequest:nil
                orTripGroup:nil
               orUpdateTrip:trip
allowDuplicatingExistingTrip:YES]; // we don't actually create a duplicate
    completion(trip);
  }];
}


#pragma mark - Private helpers


- (NSArray *)parseAndAddResult:(NSDictionary *)json
                    forRequest:(nullable TripRequest *)request
                   orTripGroup:(nullable TripGroup *)insertIntoGroup
                  orUpdateTrip:(nullable Trip *)tripToUpdate
  allowDuplicatingExistingTrip:(BOOL)allowDuplicates

{
  // check if this is an error
  NSString *error = json[@"error"];
  if (error) {
    DLog(@"Error while parsing: %@", error);
    return @[];
  }
  
  NSArray *segmentTemplatesArray = json[@"segmentTemplates"];
  NSArray *alertsArray = json[@"alerts"];
  NSArray *tripGroupsArray = json[@"groups"];
  return [self parseAndAddResultWithTripGroups:tripGroupsArray
                              segmentTemplates:segmentTemplatesArray
                                        alerts:alertsArray
                                    forRequest:request
                                   orTripGroup:insertIntoGroup
                                  orUpdateTrip:tripToUpdate
                  allowDuplicatingExistingTrip:allowDuplicates];
}

- (NSArray *)parseAndAddResultWithTripGroups:(NSArray *)tripGroupsArray
                            segmentTemplates:(NSArray *)segmentTemplatesArray
                                      alerts:(NSArray *)alertsArray
                                  forRequest:(nullable TripRequest *)request
                                 orTripGroup:(nullable TripGroup *)insertIntoGroup
                                orUpdateTrip:(nullable Trip *)tripToUpdate
                allowDuplicatingExistingTrip:(BOOL)allowDuplicates
{
  ZAssert(self.context, @"Managed object context required!");
    
  // let's check if the request is still alive
  if (! request) {
    request = insertIntoGroup.request;
  }
  if (! request) {
    request = tripToUpdate.request;
  }
  if (! request.managedObjectContext || [request isDeleted]) {
    return @[];
  }
  
  TripGroupVisibility updateTripVisibility = tripToUpdate.tripGroup.visibility;
  
  // At first, we need to parse the segment templates, since the trips will reference them
  NSMutableDictionary *segmentHashToTemplateDictionaryDict = [NSMutableDictionary dictionaryWithCapacity:segmentTemplatesArray.count];
  for (NSDictionary *segmentTemplateDict in segmentTemplatesArray) {
    // check if we already have a segment template with that id
    NSNumber *hashCode = segmentTemplateDict[@"hashCode"];
    BOOL hashCodeExists = [SegmentTemplate segmentTemplateHashCode:hashCode
                                            existsInTripKitContext:self.context];
    if (NO == hashCodeExists) {
      // keep it
      [segmentHashToTemplateDictionaryDict setValue:segmentTemplateDict forKey:[hashCode description]];
    }
  }
  
  // Next we parse the alerts
  [TKParserHelper updateOrAddAlerts:alertsArray
                   inTripKitContext:self.context];
  
  // Now parse the groups
  NSSet *previousTrips = [request trips];
  NSMutableArray *tripsToReturn = [NSMutableArray array];
  for (NSDictionary * tripGroupDict in tripGroupsArray) {
    NSMutableSet *newTrips = [NSMutableSet set];
    
    // iterate over routes
    for (NSDictionary * tripDict in tripGroupDict[@"trips"]) {
      
      // ignore "nothing" results
      if ([tripDict[@"accuracy"] isEqualToString:@"nothing"])
        continue;
      
      // create route item
      Trip *trip;
      if (tripToUpdate) {
        trip = tripToUpdate;
      } else {
        trip = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Trip class]) inManagedObjectContext:self.context];
      }
      trip.arrivalTime   = [NSDate dateWithTimeIntervalSince1970:[tripDict[@"arrive"] doubleValue]];
      trip.departureTime = [NSDate dateWithTimeIntervalSince1970:[tripDict[@"depart"] doubleValue]];
      
      // update values if we received them, otherwise keep old
      trip.totalCalories        = tripDict[@"caloriesCost"]         ?: trip.totalCalories;
      trip.totalCarbon          = tripDict[@"carbonCost"]           ?: trip.totalCarbon;
      trip.totalPrice           = tripDict[@"moneyCost"]            ?: trip.totalPrice;
      trip.totalPriceUSD        = tripDict[@"moneyUSDCost"]         ?: trip.totalPriceUSD;
      trip.currencySymbol       = tripDict[@"currencySymbol"]       ?: trip.currencySymbol;
      trip.totalHassle          = tripDict[@"hassleCost"]           ?: trip.totalHassle;
      trip.totalScore           = tripDict[@"weightedScore"]        ?: trip.totalScore;
      trip.mainSegmentHashCode  = tripDict[@"mainSegmentHashCode"]  ?: trip.mainSegmentHashCode;
      trip.saveURLString        = tripDict[@"saveURL"]              ?: trip.saveURLString;
      trip.shareURLString       = tripDict[@"shareURL"]             ?: trip.shareURLString;
      trip.temporaryURLString   = tripDict[@"temporaryURL"]         ?: trip.temporaryURLString;
      trip.updateURLString      = tripDict[@"updateURL"]            ?: trip.updateURLString;
      trip.progressURLString    = tripDict[@"progressURL"]          ?: trip.progressURLString;
      trip.plannedURLString     = tripDict[@"plannedURL"]           ?: trip.plannedURLString;
      
      if ([tripDict[@"availability"] isKindOfClass:[NSString class]]) {
        trip.missedBookingWindow  = [@"MISSED_PREBOOKING_WINDOW" isEqualToString:tripDict[@"availability"]];
      }
      
      [trip calculateDuration];
      
      // updated trip isn't strictly speaking new, but we want to process it as a successful match.
      [newTrips addObject:trip];
      
      NSMutableSet *unmatchedSegmentReferences = nil;
      if (tripToUpdate) {
        unmatchedSegmentReferences = [tripToUpdate.segmentReferences mutableCopy];
      }
      
      int segmentCount = 0;
      for (NSDictionary *refDict in tripDict[@"segments"]) {
        // create the reference object
        SegmentReference *reference = nil;
        NSNumber *hashCode = refDict[@"segmentTemplateHashCode"];
        NSDictionary *unprocessedTemplateDict = segmentHashToTemplateDictionaryDict[[hashCode description]];
        
        if (tripToUpdate) {
          for (SegmentReference *existingReference in unmatchedSegmentReferences) {
            if ([existingReference.templateHashCode isEqualToNumber:hashCode]) {
              reference = existingReference;
              break;
            }
          }
          if (reference) {
            [unmatchedSegmentReferences removeObject:reference];
          } else {
            [trip clearSegmentCaches];
          }
        }
        
        if (!reference
            && (unprocessedTemplateDict
                   || YES == [SegmentTemplate segmentTemplateHashCode:hashCode existsInTripKitContext:self.context])) {
          reference = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SegmentReference class]) inManagedObjectContext:self.context];
        }
        
        if (! reference) {
          continue;
        }
        
        Service *service = nil;
        NSString *serviceCode = refDict[@"serviceTripID"];
        if (serviceCode) {
          // public-transport
          
          // create a service object if necessary
          service = [Service fetchExistingServiceWithCode:serviceCode
                                         inTripKitContext:self.context];
          if (nil == service) {
            service = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Service class]) inManagedObjectContext:self.context];;
            service.code = serviceCode;
          }
          
          // always update these as those might be new or updated, as long as they didn't get deleted
          SGKColor *newColor = [SVKParserHelper colorForDictionary:refDict[@"serviceColor"]];
          service.color     = newColor                      ?: service.color;
          service.frequency = refDict[@"frequency"]         ?: service.frequency;
          service.lineName  = refDict[@"serviceName"]       ?: service.lineName;
          service.direction = refDict[@"serviceDirection"]  ?: service.direction;
          service.number		= refDict[@"serviceNumber"]     ?: service.number;
          reference.service = service;
          
          reference.ticketWebsiteURLString = refDict[@"ticketWebsiteURL"];
          reference.serviceStops = refDict[@"stops"];
          reference.departurePlatform = refDict[@"platform"];
          reference.bicycleAccessible = [refDict[@"bicycleAccessible"] boolValue];
          reference.wheelchairAccessible = [refDict[@"wheelchairAccessible"] boolValue];
          
          // set the trip status
          if (service.frequency.integerValue == 0) {
            trip.departureTimeIsFixed = YES;
          }
          
          // update the real-time status
          NSString *realTimeStatus = refDict[@"realTimeStatus"];
          [TKParserHelper adjustService:service forRealTimeStatusString:realTimeStatus];
          
          // keep the vehicles
          [TKParserHelper updateVehiclesForService:service
                                    primaryVehicle:refDict[@"realtimeVehicle"]
                               alternativeVehicles:refDict[@"realtimeVehicleAlternatives"]];
          
        } else {
          // private transport
          [reference setSharedVehicleData:refDict[@"sharedVehicle"]];
          [reference setVehicleUUID:refDict[@"vehicleUUID"]];
          [TKParserHelper updateVehiclesForSegmentReference:reference
                                             primaryVehicle:refDict[@"realtimeVehicle"]
                                        alternativeVehicles:nil];
        }

        NSDictionary *bookingData = [self mergedNewBookingData:refDict[@"booking"] into:reference.bookingData];
        [reference setBookingData:bookingData];

        reference.templateHashCode = hashCode;
        reference.startTime = [NSDate dateWithTimeIntervalSince1970:[refDict[@"startTime"] integerValue]];
        reference.endTime = [NSDate dateWithTimeIntervalSince1970:[refDict[@"endTime"] integerValue]];
        reference.timesAreRealTime = [refDict[@"realTime"] boolValue];

        reference.alertHashCodes = refDict[@"alertHashCodes"];
        
        // Any segment can have payloads
        NSDictionary *payloads = refDict[@"payloads"];
        if (payloads) {
          [payloads enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
#pragma unused(stop)
            [reference setPayload:obj forKey:key];
          }];
        }
        
        // now we can add the template, too
        if (unprocessedTemplateDict) {
          [self insertNewSegmentTemplate:unprocessedTemplateDict
                              forService:service];
          [segmentHashToTemplateDictionaryDict removeObjectForKey:[hashCode description]];
        }
        
        reference.index = @(segmentCount++);
        reference.trip = trip;
      }
      
      // Clean-up unmatched references
      if (unmatchedSegmentReferences.count > 0) {
        for (SegmentReference *unmatched in unmatchedSegmentReferences) {
          [self.context deleteObject:unmatched];
        }
      }
      ZAssert(trip.segmentReferences.count > 0, @"Trip has no segments: %@", trip);
    }
    
    if (newTrips.count > 0) {
      TripGroup *tripGroup = nil;
      NSMutableArray *addedTrips = [NSMutableArray arrayWithCapacity:newTrips.count];
      
      // Check if we already have a similar route. If so, we'll add ALL routes of this group to the group of an existing route.
      for (Trip *trip in newTrips) {
        // let's check if the request is still alive
        if (nil == request.managedObjectContext || [request isDeleted]) {
          return nil;
        }
        
        Trip *existingNearlyIdenticalTrip = nil;
        if (!allowDuplicates) {
          existingNearlyIdenticalTrip = [Trip findSimilarTripTo:trip inList:previousTrips];
        }
        
        if (! existingNearlyIdenticalTrip) {
          [addedTrips addObject:trip];
          [tripsToReturn addObject:trip];
        } else if (existingNearlyIdenticalTrip.tripGroup) {
          // remember route group, but don't add this
          tripGroup = existingNearlyIdenticalTrip.tripGroup;
          [tripsToReturn addObject:existingNearlyIdenticalTrip];
          
          // delete this
          [trip remove];
        }
      }
      
      if (insertIntoGroup) {
        tripGroup = insertIntoGroup;
      } else if (tripToUpdate) {
        tripGroup = tripToUpdate.tripGroup;
      }
      
      if (addedTrips.count > 0) {
        if (nil == tripGroup) {
          // create a new route group
          tripGroup = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([TripGroup class]) inManagedObjectContext:self.context];
          tripGroup.request = request;
        }
        
        // always update the visiblity
        tripGroup.visibility = request.defaultVisibility;
        
        // always update frequency + sources (if there are any)
        tripGroup.frequency = tripGroupDict[@"frequency"] ?: tripGroup.frequency;
        tripGroup.sourcesRaw = tripGroupDict[@"sources"] ?: tripGroup.sourcesRaw;
        
        for (Trip *trip in newTrips) {
          if (trip.managedObjectContext != nil) {
            trip.tripGroup = tripGroup;
          }
        }
        if (!tripToUpdate) {
          [tripGroup adjustVisibleTrip];
        }
      }
    }
  }
  
  // restore visibility
  if (tripToUpdate) {
    tripToUpdate.tripGroup.visibility = updateTripVisibility;
  }
  return tripsToReturn;
}

- (nullable NSDictionary *)mergedNewBookingData:(nullable NSDictionary *)newData into:(nullable NSDictionary *)oldData
{
  if (!newData) {
    return oldData;
  }
  if (!oldData) {
    return newData;
  }
  
  NSMutableDictionary *merged = [oldData mutableCopy];
  [newData enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
#pragma unused(stop)
    [merged setObject:obj forKey:key];
  }];
  return merged;
}

@end
