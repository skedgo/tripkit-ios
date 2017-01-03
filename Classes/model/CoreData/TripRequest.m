//
//  Trip.m
//  TripGo
//
//  Created by Adrian Schönig on 9/03/11.
//  Copyright (c) 2011 SkedGo. All rights reserved.
//

#import "TripRequest.h"

#import <TripKit/TKTripKit.h>
#import <TripKit/TripKit-Swift.h>

#define BHCostCount 3

@interface TripRequest ()

@property (nonatomic, strong) NSMutableSet *requestedModes;
@property (nonatomic, strong) NSArray<SVKRegion *> *localRegions;

@end

@implementation TripRequest
@dynamic fromLocation;
@dynamic toLocation;
@dynamic purpose;
@dynamic preferredGroup;
@dynamic departureTime, arrivalTime, timeType;
@dynamic timeCreated;
@dynamic toDelete;
@dynamic tripGroups;
@dynamic expandForFavorite;
@synthesize requestedModes;
@synthesize replacement;
@synthesize defaultVisibility;
@synthesize localRegions = _localRegions;

- (void)remove {
  self.toDelete = YES;
}

#pragma mark - Public methods

+ (TripRequest *)insertRequestIntoTripKitContext:(NSManagedObjectContext *)context
{
  NSString *entityName = NSStringFromClass([self class]);
  TripRequest *newTrip = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                       inManagedObjectContext:context];
  newTrip.timeCreated = [NSDate date];
  return newTrip;
}

+ (TripRequest *)insertRequestFrom:(id<MKAnnotation>)fromLocation
                                to:(id<MKAnnotation>)toLocation
													 forTime:(NSDate *)time
                        ofTimeType:(SGTimeType)timeType
                intoTripKitContext:(NSManagedObjectContext *)context
{
	ZAssert(fromLocation, @"We need a from location");
	ZAssert(toLocation, @"We need a to location");
  
  TripRequest *newTrip = [self insertRequestIntoTripKitContext:context];
	
  newTrip.fromLocation   = [SGKNamedCoordinate namedCoordinateForAnnotation:fromLocation];
  newTrip.toLocation     = [SGKNamedCoordinate namedCoordinateForAnnotation:toLocation];
	newTrip.timeType       = @(timeType);
	
	switch (timeType) {
		case SGTimeTypeArriveBefore:
			ZAssert(time, @"We need a time!");
			newTrip.arrivalTime   = time;
			newTrip.departureTime = nil;
			break;
		
		case SGTimeTypeLeaveAfter:
			ZAssert(time, @"We need a time!");
			newTrip.arrivalTime   = nil;
			newTrip.departureTime = time;
			break;
			
    case SGTimeTypeNone:
		case SGTimeTypeLeaveASAP:
			newTrip.arrivalTime   = nil;
			newTrip.departureTime = nil;
			break;
	}
  return newTrip;
}

+ (NSString *)timeStringForTime:(nullable NSDate *)time
                     ofTimeType:(SGTimeType)timeType
                       timeZone:(NSTimeZone *)timeZone
{
  NSString *title = nil;
  switch (timeType) {
    case SGTimeTypeLeaveASAP: {
      title = NSLocalizedStringFromTableInBundle(@"Leave now", @"TripKit", [TKTripKit bundle], nil);
      break;
    }
      
    case SGTimeTypeLeaveAfter:
    case SGTimeTypeArriveBefore: {
      NSString *prefix = timeType == SGTimeTypeLeaveAfter
        ? NSLocalizedStringFromTableInBundle(@"Leave", @"TripKit", [TKTripKit bundle], @"Prefix for selected 'leave after' time")
        : NSLocalizedStringFromTableInBundle(@"Arrive", @"TripKit", [TKTripKit bundle], @"Prefix for selected 'arrive by' time");
      
      NSMutableString *titleBuilder = [NSMutableString stringWithString:prefix];
      [titleBuilder appendString:@" "];
      
      NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
      dateFormatter.timeStyle = NSDateFormatterShortStyle;
      dateFormatter.dateStyle = NSDateFormatterShortStyle;
      dateFormatter.locale = [SGStyleManager applicationLocale];
      dateFormatter.doesRelativeDateFormatting = YES;
      
      dateFormatter.timeZone = timeZone;
      NSString *timeString = [dateFormatter stringFromDate:time];
      if (timeString) {
        timeString = [timeString stringByReplacingOccurrencesOfString:@" pm" withString:@"pm"];
        timeString = [timeString stringByReplacingOccurrencesOfString:@" am" withString:@"am"];
        timeString = [timeString lowercaseStringWithLocale:[NSLocale systemLocale]];
        [titleBuilder appendString:timeString];
      }
      
      if (timeZone && ![timeZone isEqualToTimeZone:[NSTimeZone defaultTimeZone]]) {
        [titleBuilder appendFormat:@" %@", timeZone.abbreviation];
      }
      title = titleBuilder;
      break;
    }
      
    default:
      break;
  }
  
  return title;
}

