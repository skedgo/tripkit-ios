//
//  SGSkedgoifier.m
//  TripKit
//
//  Created by Adrian Schoenig on 31/07/13.
//
//

#import "TKSkedgoifier.h"

#ifdef TK_NO_MODULE
#import <TripKit/TripKit-Swift.h>
#else
@import TripKit;
#import <TripKitAddOns/TripKitAddOns-Swift.h>
#endif

#define kTKSkedgoifierErrorTypeUser 30051
#define kSGPriorityCurrentLocation	9
#define kSGPriorityEvents           5
#define kSGPriorityHabitual         2
#define kSGPriorityStay             1
#define kSGPriorityHome             0

@interface TKTripPlaceholder : NSObject

@property (nonatomic, strong) NSNumber *key;

- (instancetype)initWithKey:(NSNumber *)key;

@end

@interface TKSkedgoifier ()

@property (nonatomic, strong) NSDictionary *keyToItems;
@property (nonatomic, strong) id lastInputJSON;

@end

@implementation TKSkedgoifier

+ (nullable NSDictionary *)skedgoifyJSONObjectForDate:(NSDate *)date
{
  NSURL *url = [[self class] skedgoifyPathForDate:date];
  return [NSDictionary dictionaryWithContentsOfURL:url];
}

- (void)fetchTripsForItems:(NSArray *)items
                 startDate:(NSDate *)startDate
                   endDate:(NSDate *)endDate
                  inRegion:(SVKRegion *)region
       withPrivateVehicles:(nullable NSArray <id<STKVehicular>> *)privateVehicles
          withTripPatterns:(nullable NSArray *)tripPatterns
                completion:(nullable void(^)(NSArray * __nullable outputItems, NSError * __nullable error))completion
{
  // send query to server
  NSDictionary *paras = [self queryParametersForItems:items
                                            startDate:startDate
                                              endDate:endDate
                                           withRegion:region
                                  withPrivateVehicles:privateVehicles
                                     withTripPatterns:tripPatterns];
  if (!paras || paras.count <= 1) {
    if (completion) {
      // trivial agenda, no update necessary
      completion(nil, nil);
    }
    return;
  }
  self.lastInputJSON = paras;
  NSDate *halfWay = [startDate dateByAddingTimeInterval:[endDate timeIntervalSinceDate:startDate] / 2];
  NSURL *url = [[self class] skedgoifyPathForDate:halfWay];
  if (url) {
    [paras writeToURL:url atomically:NO];
  }
  
  SVKServer *server = [SVKServer sharedInstance];
  [server hitSkedGoWithMethod:@"POST"
                         path:@"skedgoify.json"
                   parameters:paras
                       region:region
                      success:
   ^(NSInteger status, id responseObject) {
#pragma unused(status)
     [self processServerResultFromJSON:responseObject
                            completion:completion];

   }
                      failure:
   ^(NSError *requestError) {
     [SGKLog warn:NSStringFromClass([self class]) format:@"Skedgoify request failed with error: %@", requestError];
     if (completion) {
       completion(nil, requestError);
     }
   }];
}

#pragma mark - Helper: keeping skedgoify.json inputs

+ (NSURL *)skedgoifyPathForDate:(NSDate *)date
{
  NSURL *directory = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory
                                                             inDomains:NSUserDomainMask] lastObject];
  NSString *fileName;
  if ([SGKBetaHelper isBeta]) {
    fileName = [NSString stringWithFormat:@"skedgoify-%@.json", [self YMDStringForDate:date]];
  } else {
    fileName = @"skedgoify.json";
  }
  return [directory URLByAppendingPathComponent:fileName];
}

