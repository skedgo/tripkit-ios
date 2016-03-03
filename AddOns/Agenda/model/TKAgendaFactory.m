//
//  SGAgenda.m
//  TripGo
//
//  Created by Adrian Schoenig on 2/04/2014.
//
//

#import "TKAgendaFactory.h"

#import "TKTripKit+Agenda.h"

NSString *const kTKAgendaFactoryTemplateStay       = @"kTKAgendaFactoryTemplateStay";
NSString *const kTKAgendaFactoryTemplatePlaceholder     = @"kTKAgendaFactoryTemplatePlaceholder";
NSString *const kTKAgendaFactoryTemplateCurrentLocation = @"kTKAgendaFactoryTemplateCurrentLocation";

#define MIN_DISTANCE_TO_CREATE_TRIPS 150

@interface TKAgendaFactory ()

@property (nonatomic, strong) NSMutableDictionary *startDateDict;
@property (nonatomic, strong) NSMutableDictionary *endDateDict;

@end

@implementation TKAgendaFactory

+ (CLLocationDistance)minimumDistanceToCreateTrips
{
  return MIN_DISTANCE_TO_CREATE_TRIPS;
}

- (void)buildAgendaTemplateForTrackItems:(NSArray *)items
                           withStartDate:(NSDate *)startDate
                             withEndDate:(NSDate *)endDate
                   limitToDateComponents:(nullable NSDateComponents *)limitToDateComponents
                          stayCoordinate:(CLLocationCoordinate2D)stayCoordinate
                            stayTimeZone:(NSTimeZone *)stayTimeZone
                         currentLocation:(nullable CLLocation *)currentLocation
                                 success:(TKAgendaFactoryTemplate)success
{
  NSParameterAssert(items);
  NSParameterAssert(stayTimeZone);
  NSParameterAssert(success);

  self.startDateDict = [NSMutableDictionary dictionaryWithCapacity:items.count];
  self.endDateDict   = [NSMutableDictionary dictionaryWithCapacity:items.count];

  // 0) cull the input
  NSMutableArray *culled = [NSMutableArray arrayWithArray:items];
  if (limitToDateComponents) {
    [self cullUnnecessaryBackgroundItems:culled forDateComponents:limitToDateComponents];
  }
  
  // 1) we sort the input
  NSArray *sorted = [culled sortedArrayUsingComparator:^NSComparisonResult(id<SGTrackItem> obj1, id<SGTrackItem> obj2) {
    NSDate *start1 = [self startDateForItem:obj1];
    NSDate *start2 = [self startDateForItem:obj2];
    NSComparisonResult result = [start1 compare:start2];
    if (result == NSOrderedSame) {
      NSDate *end1 = [self endDateForItem:obj1];
      NSDate *end2 = [self endDateForItem:obj2];
      result = [end1 compare:end2];
    }
    return result;
  }];
  
  // 2) now we create the template items and, at the same time, we determine start and end dates for the agenda
  NSMutableArray *templateItems = [NSMutableArray arrayWithCapacity:sorted.count + 3];
  NSMutableArray *attendedItems = [NSMutableArray arrayWithCapacity:sorted.count + 3];

  // 2.1) Now we need to find the *seed* information. This will set the seed information for what time zone we're in.
  __block NSInteger seedIndex = -1;
  __block NSTimeZone *seedTimeZone = stayTimeZone;

  [sorted enumerateObjectsUsingBlock:^(id<SGTrackItem> trackItem, NSUInteger index, BOOL *stop) {
    if (!limitToDateComponents || [[self class] trackItem:trackItem matchesDateComponents:limitToDateComponents]) {
      seedIndex = index;
      seedTimeZone = [SGTrackHelper attendanceTimeZoneForTrackItem:trackItem];
      *stop = YES;
    }
  }];
  
  // 2.2) go back from the seed item to the first one until we detect a midnight in that time zone
  // The start date is midnight on the date converted to the noonIndex item's time zone as that'll be the relevant date for the user
  NSDateComponents *dateComponents = [limitToDateComponents copy];
  if (dateComponents) {
    dateComponents.calendar.timeZone = seedTimeZone;
    startDate = [dateComponents.calendar dateFromComponents:dateComponents];
  }
  NSDate *earliestDate = nil;
  
  for (NSInteger index = seedIndex; index >= 0 && index < (NSInteger)sorted.count; index--) {
    id<SGTrackItem> item    = sorted[index];
    NSDate *itemEnd         = [self endDateForItem:item];
    if ([itemEnd timeIntervalSinceDate:startDate] < 0) // ends before midnight
      continue; // events that start earlier can still end later!
    
    // good item
    [templateItems insertObject:item atIndex:0];
    NSTimeZone *itemTimeZone = [SGTrackHelper attendanceTimeZoneForTrackItem:item];
    if (itemTimeZone) {
      // are we attending this potentially?
      if (! [SGTrackHelper trackItemShouldBeIgnored:item]) {
        if (!earliestDate || [itemEnd compare:earliestDate] == NSOrderedAscending) {
          earliestDate = itemEnd;
        }
        if (dateComponents) {
          dateComponents.timeZone = itemTimeZone;
          startDate = [dateComponents.calendar dateFromComponents:dateComponents];
        }

        [attendedItems insertObject:item atIndex:0];
      }
    }
  }
  
  // 2.3) go forward from the noon item to the first item until we detect a midnight in that time zone
  if (dateComponents) {
    dateComponents.calendar.timeZone = seedTimeZone;
    dateComponents.day += 1;
    endDate = [dateComponents.calendar dateFromComponents:dateComponents];
  }
  NSDate *latestDate = nil;
  
  for (NSInteger index = seedIndex + 1; index < (NSInteger)sorted.count; index++) {
    id<SGTrackItem> item      = sorted[index];
    NSDate *itemStart         = [self startDateForItem:item];
    if ([itemStart timeIntervalSinceDate:endDate] > 0) { // item starts after midnight
      continue;
    }
    NSDate *itemEnd           = [self endDateForItem:item];
    if ([itemEnd timeIntervalSinceDate:startDate] < 0) { // ends before midnight
      continue; // events that start earlier can still end later!
    }

    
    // good item
    [templateItems addObject:item];
    NSTimeZone *itemTimeZone = [SGTrackHelper attendanceTimeZoneForTrackItem:item];
    if (itemTimeZone) {
      // are we attending this potentially?
      if (! [SGTrackHelper trackItemShouldBeIgnored:item]) {
        if (!latestDate || [itemStart compare:latestDate] == NSOrderedDescending) {
          latestDate = itemStart;
        }
        if (dateComponents) {
          dateComponents.timeZone = itemTimeZone;
          endDate = [dateComponents.calendar dateFromComponents:dateComponents];
        }
        
        [attendedItems addObject:item];
      }
    }
  }

  // an empty day is one without any template items, ignoring current locations
  BOOL isEmptyDay = YES;
  for (id<SGTrackItem> trackItem in templateItems) {
    if ([trackItem respondsToSelector:@selector(isBackground)] && [trackItem isBackground]) {
      continue;
    }
    isEmptyDay = NO;
    break;
  }

  // if it's for today, add the current location at the correct
  // location if required
  if ([startDate timeIntervalSinceNow] < 0 && [endDate timeIntervalSinceNow] > 0) {
    
    // find the correct place
    NSInteger currentLocationFit = 0;
    NSInteger skipCount = 0;
    for (NSUInteger index = 0; index < templateItems.count; index++) {
      id item = templateItems[index];
      ZAssert([item conformsToProtocol:@protocol(SGTrackItem)], @"We should only have track items at this stage");
      
      id<SGTrackItem> trackItem = item;
      
      // we ignore anything that's excluded
      if ([SGTrackHelper trackItemShouldBeIgnored:trackItem]) {
        skipCount++;
        continue;
      }
      
      NSDate *itemStartDate = [self startDateForItem:trackItem];
      if ([itemStartDate timeIntervalSinceNow] > 0) {
        // hasn't started yet, no need to check later events
        // insert current location BEFORE this item
        currentLocationFit = index;
        break;
      }

      NSDate *itemEndDate = [self endDateForItem:trackItem];
      if (!itemEndDate || [itemEndDate timeIntervalSinceNow] < 0) {
        currentLocationFit = index + 1; // ended already, earliest after this
        continue;
      }
      
      // track item is currently taking place
      if ([[self class] trackItem:trackItem
                 containsLocation:currentLocation
                           atTime:[NSDate date]]) {
        // current location is compatible (incl. non existent) with event location
        // => don't add current location template
        currentLocationFit = -1;
        break;
      } else {
        // doesn't have a location or is otherwise incompatible, consider adding it afterwards, but DO NOT break as a subsequent track item might mean that we don't need the current location item.
        currentLocationFit = index + 1;
      }
    }
    
    if (currentLocationFit >= 0 && ! [[self class] location:currentLocation matchesByDistance:stayCoordinate]) {
      [templateItems insertObject:kTKAgendaFactoryTemplateCurrentLocation atIndex:MIN((NSInteger)templateItems.count, currentLocationFit)];
      [attendedItems insertObject:kTKAgendaFactoryTemplateCurrentLocation atIndex:MIN((NSInteger)attendedItems.count, MAX(currentLocationFit - skipCount, 0))];
    }
  }
  
  // now we have the start and end date and sorted and filtered the items. wee!
  
  // 3) Post processing by adding special items
  NSUInteger skipCount = 0;
  NSUInteger insertionSkipCount = 0;
  BOOL endIsBackground = NO;
  BOOL lastIsBackground = NO;
  static NSTimeInterval MaxGap = 3600; // 1 hour
  NSDate *dateToCheck = startDate;
  for (NSUInteger index = 0; index < templateItems.count; index++) {
    id templateItem = templateItems[index];
    if (![attendedItems containsObject:templateItem]) {
      skipCount++;
      insertionSkipCount++;
      continue;
    }
    if ([templateItem conformsToProtocol:@protocol(SGTrackItem)]) {
      id<SGTrackItem> trackItem = (id<SGTrackItem>)templateItem;
      NSDate *itemStart = [self startDateForItem:trackItem];
      NSTimeInterval allowedGap = [dateToCheck isEqualToDate:startDate] ? 0 : MaxGap;
      if ([itemStart timeIntervalSinceDate:dateToCheck] > allowedGap) {
        // there's a gap before => add stay
        [templateItems insertObject:kTKAgendaFactoryTemplateStay atIndex:index - insertionSkipCount];
        [attendedItems insertObject:kTKAgendaFactoryTemplateStay atIndex:MAX(index - skipCount, (NSUInteger)0)];
        insertionSkipCount = 0;
        index++;
      }
      NSDate *itemEnd   = [self endDateForItem:trackItem];
      BOOL isBackground = [trackItem respondsToSelector:@selector(isBackground)] && [trackItem isBackground];
      lastIsBackground = isBackground;
      if (itemEnd == [dateToCheck laterDate:itemEnd]) {
        dateToCheck = itemEnd;
        endIsBackground = isBackground;
      }
    } else {
      // current location
      skipCount++;
      insertionSkipCount++;
    }
  }
  if (skipCount == templateItems.count) { // didn't add start as all were skipped
    [templateItems insertObject:kTKAgendaFactoryTemplateStay atIndex:0];
    [attendedItems insertObject:kTKAgendaFactoryTemplateStay atIndex:0];
  }
  if ((endIsBackground && !lastIsBackground) // go back to hotel at end of day
      || [endDate timeIntervalSinceDate:dateToCheck] > 0) { // go back home
    [templateItems addObject:kTKAgendaFactoryTemplateStay];
    [attendedItems addObject:kTKAgendaFactoryTemplateStay];
  }
  
  // add a placeholder in the middle if it's an empty day
  if (isEmptyDay) {
    BOOL justHasStay = attendedItems.count == 1;
    NSUInteger subtractor = justHasStay ? 0 : 1;
    [templateItems insertObject:kTKAgendaFactoryTemplatePlaceholder atIndex:templateItems.count - subtractor];
    [attendedItems insertObject:kTKAgendaFactoryTemplatePlaceholder atIndex:attendedItems.count - subtractor];
    
    if (justHasStay) {
      [templateItems addObject:kTKAgendaFactoryTemplateStay];
      [attendedItems addObject:kTKAgendaFactoryTemplateStay];
    }
  }

  // done
  success(startDate, endDate, seedTimeZone, templateItems);
}

