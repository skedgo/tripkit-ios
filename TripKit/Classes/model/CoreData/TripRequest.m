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
    return [[regions anyObject] modeIdentifiers];
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