- (TripRequest *)insertedEmptyCopy
{
  if (! self.managedObjectContext) {
    ZAssert(false, @"Don't create a copy of a request which doesn't have a MOC.");
    return nil;
  }
  
  TripRequest *newTrip = [[self class] insertRequestIntoTripKitContext:self.managedObjectContext];
  newTrip.fromLocation   = self.fromLocation;
  newTrip.toLocation     = self.toLocation;
  newTrip.arrivalTime    = self.arrivalTime;
  newTrip.departureTime  = self.departureTime;
  newTrip.timeType       = self.timeType;
  return newTrip;
}

- (void)dealloc
{
	[self cleanUp];
}

- (void)didTurnIntoFault
{
	[super didTurnIntoFault];
	[self cleanUp];
}

- (void)cleanUp
{
	self.requestedModes = nil;
}

- (SVKRegion *)spanningRegion
{
  CLLocationCoordinate2D start = [self.fromLocation coordinate];
  CLLocationCoordinate2D end = [self.toLocation coordinate];
  return [[SVKRegionManager sharedInstance] regionForCoordinate:start
                                                    andOther:end];
}

- (SVKRegion *)startRegion
{
  if (! _localRegions) {
    _localRegions = [self determineRegions];
  }
  return [_localRegions firstObject];
}

- (SVKRegion *)endRegion
{
  if (! _localRegions) {
    _localRegions = [self determineRegions];
  }
  return [_localRegions lastObject];
}

/**
 @return The regions that this query is touching
 */
- (nonnull NSSet <SVKRegion *> *)touchedRegions
{
  NSMutableSet *regions = [NSMutableSet setWithCapacity:5];
  SVKRegionManager *manager = [SVKRegionManager sharedInstance];
  [regions unionSet:[manager localRegionsForCoordinate:self.fromLocation.coordinate]];
  [regions unionSet:[manager localRegionsForCoordinate:self.toLocation.coordinate]];
  
  if (regions.count >= 2) {
    [regions addObject:[SVKInternationalRegion shared]];
  }
  return regions;
}

- (NSArray <NSString *> *)applicableModeIdentifiers
{
  NSSet *regions = [self touchedRegions];
  if (regions.count == 1) {
    return [[regions anyObject] modeIdentifiers];
  }
  
  NSMutableSet *modes = [NSMutableSet set];
  for (SVKRegion *region in regions) {
    [modes addObjectsFromArray:[region modeIdentifiers]];
  }
  return [[modes allObjects] sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull obj1, NSString * _Nonnull obj2) {
    return [obj1 compare:obj2];
  }];
}

- (NSTimeZone *)departureTimeZone
{
  return [[SVKRegionManager sharedInstance] timeZoneForCoordinate:[self.fromLocation coordinate]];
}

- (NSTimeZone *)arrivalTimeZone
{
  return [[SVKRegionManager sharedInstance] timeZoneForCoordinate:[self.toLocation coordinate]];
}

- (NSString *)timeString
{
  return [TripRequest timeStringForTime:self.time
                             ofTimeType:self.type
                               timeZone:[self departureTimeZone]];
}

- (BOOL)resultsInSameQueryAs:(TripRequest *)other
{
  if (other == nil)
    return NO;
  if (other.type != self.type)
    return NO;
  if (fabs([other.time timeIntervalSinceDate:self.time]) >  30) // within 30 seconds
    return NO;
  if (! [SGLocationHelper coordinate:[other.fromLocation coordinate]
                              isNear:[self.fromLocation coordinate]])
    return NO;
  if (! [SGLocationHelper coordinate:[other.toLocation coordinate]
                              isNear:[self.toLocation coordinate]])
    return NO;
  return YES;
}