+ (BOOL)trackItem:(id<SGTrackItem>)trackItem matchesDateComponents:(NSDateComponents *)dateComponents
{
  NSDate *itemStart = [trackItem startDate];
  NSDate *itemEnd = nil;
  if (itemStart && [trackItem duration] >= 0) {
    itemEnd = [itemStart dateByAddingTimeInterval:[trackItem duration]];
  }
  if (!itemStart && ! itemEnd) {
    // applies every day
    return YES;
  }

  // we have a start and/or end => need to check if event overlaps the day in the item's timezone
  NSTimeZone *itemTimeZone = [SGTrackHelper attendanceTimeZoneForTrackItem:trackItem];
  if (itemTimeZone) {
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.timeZone = itemTimeZone;
    components.calendar = dateComponents.calendar;
    components.year = dateComponents.year;
    components.month = dateComponents.month;
    components.day = dateComponents.day;
    components.hour = 0;
    NSDate *componentsStart = [components.calendar dateFromComponents:components];
    if (itemEnd && [itemEnd earlierDate:componentsStart] == itemEnd) {
      return NO; // item ended already before this date
    }
    
    components.hour = 24;
    NSDate *componentsEnd = [components.calendar dateFromComponents:components];
    if ([itemStart laterDate:componentsEnd] == itemStart) {
      return NO; // item starts AFTER end
    }
    
    return YES; // overlaps
  }
  return NO;
}

