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
    
    if ([STKModeHelper modes:hidden contain:groupModeIdentifiers]) {
      // if any mode is hidden, hide the whole group
      group.visibility = TripGroupVisibilityHidden;
      
    } else if ([STKModeHelper modes:minimized contain:groupModeIdentifiers]) {
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