- (void)adjustVisibilityForMinimizedModeIdentifiers:(NSSet * __nonnull)minimized
                              hiddenModeIdentifiers:(NSSet * __nonnull)hidden
{
  NSSet *allGroups = [self tripGroups];
  NSMutableDictionary *minimizedModeIdentifierSetToTripGroups = [NSMutableDictionary dictionaryWithCapacity:allGroups.count];
  for (TripGroup *group in allGroups) {
    NSSet *groupModeIdentifiers = [group usedModeIdentifiers];
    
    if ([groupModeIdentifiers intersectsSet:hidden]) {
      // if any mode is hidden, hide the whole group
      group.visibility = TripGroupVisibilityHidden;
      
    } else if ([groupModeIdentifiers intersectsSet:minimized]) {
      id key = groupModeIdentifiers;
      NSMutableArray *groups = [minimizedModeIdentifierSetToTripGroups objectForKey:key];
      if (! groups) {
        groups = [NSMutableArray arrayWithCapacity:5];
        minimizedModeIdentifierSetToTripGroups[key] = groups;
      }
      [groups addObject:group];
    } else {
      group.visibility = TripGroupVisibilityFull;
    }
  }
  
  NSArray *sorters = [self sortDescriptorsAccordingToSelectedOrder];
  [minimizedModeIdentifierSetToTripGroups enumerateKeysAndObjectsUsingBlock:^(id key, NSMutableArray *groups, BOOL *stopOuter) {
#pragma unused(key,stopOuter)
    NSArray *sorted = [groups sortedArrayUsingDescriptors:sorters];
    [sorted enumerateObjectsUsingBlock:^(TripGroup *tripGroup, NSUInteger index, BOOL *stopInner) {
#pragma unused(stopInner)
      tripGroup.visibility = (index == 0) ? TripGroupVisibilityMini : TripGroupVisibilityHidden;
    }];
  }];
}

- (TripGroup *)lastSelection
{
	return self.preferredGroup;
}

- (void)setLastSelection:(TripGroup *)tripGroup
{
	self.preferredGroup = tripGroup;
}

- (Trip *)preferredTrip
{
  return self.preferredGroup.visibleTrip;
}

- (void)setPreferredTrip:(Trip *)preferredTrip
{
  [preferredTrip setAsPreferredTrip];
}

- (NSSet *)trips
{
  NSMutableSet *trips = [NSMutableSet set];
  for (TripGroup *group in self.tripGroups) {
    for (Trip *trip in group.trips) {
      [trips addObject:trip];
    }
  }
  return trips;
}

- (SGTimeType)type
{
  return (SGTimeType) self.timeType.integerValue;
}

- (NSDate *)time
{
  SGTimeType type = [self type];
	switch (type) {
    case SGTimeTypeNone: // default to now
		case SGTimeTypeLeaveASAP:
			return [NSDate date];
			
		case SGTimeTypeLeaveAfter:
			return [self departureTime];
			
		case SGTimeTypeArriveBefore:
			return [self arrivalTime];
	}
}

- (void)setTime:(NSDate *)time forType:(SGTimeType)type
{
  self.timeType = @(type);
	
	switch (type) {
		case SGTimeTypeLeaveASAP:
			self.departureTime = [NSDate date];
			self.arrivalTime = nil;
			break;
			
		case SGTimeTypeLeaveAfter:
			self.departureTime = time;
			self.arrivalTime = nil;
			break;
			
		case SGTimeTypeArriveBefore:
			self.departureTime = nil;
			self.arrivalTime = time;
			break;
      
    case SGTimeTypeNone:
      self.departureTime = nil;
      self.arrivalTime   = nil;
      break;
	}
}

- (NSString *)timeSorterTitle
{
  if (self.timeType.intValue == SGTimeTypeArriveBefore) {
    return NSLocalizedStringFromTableInBundle(@"Departure", @"TripKit", [TKTripKit bundle], @"Departure time sorter title") ;
  } else {
    return NSLocalizedStringFromTableInBundle(@"Arrival", @"TripKit", [TKTripKit bundle], @"Arrival time sorter title") ;
  }
}

- (BOOL)hasTrips
{
  return self.tripGroups.count > 0;
}

- (BOOL)priceInformationAvailable
{
  if (! [self hasTrips]) {
    return YES;
  }
  
  for (Trip *trip in self.trips) {
    if (trip.totalPrice) {
      return YES;
    }
  }
  return NO;
}