+ (void)insertTrackItem:(id<SGTrackItem>)trackItem
              intoItems:(NSMutableArray *)items
{
  NSDate *startTime = [trackItem startDate];
  
  BOOL didInsert = NO;
  for (NSUInteger startIndex = 0; startIndex < items.count; startIndex++) {
    id object = items[startIndex];
    if ([object conformsToProtocol:@protocol(SGTrackItem)]) {
      NSDate *existingStart = [object startDate];
      if ([startTime timeIntervalSinceDate:existingStart] < 0) {
        [items insertObject:trackItem atIndex:startIndex];
        didInsert = YES;
        break;
      }
    } else {
      ZAssert(false, @"Object should be track item, but isn't: %@", object);
    }
  }
  if (! didInsert) {
    [items addObject:trackItem]; // add to end
  }
}

+ (BOOL)trackItem:(id<SGTrackItem>)trackItem
 containsLocation:(CLLocation *)location
           atTime:(NSDate *)time
{
  if (! location) {
    return NO;
  }
  if ([SGTrackHelper trackItemShouldBeIgnored:trackItem]) {
    return NO;
  }
  
  NSDate *startDate = nil;
  if ([trackItem respondsToSelector:@selector(effectiveStart)]) {
    startDate = [trackItem effectiveStart];
  }
  if (!startDate) {
    startDate = [trackItem startDate];
  }
  if (startDate && [startDate timeIntervalSinceDate:time] > 0) {
    // hasn't started yet
    return NO;
  }
  
  NSDate *endDate = nil;
  if ([trackItem respondsToSelector:@selector(effectiveEnd)]) {
    endDate = [trackItem effectiveEnd];
  }
  if (!endDate) {
    NSTimeInterval duration = [trackItem duration];
    if (duration >= 0) {
      endDate = [startDate dateByAddingTimeInterval:duration];
    }
  }
  if (endDate && [endDate timeIntervalSinceDate:time] < 0) {
    // ended already
    return NO;
  }
  
  if ([trackItem conformsToProtocol:@protocol(SGTripTrackItem)]) {
    id<SGTripTrackItem> tripTrackItem = (id<SGTripTrackItem>)trackItem;
    if ([tripTrackItem respondsToSelector:@selector(containsLocation:atTime:)]) {
      return [tripTrackItem containsLocation:location
                                      atTime:time];
    }
    
    id<STKTrip> trip = [tripTrackItem trip];
    id<STKTripSegment> nextSegment = [TKNextSegmentScorer nextSegmentOfTrip:trip
                                                                    forTime:time
                                                               withLocation:location];
    return (nextSegment != nil);
    
  } else if ([trackItem respondsToSelector:@selector(mapAnnotation)]) {
    // single-location event
    id<MKAnnotation> eventAnnotation = [trackItem mapAnnotation];
    if (eventAnnotation) {
      CLLocationCoordinate2D coordinate = [eventAnnotation coordinate];
      if (! location || [self location:location matchesByDistance:coordinate]) {
        return YES;
      }
    }
  }
  return NO;
}

