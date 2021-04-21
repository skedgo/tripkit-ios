//
//  TKRoutingParser.m
//  TripKit
//
//  Created by Adrian Schoenig on 7/04/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "TKRoutingParser.h"

@import CoreData;

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
                allowDuplicatingExistingTrip:YES
                                  visibility:TKTripGroupVisibilityFull];
    if (added.count == 0) {
      return;
    }
    
    BOOL success = [TKRoutingParser populate:request start:nil end:nil leaveAfter:nil arriveBy:nil queryJSON:json[@"query"]];
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
    TripRequest *request = [TripRequest insertEmptyIntoContext:self.context];
    
    NSArray *added = [self parseAndAddResult:json
                                  forRequest:request
                                 orTripGroup:nil
                                orUpdateTrip:nil
                allowDuplicatingExistingTrip:YES
                                  visibility:TKTripGroupVisibilityFull];
    if (added.count == 0) {
      [self.context deleteObject:request];
      [TKLog warn:@"TKRoutingParser" text:[NSString stringWithFormat:@"Error parsing request: %@", json]];
      completion(nil);
      return;
    }
    
    BOOL success = [TKRoutingParser populate:request start:nil end:nil leaveAfter:nil arriveBy:nil queryJSON:json[@"query"]];
    if (! success) {
      [self.context deleteObject:request];
      [TKLog info:@"TKRoutingParser" text:[NSString stringWithFormat:@"Got trip without a segment from JSON: %@", json]];
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
                 allowDuplicatingExistingTrip:!mergeWithExistingTrips
                                   visibility:TKTripGroupVisibilityFull];
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
                 allowDuplicatingExistingTrip:!mergeWithExistingTrips
                                   visibility:TKTripGroupVisibilityFull];
    completion(result);
  }];
}

- (NSArray<Trip *>*)parseAndAddResult:(NSDictionary *)json
                           forRequest:(TripRequest *)request
                              merging:(BOOL)mergeWithExistingTrips
                           visibility:(TKTripGroupVisibility)visibility
{
  return [self parseAndAddResult:json
                      forRequest:request
                     orTripGroup:nil
                    orUpdateTrip:nil
    allowDuplicatingExistingTrip:!mergeWithExistingTrips
                      visibility:visibility];
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
                                    allowDuplicatingExistingTrip:YES
                                                      visibility:TKTripGroupVisibilityFull];
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
allowDuplicatingExistingTrip:YES // we don't actually create a duplicate
                 visibility:TKTripGroupVisibilityFull];
    completion(trip);
  }];
}


#pragma mark - Private helpers


- (NSArray *)parseAndAddResult:(NSDictionary *)json
                    forRequest:(nullable TripRequest *)request
                   orTripGroup:(nullable TripGroup *)insertIntoGroup
                  orUpdateTrip:(nullable Trip *)tripToUpdate
  allowDuplicatingExistingTrip:(BOOL)allowDuplicates
                    visibility:(TKTripGroupVisibility)visibility

{
  NSString *error = json[@"error"];
  if (error) {
    [TKLog warn:@"TKRoutingParser" text:[NSString stringWithFormat:@"Error while parsing: %@", error]];
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
                  allowDuplicatingExistingTrip:allowDuplicates
                                    visibility:visibility];
}