+ (NSString *)YMDStringForDate:(NSDate *)date
{
  struct tm *timeinfo;
  char buffer[80];
  
  time_t rawtime = (time_t)[date timeIntervalSince1970];
  timeinfo = gmtime(&rawtime);
  strftime(buffer, 80, "%Y-%m-%d", timeinfo);
  return [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
}

#pragma mark - Helper: building skegdoify.json

- (NSDictionary *)queryParametersForItems:(NSArray *)items
                                startDate:(NSDate *)startDate
                                  endDate:(NSDate *)endDate
                               withRegion:(SVKRegion *)region
                      withPrivateVehicles:(nullable NSArray <id<STKVehicular>> *)privateVehicles
                         withTripPatterns:(nullable NSArray *)tripPatterns
{
  NSMutableDictionary *keysToItems = [NSMutableDictionary dictionary];
  NSDictionary *paras =  [[self class] queryParametersForItems:items
                                                     startDate:startDate
                                                       endDate:endDate
                                                      inRegion:region
                                           withPrivateVehicles:privateVehicles
                                              withTripPatterns:tripPatterns
                                              fillInKeysToItems:keysToItems];
  self.keyToItems = keysToItems;
  return paras;
}

+ (BOOL)coordinate:(CLLocationCoordinate2D)coordinate isCloseTo:(CLLocationCoordinate2D)other
{
  CLLocation *loc1 = [[CLLocation alloc] initWithLatitude:coordinate.latitude
                                                longitude:coordinate.longitude];
  CLLocation *loc2 = [[CLLocation alloc] initWithLatitude:other.latitude
                                                longitude:other.longitude];
  return [loc1 distanceFromLocation:loc2] < 250;
}

+ (NSDictionary *)queryParametersForItems:(NSArray *)items
                                startDate:(NSDate *)startDate
                                  endDate:(NSDate *)endDate
                                 inRegion:(SVKRegion *)region
                      withPrivateVehicles:(nullable NSArray <id<STKVehicular>> *)privateVehicles
                         withTripPatterns:(nullable NSArray *)tripPatterns
                        fillInKeysToItems:(NSMutableDictionary *)keysToItems
{
  // this will access the agenda which refers managed object's. we need to make
  // sure we access those on the right thread, hence the wrapper.
  
  NSArray *itemsPayload = [self payloadForItems:items
                                      startDate:startDate
                                        endDate:endDate
                            withPrivateVehicles:privateVehicles
                              fillInKeysToItems:keysToItems];
  if (! itemsPayload || itemsPayload.count <= 1) {
    // we even send useless requests, e.g., if you only have home and events without an address.
    return @{};
  }
  
  NSDictionary *framePayload = @{
                                 @"startTime"	: @(floor([startDate timeIntervalSince1970])),
                                 @"endTime"		: @(ceil([endDate timeIntervalSince1970])),
#ifdef DEBUG
                                 @"startText"	: [startDate descriptionWithLocale:[NSLocale currentLocale]],
                                 @"endText"		: [endDate descriptionWithLocale:[NSLocale currentLocale]],
#endif
                                 };
  
  NSArray *regionModes = [region modeIdentifiers];
  NSArray *modes = [TKUserProfileHelper orderedEnabledModeIdentifiersForAvailableModeIdentifiers:regionModes];
  
  return @{
            @"config":   [TKSettings defaultDictionary],
            @"frame":    framePayload,
            @"items":    itemsPayload,
            @"patterns": tripPatterns ?: @[],
            @"modes":    modes,
            @"vehicles": privateVehicles ? [TKAgendaParserHelper vehiclesPayloadForVehicles:privateVehicles] : @[],
          };
}

+ (NSArray *)payloadForItems:(NSArray *)items
                   startDate:(NSDate *)agendaStartDate
                     endDate:(NSDate *)agendaEndDate
         withPrivateVehicles:(NSArray <id<STKVehicular>> *)privateVehicles
           fillInKeysToItems:(NSMutableDictionary *)keysToItems
{
  if (items.count == 0) {
    return nil;
  }
  
  // item ids => local identifiers which every object has (memory address as string)
  // keys => identifiers to be sent to server which only some might have (integer, event's ID, etc)
  
  // first we create IDs and connect up any trips
  if (! keysToItems) {
    keysToItems = [NSMutableDictionary dictionaryWithCapacity:items.count];
  }
  NSMutableDictionary *itemIDToKeyDict = [NSMutableDictionary dictionaryWithCapacity:items.count];
  
  // generate key
	[items enumerateObjectsUsingBlock:^(id inputItem, NSUInteger idx, BOOL *stop) {
#pragma unused(stop)
    NSString *itemId = [NSString stringWithFormat:@"%p", inputItem];
    NSString *key = [@(idx) stringValue];
    if ([inputItem conformsToProtocol:@protocol(TKAgendaEventInputType)]) {
      id<TKAgendaEventInputType> eventInput = (id<TKAgendaEventInputType>)inputItem;
      key = eventInput.identifier ?: key;
    }
    itemIDToKeyDict[itemId] = key;
    keysToItems[key] = inputItem;
  }];
  
  // now we can create the payload
	NSMutableArray *payload = [NSMutableArray arrayWithCapacity:items.count];
  
  __block NSDate *currentLocationTime = nil;
	[items enumerateObjectsUsingBlock:^(id inputItem, NSUInteger idx, BOOL *stop) {
#pragma unused(stop)
    
#warning FIXME: ignore those items again
//    if ([TKAgendaInputBuilder agendaInputShouldBeIgnored:inputItem]) {
//      return;
//    }
    
    NSDictionary *data = nil;
    NSString *itemId = [NSString stringWithFormat:@"%p", inputItem];
    NSString *key = itemIDToKeyDict[itemId];
    if (! key) {
      ZAssert(false, @"Each item should have a key!");
      return;
    }
    
    if ([inputItem conformsToProtocol:@protocol(TKAgendaTripInputType)]) {
      id<TKAgendaTripInputType> tripInput = (id<TKAgendaTripInputType>)inputItem;
      
      NSDate *departureTime = tripInput.departureTime;
      NSDate *arrivalTime = tripInput.arrivalTime;
      
      NSMutableDictionary *dataMutable = [NSMutableDictionary dictionary];
      dataMutable[@"class"]         = @"trip";
      dataMutable[@"id"]            = key;
      dataMutable[@"startTime"]     = @(floor([departureTime timeIntervalSince1970]));
      dataMutable[@"endTime"]       = @(ceil([arrivalTime timeIntervalSince1970]));
#ifdef DEBUG
      dataMutable[@"startText"] = [departureTime descriptionWithLocale:[NSLocale currentLocale]];
      dataMutable[@"endText"]		= [arrivalTime descriptionWithLocale:[NSLocale currentLocale]];
#endif
      dataMutable[@"startLocation"] = [STKParserHelper dictionaryForCoordinate:tripInput.origin];
      dataMutable[@"endLocation"]   = [STKParserHelper dictionaryForCoordinate:tripInput.destination];
      
      id<STKTrip> trip = tripInput.trip;
      if ([trip isKindOfClass:[Trip class]]) {
        __block NSArray<NSString *> *modes;
        __block NSArray<NSDictionary <NSString *, id> *> *vehiclesInfo;
        
        Trip *tripKitTrip = (Trip *)trip;
        
        [tripKitTrip.managedObjectContext performBlockAndWait:^{
          modes = [[tripKitTrip usedModeIdentifiers] allObjects];

          // do we use vehicles?
          NSSet *vehicleSegments = [tripKitTrip vehicleSegments];
          if (vehicleSegments.count > 0) {
            NSMutableArray *vehiclesArray = [NSMutableArray arrayWithCapacity:vehicleSegments.count];
            for (TKSegment *segment in vehicleSegments) {
              NSMutableDictionary *vehicleInfo = [NSMutableDictionary dictionary];
              vehicleInfo[@"vehicle"] = [segment usedVehicleFromAllVehicles:privateVehicles];
              if (segment.start) {
                vehicleInfo[@"pickupLocation"] = [STKParserHelper dictionaryForAnnotation:segment.start];
              }
              if (segment.end) {
                vehicleInfo[@"parkingLocation"] = [STKParserHelper dictionaryForAnnotation:segment.end];
              }
              [vehiclesArray addObject:vehicleInfo];
            }
            vehiclesInfo = [vehiclesArray copy];
          }
        }];
        
        dataMutable[@"modes"] = modes;
        dataMutable[@"vehicles"] = vehiclesInfo;
        
      } else {
        dataMutable[@"modes"] = tripInput.modes;
      }
      
      data = dataMutable;
      
    } else if ([inputItem conformsToProtocol:@protocol(TKSkedgoifierEventInputType)]) {
      id<TKSkedgoifierEventInputType> eventInput = (id<TKSkedgoifierEventInputType>)inputItem;
      // regular track items
      CLLocationCoordinate2D coordinate = eventInput.coordinate;
      if (!CLLocationCoordinate2DIsValid(coordinate)) {
        return; // ignore this
      }

      int priority = -1;
      NSDate *startDate  = eventInput.startDate;
      if (currentLocationTime) {
        startDate = startDate ? [startDate laterDate:currentLocationTime] : currentLocationTime;
      }
      NSDate *endDate = eventInput.endDate;
      BOOL direct = eventInput.goHereDirectly;
      
      switch (eventInput.kind) {
        case TKSkedgoifierEventKindActivity:
          priority = kSGPriorityEvents;
          break;
          
        case TKSkedgoifierEventKindCurrentLocation:
          priority = kSGPriorityCurrentLocation;
          currentLocationTime = endDate;
          break;
          
        case TKSkedgoifierEventKindHome:
          priority = kSGPriorityHome;
          break;
          
        case TKSkedgoifierEventKindRoutine:
          priority = kSGPriorityHabitual;
          break;
          
        case TKSkedgoifierEventKindStay:
          priority = kSGPriorityStay;
          break;
      }

      
      // get rid of items before 'current location'
      if (currentLocationTime
          && [currentLocationTime timeIntervalSinceDate:endDate] > 0) {
        return; // ignore this as it ended before 'now'
      }
      
      // special cases
      if (idx == 0) {
        if (! startDate) {
          startDate = [agendaStartDate dateByAddingTimeInterval:-12 * 60 * 60]; // Tim wants extra padding
        } else {
          startDate = [startDate laterDate:agendaStartDate];  // cap at agenda's start
        }
        if (!endDate) {
          endDate = [agendaEndDate dateByAddingTimeInterval:12 * 60 * 60];
        } else {
          endDate = [endDate earlierDate:agendaEndDate]; // cap at agenda's end
        }
      }
      if (idx == items.count - 1) {
        if (! endDate) {
          endDate = [agendaEndDate dateByAddingTimeInterval:12 * 60 * 60];
        } else {
          endDate = [endDate earlierDate:agendaEndDate]; // cap at agenda's end
        }
      }
      if ([startDate timeIntervalSinceDate:endDate] > 0) {
        [SGKLog error:@"Skedgoifier" format:@"End date (%@) is after start (%@) for object: %@", endDate, startDate, inputItem];
        return; // ignore this
      }
      
      data = @{
               @"class"     : @"event",
               @"id"        : key,
               @"priority"	: @(priority),
               @"startTime"	: @(floor([startDate timeIntervalSince1970])),
               @"endTime"		: @(ceil([endDate timeIntervalSince1970])),
#ifdef DEBUG
               @"startText"	: startDate ? [startDate descriptionWithLocale:[NSLocale currentLocale]] : @"",
               @"endText"		: endDate ? [endDate descriptionWithLocale:[NSLocale currentLocale]] : @"",
#endif
               @"direct"		: @(direct),
               @"location"  : [STKParserHelper dictionaryForCoordinate:coordinate],
             };
    }

    [payload addObject:data];
	}];
  if (payload.count == 0) {
    return nil;
  } else {
    return payload;
  }
}

#pragma mark - Helper: Parsing skedgoify.json output

- (void)processServerResultFromJSON:(id)json
                         completion:(nullable void(^)(NSArray * __nullable outputItems, NSError * __nullable error))completion
{
  NSDictionary *result = json[@"result"];
  if (! result) {
    [SGKLog warn:NSStringFromClass([self class]) format:@"Agenda error: %@", json[@"error"]];
    if (completion) {
      NSError *error = [SVKError errorFromJSON:json] ?: [NSError errorWithCode:91651 message:@"Could not calculate agenda, but no error from server either."];
      completion(nil, error);
    }
    return;
  }
  
  // things we collect for the main parser
  NSMutableSet *keysSeenBefore = [NSMutableSet setWithCapacity:self.keyToItems.count];
  
  // parsing the main output
  NSArray *track = result[@"track"];
  NSMutableDictionary *indexToTripGroups = [NSMutableDictionary dictionaryWithCapacity:track.count];
  NSMutableDictionary *indexToTripTrackDict = [NSMutableDictionary dictionaryWithCapacity:track.count];
  NSMutableArray *skedgoifiedItems = [NSMutableArray arrayWithCapacity:track.count];
  [track enumerateObjectsUsingBlock:^(NSDictionary *trackDict, NSUInteger idx, BOOL *stop) {
#pragma unused(stop)
    NSString *class = trackDict[@"class"];
    NSString *itemKey = trackDict[@"id"];
    if ([class isEqualToString:@"event"]) {
      // parse event
      if (! itemKey) {
        [SGKLog warn:NSStringFromClass([self class]) format:@"Still need to handle events without IDs!"];
        return; // skip this
      }
      id trackItem = self.keyToItems[itemKey];
      if (! trackItem) {
        ZAssert(false, @"Could not find track item with key '%@' in: %@", itemKey, self.keyToItems);
        return; // skip this
      }
      if (![trackItem conformsToProtocol:@protocol(TKAgendaEventInputType)]) {
        ZAssert(false, @"Event result returned for non-event input. Result: %@. Input: %@", trackDict, trackItem);
        return; // skip this
      }
      id<TKAgendaEventInputType> eventInput = (id<TKAgendaEventInputType>)trackItem;
      NSDate *effectiveStart = [NSDate dateWithTimeIntervalSince1970:[trackDict[@"effectiveStart"] integerValue]];
      NSDate *effectiveEnd   = [NSDate dateWithTimeIntervalSince1970:[trackDict[@"effectiveEnd"] integerValue]];
      
      if (! [keysSeenBefore containsObject:itemKey]) {
        // this is the time we get info of this item => set effective start + end
        id outputItem = [[TKSkedgoifierEventOutput alloc] initForInput:eventInput effectiveStart:effectiveStart effectiveEnd:effectiveEnd isContinuation:NO];
        [keysSeenBefore addObject:itemKey];
        [skedgoifiedItems addObject:outputItem];
      
      } else {
        // we've seen this before, add a continuation if the location is different from the
        // previous event => identified by whether there's a trip or not
        BOOL previousIsTrip = (idx > 0) && [track[idx - 1][@"class"] isEqualToString:@"trip"];
        if (previousIsTrip) {
          NSDate *continuationEnd = (idx < track.count - 1) ? effectiveEnd : nil;
          id outputItem = [[TKSkedgoifierEventOutput alloc] initForInput:eventInput effectiveStart:effectiveStart effectiveEnd:continuationEnd isContinuation:YES];
          [skedgoifiedItems addObject:outputItem];
        }
      }
      
    } else if ([class isEqualToString:@"trip"]) {
      if (itemKey) {
        // the old trip is compatible
        id trackItem = self.keyToItems[itemKey];
        if (! trackItem) {
          [SGKLog warn:NSStringFromClass([self class]) format:@"Unexpected key in result: %@", trackDict];
          return; // skip this
        }
        
        if (![trackItem conformsToProtocol:@protocol(TKAgendaTripInputType)]) {
          ZAssert(false, @"Trip result returned for non-event input. Result: %@. Input: %@", trackDict, trackItem);
          return; // skip this
        }
        
        id<TKAgendaTripInputType> tripItem = (id<TKAgendaTripInputType>)trackItem;
        id<STKTrip> trip = tripItem.trip;
        if (trip) {
          id outputItem = [[TKAgendaTripOutput alloc] initWithTrip:trip forInput:tripItem];
          [skedgoifiedItems addObject:outputItem];
        } else {
          // TODO: handle flights getting returned as matching
        }
        
      } else {
        // parse trip as usual
        NSArray *groups = trackDict[@"groups"];
        NSNumber *index = @(idx);
        indexToTripGroups[index] = groups;
        indexToTripTrackDict[index] = trackDict;
        id outputItem = [[TKTripPlaceholder alloc] initWithKey:index];
        [skedgoifiedItems addObject:outputItem];
      }
    }
  }];
  
  // then we forward it to a parser that takes care of the trips
  NSArray *segmentTemplates = result[@"segmentTemplates"];
  NSArray *alerts = result[@"alerts"];

  NSManagedObjectContext *tripKitContext = [[TKTripKit sharedInstance] tripKitContext];
  TKRoutingParser *parser = [[TKRoutingParser alloc] initWithTripKitContext:tripKitContext];
  NSDictionary *keyToItems = self.keyToItems;
  [parser parseAndAddResult:indexToTripGroups
       withSegmentTemplates:segmentTemplates
                  andAlerts:alerts
                 completion:
   ^(NSDictionary *keyToAddedTrips) {
     // now we can add the trips into the agenda
     [keyToAddedTrips enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSArray *trips, BOOL *stop) {
#pragma unused(stop)
       // Key matches the key that we passed on indexToTripGroups
       
       NSUInteger index = [skedgoifiedItems indexOfObjectPassingTest:^BOOL(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop2) {
#pragma unused(idx)
         if ([obj isKindOfClass:[TKTripPlaceholder class]]) {
           TKTripPlaceholder *placeholder = (TKTripPlaceholder *)obj;
           if ([placeholder.key isEqualToNumber:key]) {
             *stop2 = YES;
             return YES;
           }
         }
         return NO;
       }];
       
       if (index == NSNotFound) {
         ZAssert(false, @"Uh-oh, unexpected key: %@", key);
         return;
       }
       Trip *trip = [trips firstObject];
       TKAgendaTripOutput *tripOutput = [[TKAgendaTripOutput alloc] initWithTrip:trip forInput:nil];
       
       NSDate *leaveAfter = nil, *arriveBy = nil;
       NSDictionary *tripTrackDict = indexToTripTrackDict[key];
       NSString *fromId = tripTrackDict[@"fromId"];
       if (fromId) {
         id fromItem = keyToItems[fromId];
         if ([fromItem conformsToProtocol:@protocol(TKAgendaEventInputType)]) {
           id<TKAgendaEventInputType> fromEventInput = (id<TKAgendaEventInputType>)fromItem;
           
           tripOutput.fromIdentifier = fromEventInput.identifier;
           leaveAfter = fromEventInput.endDate;
           
         } else {
           ZAssert(false, @"Trip from something, that's not an event!");
         }
         
       }
       NSString *toId = tripTrackDict[@"toId"];
       if (toId) {
         id toItem = keyToItems[fromId];
         if ([toItem conformsToProtocol:@protocol(TKSkedgoifierEventInputType)]) {
           id<TKSkedgoifierEventInputType> toEventInput = (id<TKSkedgoifierEventInputType>)toItem;

           tripOutput.toIdentifier = toEventInput.identifier;
           arriveBy = toEventInput.startDate;
           
           trip.request.purpose = [NSString stringWithFormat:NSLocalizedStringFromTable(@"PrimaryLocationEnd", @"TripKit", @"For trip titles, e.g., 'To work'"), toEventInput.title];
           
           if (arriveBy && toEventInput.kind == TKSkedgoifierEventKindActivity) {
             // When we have an arrival time, mark the departure time as fixed.
             // Reason for this is that we'll then show the time you need to leave,
             // rather than keeping it flexible in the UI.
             trip.departureTimeIsFixed = YES;
           }
           
         } else {
           ZAssert(false, @"Trip from something, that's not an event!");
         }
       }
       
       [skedgoifiedItems replaceObjectAtIndex:index withObject:tripOutput];

       [TKRoutingParser populateRequestWithTripInformation:trip.request
                                              fromLocation:nil
                                                toLocation:nil
                                                leaveAfter:leaveAfter
                                                  arriveBy:arriveBy];
       
       // now we can post-prepare the trip
       trip.request.expandForFavorite = YES;
     }];
     
     if (completion) {
       completion(skedgoifiedItems, nil);
     }
   }];
  
  self.keyToItems = nil;
}

@end

@implementation TKTripPlaceholder

- (instancetype)initWithKey:(NSNumber *)key
{
  self = [super init];
  if (self) {
    self.key = key;
  }
  return self;
}

@end