+ (BOOL)trackItems:(NSArray<id<SGTrackItem>> *)trackItems
   containLocation:(CLLocation *)location
            atTime:(NSDate *)time
{
  for (id<SGTrackItem> trackItem in trackItems) {
    if ([self trackItem:trackItem containsLocation:location atTime:time]) {
      return YES;
    }
  }
  return NO;
}

+ (BOOL)location:(CLLocation *)location matchesByDistance:(CLLocationCoordinate2D)coordinate
{
  if (! CLLocationCoordinate2DIsValid(coordinate)) {
    return NO;
  }
  
  CLLocation *eventLocation = [[CLLocation alloc] initWithLatitude:coordinate.latitude
                                                         longitude:coordinate.longitude];
  return [location distanceFromLocation:eventLocation] < location.horizontalAccuracy + [self minimumDistanceToCreateTrips];
}

#pragma mark - Private helpers

+ (NSString *)trackItemsToString:(NSArray *)trackItems
{
  NSMutableString *string = [NSMutableString string];
  for (id<SGTrackItem> trackItem in trackItems) {
    NSString *start = [[trackItem startDate] ISO8601String];
    double hours = [trackItem duration] / 3600;
    NSString *title = [trackItem title];
    [string appendFormat:@"- %@: %.1fh (%@)\n", start, hours, title];
  }
  return string;
}