- (NSArray *)sortDescriptorsAccordingToSelectedOrder
{
  STKTripCostType sortType = (STKTripCostType) [[NSUserDefaults sharedDefaults] integerForKey:TKDefaultsKeyLastUseSortIndex];
  return [self sortDescriptorsWithPrimary:sortType];
}

- (NSArray<NSSortDescriptor *> *)sortDescriptorsWithPrimary:(STKTripCostType)sortType
{
	NSArray *sortDescriptors;
	NSSortDescriptor *first, *second, *third, *primaryTimeSorter, *scoreSorter, *visibilitySorter;
	
	primaryTimeSorter = [self timeSorterForGroups:YES];
	visibilitySorter  = [[NSSortDescriptor alloc] initWithKey:@"visibilityRaw" ascending:YES];
	scoreSorter       = [[NSSortDescriptor alloc] initWithKey:@"visibleTrip.totalScore" ascending:YES];
	
	switch (sortType) {
    case STKTripCostTypeTime:
			// sort by time
			if (self.timeType.intValue == SGTimeTypeArriveBefore) {
				first = primaryTimeSorter;
				second = [[NSSortDescriptor alloc] initWithKey:@"visibleTrip.arrivalTime" ascending:YES];
			} else {
				first = primaryTimeSorter;
				second = [[NSSortDescriptor alloc] initWithKey:@"visibleTrip.departureTime" ascending:NO];
			}
			third   = visibilitySorter;
      break;
      
		case STKTripCostTypeDuration:
			first   = [[NSSortDescriptor alloc] initWithKey:@"visibleTrip.minutes" ascending:YES];
      second  = visibilitySorter;
			third   = primaryTimeSorter;
			break;
			
		case STKTripCostTypePrice:
      first   = [[NSSortDescriptor alloc] initWithKey:@"visibleTrip.totalPriceUSD" ascending:YES];
      second  = visibilitySorter;
			third   = primaryTimeSorter;
      break;
			
		case STKTripCostTypeCarbon:
			first   = [[NSSortDescriptor alloc] initWithKey:@"visibleTrip.totalCarbon" ascending:YES];
      second  = visibilitySorter;
			third   = primaryTimeSorter;
			break;
      
    case STKTripCostTypeCalories:
			first   = [[NSSortDescriptor alloc] initWithKey:@"visibleTrip.totalCalories" ascending:YES];
      second  = visibilitySorter;
			third   = primaryTimeSorter;
			break;

    case STKTripCostTypeWalking:
			first   = [[NSSortDescriptor alloc] initWithKey:@"visibleTrip.totalWalking" ascending:YES];
      second  = visibilitySorter;
			third   = primaryTimeSorter;
			break;
      
    case STKTripCostTypeHassle:
			first   = [[NSSortDescriptor alloc] initWithKey:@"visibleTrip.totalHassle" ascending:YES];
      second  = visibilitySorter;
			third   = primaryTimeSorter;
			break;

    case STKTripCostTypeCount:
      ZAssert(false, @"Don't sort by this!");
      // fallthrough!

    case STKTripCostTypeScore:
			first   = visibilitySorter;
      second  = scoreSorter;
      third   = primaryTimeSorter;
			break;
	}
	
	sortDescriptors = @[first, second, third];
	return sortDescriptors;
}

- (NSString *)debugString
{
  NSArray *sortedGroups = [self.tripGroups sortedArrayUsingDescriptors:[self sortDescriptorsAccordingToSelectedOrder]];

  NSMutableString *output = [NSMutableString stringWithFormat:@"%lu groups\n", (unsigned long)sortedGroups.count];
  for (TripGroup *group in sortedGroups) {
    [output appendString:@"\t- "];
    [output appendString:[group.visibleTrip debugString]];
    [output appendString:@"\n"];
  }
  
  return output;
}

#pragma mark - Private methods

- (NSSortDescriptor *)timeSorterForGroups:(BOOL)forGroups
{
  NSString *base = forGroups ? @"visibleTrip." : @"";
  
  if (self.timeType.intValue == SGTimeTypeArriveBefore) {
    return [[NSSortDescriptor alloc] initWithKey:[NSString stringWithFormat:@"%@departureTime", base] ascending:NO];
  } else {
    return [[NSSortDescriptor alloc] initWithKey:[NSString stringWithFormat:@"%@arrivalTime", base] ascending:YES];
  }
}


@end
