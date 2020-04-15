//
//  Trip.m
//  TripKit
//
//  Created by Adrian Schönig on 9/03/11.
//  Copyright (c) 2011 SkedGo. All rights reserved.
//

#import "TripRequest.h"

#import <TripKit/TripKit-Swift.h>

#define BHCostCount 3

@interface TripRequest ()

@property (nonatomic, strong) NSMutableSet *requestedModes;
@property (nonatomic, strong) NSArray<TKRegion *> *localRegions;

@end

@implementation TripRequest
@dynamic fromLocation;
@dynamic toLocation;
@dynamic purpose;
@dynamic preferredGroup;
@dynamic departureTime, arrivalTime, timeType;
@dynamic timeCreated;
@dynamic tripGroups;
@dynamic expandForFavorite;
@dynamic excludedStops;
@synthesize requestedModes;
@synthesize replacement;
@synthesize defaultVisibility;
@synthesize localRegions = _localRegions;

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

- (TKRegion *)spanningRegion
{
  CLLocationCoordinate2D start = [self.fromLocation coordinate];
  CLLocationCoordinate2D end = [self.toLocation coordinate];
  return [TKRegionManager.shared regionContainingCoordinate:start andOther:end];
}

- (TKRegion *)startRegion
{
  if (! _localRegions) {
    _localRegions = [self _determineRegions];
  }
  return [_localRegions firstObject];
}

- (TKRegion *)endRegion
{
  if (! _localRegions) {
    _localRegions = [self _determineRegions];
  }
  return [_localRegions lastObject];
}

/**
 @return The regions that this query is touching
 */
- (nonnull NSSet <TKRegion *> *)touchedRegions
{
  NSMutableSet *regions = [NSMutableSet setWithCapacity:5];
  TKRegionManager *manager = TKRegionManager.shared;
  [regions unionSet:[manager localRegionsContainingCoordinate:self.fromLocation.coordinate]];
  [regions unionSet:[manager localRegionsContainingCoordinate:self.toLocation.coordinate]];
  
  // Add international, if we either have no region or more than 1
  if (regions.count != 1) {
    [regions addObject:TKRegion.international];
  }
  return regions;
}

- (NSArray <NSString *> *)applicableModeIdentifiers
{
  NSSet *regions = [self touchedRegions];
  if (regions.count == 1) {
    return [[[regions anyObject] modeIdentifiers] allObjects];
  }
  
  NSMutableSet *modes = [NSMutableSet set];
  for (TKRegion *region in regions) {
    [modes addObjectsFromArray:[region modeIdentifiers]];
  }
  return [[modes allObjects] sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull obj1, NSString * _Nonnull obj2) {
    return [obj1 compare:obj2];
  }];
}

- (NSTimeZone *)departureTimeZone
{
  return [TKRegionManager.shared timeZoneForCoordinate:[self.fromLocation coordinate]];
}

- (NSTimeZone *)arrivalTimeZone
{
  return [TKRegionManager.shared timeZoneForCoordinate:[self.toLocation coordinate]];
}

- (BOOL)resultsInSameQueryAs:(TripRequest *)other
{
  if (other == nil) {
    return NO;
  } else if ((other.type == TKTimeTypeArriveBefore && self.type != TKTimeTypeArriveBefore)
              || (other.type != TKTimeTypeArriveBefore && self.type == TKTimeTypeArriveBefore)) {
    return NO;
  } else if (fabs([other.time timeIntervalSinceDate:self.time]) >  30) { // within 30 seconds
    return NO;
  } else if (! [TKLocationHelper coordinate:[other.fromLocation coordinate]
                                     isNear:[self.fromLocation coordinate]]) {
    return NO;
  } else if (! [TKLocationHelper coordinate:[other.toLocation coordinate]
                                     isNear:[self.toLocation coordinate]]) {
    return NO;
  } else {
    return YES;
  }
}

- (void)adjustVisibilityForMinimizedModeIdentifiers:(NSSet * __nonnull)minimized
                              hiddenModeIdentifiers:(NSSet * __nonnull)hidden
{
  NSSet *allGroups = [self tripGroups];
  NSMutableDictionary *minimizedModeIdentifierSetToTripGroups = [NSMutableDictionary dictionaryWithCapacity:allGroups.count];
  for (TripGroup *group in allGroups) {
    NSSet *groupModeIdentifiers = [group usedModeIdentifiers];
    
    if ([TKModeHelper modes:hidden contain:groupModeIdentifiers]) {
      // if any mode is hidden, hide the whole group
      group.visibility = TKTripGroupVisibilityHidden;
      
    } else if ([TKModeHelper modes:minimized contain:groupModeIdentifiers]) {
      id key = groupModeIdentifiers;
      NSMutableArray *groups = [minimizedModeIdentifierSetToTripGroups objectForKey:key];
      if (! groups) {
        groups = [NSMutableArray arrayWithCapacity:5];
        minimizedModeIdentifierSetToTripGroups[key] = groups;
      }
      [groups addObject:group];
    } else {
      group.visibility = TKTripGroupVisibilityFull;
    }
  }
  
  NSArray *sorters = [self sortDescriptorsAccordingToSelectedOrder];
  [minimizedModeIdentifierSetToTripGroups enumerateKeysAndObjectsUsingBlock:^(id key, NSMutableArray *groups, BOOL *stopOuter) {
#pragma unused(key,stopOuter)
    NSArray *sorted = [groups sortedArrayUsingDescriptors:sorters];
    [sorted enumerateObjectsUsingBlock:^(TripGroup *tripGroup, NSUInteger index, BOOL *stopInner) {
#pragma unused(stopInner)
      tripGroup.visibility = (index == 0) ? TKTripGroupVisibilityMini : TKTripGroupVisibilityHidden;
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
  if (self.timeType.intValue == TKTimeTypeArriveBefore) {
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


@end