- (NSDate *)startDateForItem:(id<SGTrackItem>)trackItem
{
  NSString *key = [NSString stringWithFormat:@"%p", trackItem];
  NSDate *startDate = self.startDateDict[key];
  if (!startDate) {
    startDate = nil;
    if ([trackItem respondsToSelector:@selector(effectiveStart)]) {
      startDate = [trackItem effectiveStart];
    }
    if (!startDate) {
      startDate = [trackItem startDate];
    }
    if (startDate) {
      self.startDateDict[key] = startDate;
    }
  }
  return startDate;
}

- (NSDate *)endDateForItem:(id<SGTrackItem>)trackItem
{
  NSString *key = [NSString stringWithFormat:@"%p", trackItem];
  NSDate *endDate = self.endDateDict[key];
  if (!endDate) {
    if ([trackItem respondsToSelector:@selector(effectiveEnd)]) {
      endDate = [trackItem effectiveEnd];
    }
    if (!endDate) {
      NSDate *startDate = [self startDateForItem:trackItem];
      if (startDate && [trackItem duration] >= 0) {
        endDate = [startDate dateByAddingTimeInterval:[trackItem duration]];
      }
    }
    if (endDate) {
      self.endDateDict[key] = endDate;
    }
  }
  return endDate;
  
}

