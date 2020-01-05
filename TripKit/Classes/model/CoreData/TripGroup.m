//
//  TripGroup.m
//  TripKit
//
//  Created by Adrian Schönig on 16/04/12.
//  Copyright (c) 2012 SkedGo. All rights reserved.
//

#import "TripGroup.h"

#import "TripKit/TripKit-Swift.h"


typedef enum {
  BHTripGroupFlagIsInCalendar = 1<<0,
  BHTripGroupFlagIsViewed     = 1<<1,
  BHTripGroupFlagIsIgnored    = 1<<2,
} BHTripGroupFlag;

@interface TripGroup ()

@property (nonatomic, strong, nullable) NSMutableDictionary *indexToPairIdentifiers;

@end

@implementation TripGroup

@dynamic classification;
@dynamic frequency;
@dynamic flags;
@dynamic sourcesRaw;
@dynamic visibilityRaw;
@dynamic toDelete;
@dynamic request;
@dynamic trips;
@dynamic visibleTrip;
@synthesize indexToPairIdentifiers;

/**
 * This adjusts the visible route.
 */
- (void)adjustVisibleTrip
{
  // default to preferred trip
  self.visibleTrip = [self tripWithBestScore];
}

- (NSDate *)earliestDeparture
{
  NSDate *earliestDeparture = nil;
  for (Trip *trip in self.trips) {
    if (! earliestDeparture || [trip.departureTime compare:earliestDeparture] == NSOrderedAscending) {
      earliestDeparture = trip.departureTime;
    }
  }
  return earliestDeparture;
}

/**
 * Returns the trip with the lowest score, that's not impossible
 */
- (nullable Trip *)tripWithBestScore
{
	NSSet *allTrips = self.trips;
	if (allTrips.count == 0) {
		return nil;
	}
	
  float bestScore = MAXFLOAT;
  Trip *bestTrip = nil;
  for (Trip *trip in allTrips) {
    if ([trip isImpossible]) {
      continue;
    }
    
    float score = [[trip totalScore] floatValue];
    if (score < bestScore) {
      bestTrip = trip;
      bestScore = score;
    }
  }
  
  if (nil == bestTrip) {
    // this is just here for debugging
    bestTrip = [allTrips anyObject];
  }
	return bestTrip;
}

- (NSSet *)usedModeIdentifiers
{
  if (self.visibleTrip) {
    return [self.visibleTrip usedModeIdentifiers];
  } else {
    return [[NSSet alloc] init];
  }
}

- (TKTripGroupVisibility)visibility
{
  return (TKTripGroupVisibility) [self.visibilityRaw integerValue];
}

- (void)setVisibility:(TKTripGroupVisibility)visibility
{
  if (self.visibility != visibility) {
    self.visibilityRaw = @(visibility);
  }
}

- (NSString *)debugString
{
  NSMutableString *output = [NSMutableString stringWithFormat:@"%lu trips with freq. %@\n", (unsigned long)self.trips.count, self.frequency];
  
  for (Trip *trip in self.trips) {
    [output appendString:@"\t- "];
    if (trip == self.visibleTrip) {
      [output appendString:@"★ "];
    }
    [output appendString:[trip debugString]];
    [output appendString:@"\n"];
  }
  
  return output;
}

#pragma mark - Caches

- (void)setPairIdentifiers:(NSSet *)pairIdentifiers forPublicSegment:(TKSegment *)segment
{
  if (! self.indexToPairIdentifiers) {
    self.indexToPairIdentifiers = [NSMutableDictionary dictionaryWithCapacity:self.visibleTrip.segments.count];
  }
  
  NSUInteger index = [self publicIndexOfPublicSegment:segment];
  [self.indexToPairIdentifiers setObject:pairIdentifiers forKey:@(index)];
}

- (NSSet *)pairIdentifiersForPublicSegment:(TKSegment *)segment
{
  if (! self.indexToPairIdentifiers) {
    return nil;
  }
  
  NSUInteger index = [self publicIndexOfPublicSegment:segment];
  return self.indexToPairIdentifiers[@(index)];
}

- (NSUInteger)publicIndexOfPublicSegment:(TKSegment *)segment
{
  NSUInteger index = 0;
  for (TKSegment *tripSegment in segment.trip.segments) {
    if (tripSegment == segment)
      return index;
    if ([tripSegment isPublicTransport]) {
      index++;
    }
  }
  return NSNotFound;
}

#pragma mark - UIAccessibility

- (NSString *)accessibilityLabel
{
  NSMutableString *accessibleLabel = [NSMutableString string];
  
#if TARGET_OS_IPHONE
  NSString *baseLabel = self.visibleTrip.accessibilityLabel;
	if (baseLabel) {
		[accessibleLabel appendString:baseLabel];
	}
#endif
	
  NSDictionary *dict = [self.visibleTrip costValues];
  [dict enumerateKeysAndObjectsUsingBlock:^(id key, NSString *string, BOOL *stop) {
#pragma unused(key,stop)
    if (accessibleLabel.length > 0) {
      [accessibleLabel appendString:@"; "];
    }
    [accessibleLabel appendString:string];
  }];
	
  return accessibleLabel;
}


#pragma mark - User interaction

- (BOOL)userDidSaveToCalendar {
  return self.flags.intValue & BHTripGroupFlagIsInCalendar;
}

- (void)setUserDidSaveToCalendar:(BOOL)userDidSaveToCalendar {
  // set flags
  [self setFlag:BHTripGroupFlagIsInCalendar to:userDidSaveToCalendar];
}

- (void)setFlag:(BHTripGroupFlag)flag to:(BOOL)value
{
	BHTripGroupFlag flags = (BHTripGroupFlag) self.flags.integerValue;
	if (value) {
		self.flags = @(flags | flag);
	} else {
		self.flags = @(flags & ~flag);
	}
}

@end