- (NSArray *)parseAndAddResultWithTripGroups:(NSArray *)tripGroupsArray
                            segmentTemplates:(NSArray *)segmentTemplatesArray
                                      alerts:(NSArray *)alertsArray
                                  forRequest:(nullable TripRequest *)request
                                 orTripGroup:(nullable TripGroup *)insertIntoGroup
                                orUpdateTrip:(nullable Trip *)tripToUpdate
                allowDuplicatingExistingTrip:(BOOL)allowDuplicates
                                  visibility:(TKTripGroupVisibility)visibility
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
  
  TKTripGroupVisibility updateTripVisibility = tripToUpdate.tripGroup.visibility;
  
  // At first, we need to parse the segment templates, since the trips will reference them
  NSMutableDictionary *segmentHashToTemplateDictionaryDict = [NSMutableDictionary dictionaryWithCapacity:segmentTemplatesArray.count];
  NSMutableSet *addedTemplateHashCodes = [NSMutableSet setWithCapacity:segmentTemplatesArray.count];
  for (NSDictionary *segmentTemplateDict in segmentTemplatesArray) {
    NSNumber *hashCode = segmentTemplateDict[@"hashCode"];
    [segmentHashToTemplateDictionaryDict setValue:segmentTemplateDict forKey:[hashCode description]];

    BOOL hashCodeExists = [SegmentTemplate segmentTemplateHashCode:hashCode.integerValue
                                            existsInTripKitContext:self.context];
    if (hashCodeExists) {
      [addedTemplateHashCodes addObject:hashCode];
    }
  }
  
  // Next we parse the alerts
  [TKAPIToCoreDataConverter updateOrAddAlerts:alertsArray
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
      trip.arrivalTime   = [TKParserHelper parseDate:tripDict[@"arrive"]];;
      trip.departureTime = [TKParserHelper parseDate:tripDict[@"depart"]];;
      
      // update values if we received them, otherwise keep old
      trip.mainSegmentHashCode  = [tripDict[@"mainSegmentHashCode"] intValue];
      trip.totalCalories        = [tripDict[@"caloriesCost"] floatValue];
      trip.totalCarbon          = [tripDict[@"carbonCost"] floatValue];
      trip.totalHassle          = [tripDict[@"hassleCost"] floatValue];
      trip.totalScore           = [tripDict[@"weightedScore"] floatValue];
      trip.totalPrice           = tripDict[@"moneyCost"]            ?: trip.totalPrice;
      trip.totalPriceUSD        = tripDict[@"moneyUSDCost"]         ?: trip.totalPriceUSD;
      trip.currencyCode         = tripDict[@"currency"]             ?: trip.currencyCode;
      trip.budgetPoints         = tripDict[@"budgetPoints"]         ?: trip.budgetPoints;
      trip.saveURLString        = tripDict[@"saveURL"]              ?: trip.saveURLString;
      trip.shareURLString       = tripDict[@"shareURL"]             ?: trip.shareURLString;
      trip.temporaryURLString   = tripDict[@"temporaryURL"]         ?: trip.temporaryURLString;
      trip.updateURLString      = tripDict[@"updateURL"]            ?: trip.updateURLString;
      trip.progressURLString    = tripDict[@"progressURL"]          ?: trip.progressURLString;
      trip.plannedURLString     = tripDict[@"plannedURL"]           ?: trip.plannedURLString;
      trip.logURLString         = tripDict[@"logURL"]               ?: trip.logURLString;

      if ([tripDict[@"availability"] isKindOfClass:[NSString class]]) {
        trip.missedBookingWindow = [@"MISSED_PREBOOKING_WINDOW" isEqualToString:tripDict[@"availability"]];
        trip.isCanceled = [@"CANCELLED" isEqualToString:tripDict[@"availability"]];
      }
      
      if ([tripDict[@"bundleId"] isKindOfClass:[NSString class]]) {
        trip.bundleId = tripDict[@"bundleId"];
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
        ZAssert(hashCode != nil, @"No hash code in %@", refDict);
        NSDictionary *templateDict = segmentHashToTemplateDictionaryDict[[hashCode description]];
        ZAssert(templateDict != nil, @"Missing template for %@", hashCode);
        BOOL isNewTemplate = ![addedTemplateHashCodes containsObject:hashCode];
        
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
            && (isNewTemplate || YES == [SegmentTemplate segmentTemplateHashCode:hashCode.integerValue existsInTripKitContext:self.context])) {
          reference = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SegmentReference class]) inManagedObjectContext:self.context];
        }
        
        if (! reference) {
          continue;
        }
        
        [reference _populateFromDictionary:refDict];
        
        Service *service = nil;
        NSString *serviceCode = refDict[@"serviceTripID"];
        if (serviceCode) {
          // public-transport
          
          // create a service object if necessary
          service = [Service fetchOrInsertServiceWithCode:serviceCode
                                         inTripKitContext:self.context];
          
          // always update these as those might be new or updated, as long as they didn't get deleted
          TKColor *newColor = [TKParserHelper colorForDictionary:refDict[@"serviceColor"]];
          service.color     = newColor                      ?: service.color;
          service.frequency = refDict[@"frequency"]         ?: service.frequency;
          service.lineName  = refDict[@"serviceName"]       ?: service.lineName;
          service.direction = refDict[@"serviceDirection"]  ?: service.direction;
          service.number		= refDict[@"serviceNumber"]     ?: service.number;
          reference.service = service;
          
          reference.bicycleAccessible = [refDict[@"bicycleAccessible"] boolValue];

          [reference _setWheelchairAccessibility:refDict[@"wheelchairAccessible"]];
          
          // set the trip status
          if (service.frequency.integerValue == 0) {
            trip.departureTimeIsFixed = YES;
          }
          
          // update the real-time status
          NSString *realTimeStatus = refDict[@"realTimeStatus"];
          [TKCoreDataParserHelper adjustService:service forRealTimeStatusString:realTimeStatus];
          
          // keep the vehicles
          [TKAPIToCoreDataConverter updateVehiclesForService:service
                                              primaryVehicle:refDict[@"realtimeVehicle"]
                                         alternativeVehicles:refDict[@"realtimeVehicleAlternatives"]];
          
        } else {
          // private transport
          [TKCoreDataParserHelper updateVehiclesForSegmentReference:reference
                                             primaryVehicle:refDict[@"realtimeVehicle"]
                                        alternativeVehicles:nil];
        }

        reference.templateHashCode = hashCode;
        reference.startTime = [TKParserHelper parseDate:refDict[@"startTime"]];;
        reference.endTime = [TKParserHelper parseDate:refDict[@"endTime"]];;
        reference.timesAreRealTime = [refDict[@"realTime"] boolValue];

        reference.alertHashCodes = refDict[@"alertHashCodes"];
        
        
        ZAssert(templateDict, @"No segment template found for code %@", hashCode);
        if (isNewTemplate) {
          [SegmentTemplate insertNewTemplateFromDictionary:templateDict forService:service relativeTime:reference.startTime intoContext:self.context];
          [addedTemplateHashCodes addObject:hashCode];
        } else if (service) {
          // We don't need to insert the full template, but need to add
          // shapes for that service
          
          TKModeInfo *modeInfo = [service modeInfo]; // *not* using `findModeInfo`
            // as we might have just created this, and it'll get populated from
            // templateDict
          
          [SegmentTemplate insertNewShapesFromDictionary:templateDict forService:service relativeTime:reference.startTime modeInfo:modeInfo intoContext:self.context];
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
          [self.context deleteObject:trip];
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
        
        tripGroup.visibility = visibility;
        
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

@end