- (void)cullUnnecessaryBackgroundItems:(NSMutableArray *)allItems
                     forDateComponents:(NSDateComponents *)dateComponents
{
  NSMutableArray *backgroundItems = [NSMutableArray arrayWithCapacity:allItems.count];
  for (id item in allItems) { 
    if ([item conformsToProtocol:@protocol(SGTrackItem)]
        && [item respondsToSelector:@selector(isBackground)]
        && [(id<SGTrackItem>) item isBackground]) {
      
      if ([[self class] trackItem:item matchesDateComponents:dateComponents]) {
        [backgroundItems addObject:item];
      }
    }
  }
  
  if (backgroundItems.count <= 1) {
    return; // nothing to do
  }
  
  for (NSInteger index = backgroundItems.count - 1; index >= 0; index--) {
    if ([self backgroundItemAtIndex:index
             isDominatedGroupwiseBy:backgroundItems
                  forDateComponents:dateComponents]) {
      id object = backgroundItems[index];
      [allItems removeObject:object];
    }
  }
}

- (BOOL)backgroundItemAtIndex:(NSUInteger)index
       isDominatedGroupwiseBy:(NSArray *)backgroundItems
            forDateComponents:(NSDateComponents *)dateComponents
{
  id<SGTrackItem> item = (id<SGTrackItem>) backgroundItems[index];
  if (![[self class] trackItem:item matchesDateComponents:dateComponents]) {
    return YES;
  }
  
  NSDateComponents *components = [[NSDateComponents alloc] init];
  components.timeZone = [item timeZone];
  components.calendar = dateComponents.calendar;
  components.year = dateComponents.year;
  components.month = dateComponents.month;
  components.day = dateComponents.day;
  components.hour = 0;
  NSDate *itemStart = [item startDate];
  NSDate *prunedStart = [components.calendar dateFromComponents:components];
  prunedStart = itemStart ? [prunedStart laterDate:itemStart] : prunedStart;
  
  components.hour = 24;
  NSDate *prunedEnd = [components.calendar dateFromComponents:components];
  if (itemStart && [item duration] >= 0) {
    NSDate *itemEnd = [itemStart dateByAddingTimeInterval:[item duration]];
    prunedEnd = [prunedEnd earlierDate:itemEnd];
  }
  
  // later items in the list have higher priority!
  // so we subtract any time interval that a later item covers
  // we push back the `prunedStart`
  for (NSUInteger otherIndex = index + 1; otherIndex < backgroundItems.count; otherIndex++) {
    id<SGTrackItem> other = (id<SGTrackItem>) backgroundItems[otherIndex];
    NSDate *otherStart = [other startDate];
    if (otherStart) {
      NSDate *otherEnd = nil;
      if ([other duration] >= 0) {
        otherEnd = [otherStart dateByAddingTimeInterval:[other duration]];
      }
      
      if ([otherStart earlierDate:prunedStart] == otherStart
          && (otherEnd == nil || [otherEnd laterDate:prunedStart] == otherEnd)) {
        // other overlaps the front bit => push back pruned start
        prunedStart = otherEnd ? [otherEnd laterDate:prunedStart] : prunedStart;
      }
      
      if ([otherEnd laterDate:prunedEnd] == otherEnd
          && [otherStart earlierDate:prunedEnd] == otherStart) {
        // other overlaps the back bit => push forward pruned end
        prunedEnd = [otherStart earlierDate:prunedEnd];
      }
      
      if ([prunedEnd timeIntervalSinceDate:prunedStart] <= 0) {
        return YES;
      }
    }
  }
  
  if ([prunedEnd timeIntervalSinceDate:prunedStart] <= 0) {
    return YES;
  } else {
    ZAssert([prunedEnd timeIntervalSinceDate:prunedStart] > 0, @"Unexpected pruning status! Should have aborted before!");
    NSString *key = [NSString stringWithFormat:@"%p", item];
    self.startDateDict[key] = prunedStart;
    if ([item respondsToSelector:@selector(updateStartDate:)]) {
      [item updateStartDate:prunedStart];
    }
    self.endDateDict[key] = prunedEnd;
    if ([item respondsToSelector:@selector(updateEndDate:)]) {
      [item updateEndDate:prunedEnd];
    }
    return NO;
  }
}

@end
