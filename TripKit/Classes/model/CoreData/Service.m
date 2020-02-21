//
//  Service.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 24/11/12.
//
//

#import "Service.h"

@import MapKit;

#import "TripKit/TripKit-Swift.h"

enum {
  SGServiceFlagRealTime               = 1 << 0,
  SGServiceFlagRealTimeCapable        = 1 << 1,
  SGServiceFlagCancelled              = 1 << 2,
  SGServiceFlagBicycleAccessible      = 1 << 3,
  SGServiceFlagWheelchairAccessible   = 1 << 4,
};
typedef NSUInteger SGServiceFlag;

@interface Service ()

@property (nonatomic, copy) NSArray *alerts;

@end

@implementation Service

@dynamic code;
@dynamic color;
@dynamic frequency;
@dynamic modeInfo;
@dynamic name;
@dynamic number;
@dynamic operatorName;
@dynamic flags;
@dynamic toDelete;
@dynamic continuation, progenitor;
@dynamic segments;
@dynamic shape;
@dynamic vehicle, vehicleAlternatives;
@dynamic visits;
@dynamic alertHashCodes;

@synthesize sortedVisits = _sortedVisits;
@synthesize alerts = _alerts;
@synthesize isRequestingServiceData;

- (void)remove
{
  self.toDelete = YES;
}

- (Alert *)sampleAlert
{
  return [self.alerts firstObject];
}

- (NSArray<Alert *> *)allAlerts
{
  return self.alerts;
}

- (BOOL)isRealTime
{
  return 0 != (self.flags.integerValue & SGServiceFlagRealTime);
}

- (void)setRealTime:(BOOL)realTime
{
	[self setFlag:SGServiceFlagRealTime to:realTime];
}

- (BOOL)isRealTimeCapable
{
  return 0 != (self.flags.integerValue & SGServiceFlagRealTimeCapable);
}

- (void)setRealTimeCapable:(BOOL)realTimeCapable
{
	[self setFlag:SGServiceFlagRealTimeCapable to:realTimeCapable];
}

- (BOOL)isCancelled
{
  return 0 != (self.flags.integerValue & SGServiceFlagCancelled);
}

- (void)setCancelled:(BOOL)cancelled
{
	[self setFlag:SGServiceFlagCancelled to:cancelled];
}

- (BOOL)isBicycleAccessible
{
  return 0 != (self.flags.integerValue & SGServiceFlagBicycleAccessible);
}

- (void)setBicycleAccessible:(BOOL)bicycleAccessible
{
  [self setFlag:SGServiceFlagBicycleAccessible to:bicycleAccessible];
}

- (BOOL)isWheelchairAccessible
{
  return 0 != (self.flags.integerValue & SGServiceFlagWheelchairAccessible);
}

- (void)setWheelchairAccessible:(BOOL)wheelchairAccessible
{
  [self setFlag:SGServiceFlagWheelchairAccessible to:wheelchairAccessible];
}

- (void)setLineName:(NSString *)lineName
{
  if (! lineName) {
    lineName = @"";
  }
  
  NSString *direction = [self direction];
  if (! direction) {
    direction = @"";
  }
  self.name = [NSString stringWithFormat:@"%@\1%@", lineName, direction];
}

- (NSString *)lineName
{
  NSRange range = [self.name rangeOfString:@"\1"];
  if (range.location == NSNotFound) {
    return self.name;
  } else {
    return [self.name substringToIndex:range.location];
  }
}

- (void)setDirection:(NSString *)direction
{
  if (! direction) {
    direction = @"";
  }
  
  NSString *lineName = [self lineName];
  if (! lineName) {
    lineName = @"";
  }
  self.name = [NSString stringWithFormat:@"%@\1%@", lineName, direction];
}

- (NSString *)direction
{
  NSRange range = [self.name rangeOfString:@"\1"];
  if (range.location == NSNotFound) {
    return nil;
  } else {
    return [self.name substringFromIndex:range.location + 1];
  }
}

- (NSString *)title
{
	NSMutableString *title = [NSMutableString stringWithCapacity:30];
	if (self.number.length > 0) {
		[title appendString:self.number];
		[title appendString:@" "];
	}
	[title appendString:self.lineName];
	return title;
}

- (nullable NSString *)shortIdentifier
{
  if (self.number.length > 0) {
    return self.number;
  } else {
    return self.lineName;
  }
}

- (BOOL)looksLikeAnExpress
{
  CLLocation *previous = nil;
  for (StopVisits *visit in self.sortedVisits) {
    CLLocationCoordinate2D coordinate = [visit coordinate];
    CLLocation *current = [[CLLocation alloc] initWithLatitude:coordinate.latitude
                                                     longitude:coordinate.longitude];
    if ([previous distanceFromLocation:current] > 5000) {
      return YES;
    }
    previous = current;
  }
  return NO;
}

- (nullable StopVisits *)visitForStopCode:(NSString *)stopCode
{
  for (StopVisits *visit in self.visits) {
    if ([visit isKindOfClass:[DLSEntry class]])
      continue;
    
    if ([visit.stop.stopCode isEqualToString:stopCode])
      return visit;
  }
  return nil;
}

- (NSArray *)shapesForEmbarkation:(StopVisits *)embarkation
                   disembarkingAt:(StopVisits *)disembarkation
{
  NSMutableArray *waypoints = [NSMutableArray array];
  NSMutableArray *visits = [NSMutableArray array];
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"index"
                                                                 ascending:YES];

  for (Service *service = self; service != nil; service = (disembarkation != nil ? service.continuation : nil)) {
    [waypoints addObjectsFromArray:[service.shape routePath]];
    [visits addObjectsFromArray:[service.visits sortedArrayUsingDescriptors:@[sortDescriptor]]];
  }
	
	// determine the split
	NSUInteger startSplit = 0;
  if (embarkation) {
    if (embarkation.service == self) {
      startSplit = [[self class] indexForSplittingWaypoints:waypoints
                                                    atVisit:embarkation
                                              withAllVisits:visits];
    } else {
      startSplit = 0; // we never have embarkations on an later service, so
                      // `self` has to be a continuation of `embarkation.service`
    }
  }
  NSInteger endSplit = -1;
  if (disembarkation) {
    endSplit = [[self class] indexForSplittingWaypoints:waypoints
                                                atVisit:disembarkation
                                          withAllVisits:visits];
  }

	NSMutableArray *shapes = [NSMutableArray arrayWithCapacity:2];
	if (startSplit > 0 || endSplit != -1) {
    NSArray *dashPattern = self.shape.routeDashPattern;
    // untravelled start
		TKColoredRoute *u = [[TKColoredRoute alloc] initWithWaypoints:waypoints
                                                             from:0
                                                               to:startSplit + 1 // include it
                                                        withColor:TKColor.routeDashColorNonTravelled
                                                      dashPattern:dashPattern
                                                      isTravelled:NO];
		[shapes addObject:u];

		TKColoredRoute *t = [[TKColoredRoute alloc] initWithWaypoints:waypoints
                                                             from:startSplit
                                                               to:endSplit > 0 ? endSplit + 1 : -1 // include it, too
                                                        withColor:self.color
                                                      dashPattern:dashPattern
                                                      isTravelled:YES];
		[shapes addObject:t];
    
    if (endSplit > 0) {
      t = [[TKColoredRoute alloc] initWithWaypoints:waypoints
                                               from:endSplit
                                                 to:-1
                                          withColor:TKColor.routeDashColorNonTravelled
                                        dashPattern:dashPattern
                                        isTravelled:NO];
      [shapes addObject:t];
    }
    
	} else {
		[shapes addObject:self.shape];
	}
	return shapes;
}


#pragma mark - Private methods

- (void)setFlag:(SGServiceFlag)flag to:(BOOL)value
{
	NSInteger flags = self.flags.integerValue;
	if (value) {
		self.flags = @(flags | flag);
	} else {
		self.flags = @(flags & ~flag);
	}
}

+ (NSUInteger)indexForSplittingWaypoints:(NSArray <id<MKAnnotation>> *)waypoints
																 atVisit:(StopVisits *)split
													 withAllVisits:(NSArray <StopVisits *> *)visits
{
	// where are we at in the visits array?
	NSInteger visitIndex    = 0;
	StopVisits *currentVisit = visits[visitIndex];
  CLLocationCoordinate2D coordinate = [currentVisit.stop.location coordinate];

	// whats the best index for the current target
	double bestTargetDistance = MAXFLOAT;
	NSInteger bestTargetIndex = -1;
	
	for (NSInteger waypointIndex = 0; waypointIndex < (NSInteger) waypoints.count; waypointIndex++) {
		id<MKAnnotation> waypoint = waypoints[waypointIndex];
		double distance =   fabs(coordinate.latitude - waypoint.coordinate.latitude)
 		                  + fabs(coordinate.longitude - waypoint.coordinate.longitude);
		if (distance < bestTargetDistance) {
			// we are still moving towards the target
			bestTargetDistance = distance;
			bestTargetIndex    = waypointIndex;
		}
		
		if (bestTargetDistance < 0.0001 || waypointIndex == (NSInteger) waypoints.count - 1) {
			// we are at the target. is it the requested split?
			if (currentVisit == split) {
				// winner!
//				[TKLog debug:@"TKService" text:[NSString stringWithFormat:@"Split is at %d with distance %.1f. Winning waypoint: %@.", bestTargetIndex, bestTargetDistance, waypoints[bestTargetIndex]]];
				return bestTargetIndex;
			} else {
				// advance the target
				visitIndex++;
        if (visitIndex >= visits.count) {
          return bestTargetIndex;
        }
				currentVisit = visits[visitIndex];
        coordinate = [currentVisit.stop.location coordinate];
				bestTargetDistance = MAXFLOAT;
				bestTargetIndex = -1;
				waypointIndex = bestTargetIndex; // reset to the previous index
			}
		}
	}
	ZAssert(false, @"Uh-oh!");
	return -1;
}

#pragma mark - Lazy accessors

- (NSArray *)alerts
{
  if (!_alerts) {
    NSArray *hasCodes = self.alertHashCodes;
    if (hasCodes.count == 0) {
      _alerts = @[];
    } else {
      _alerts = [Alert fetchAlertsForService:self];
    }
  }
  return _alerts;
}

- (NSArray *)sortedVisits
{
	if (nil == _sortedVisits) {
    NSInteger capacity = self.visits.count;
    NSMutableSet *visits = [NSMutableSet setWithCapacity:capacity];
    NSMutableSet *indices = [NSMutableSet setWithCapacity:capacity];
    for (StopVisits *visit in self.visits) {
      if ([visit isKindOfClass:[DLSEntry class]])
        continue;
      
      // avoid duplicate indexes which can happen if we fetched service data
      // multiple times. which shouldn't happen, but even if it does this method
      // should enforce
      NSNumber *index = visit.index;
      if ([indices containsObject:index])
        continue;
      
      [visits addObject:visit];
      [indices addObject:index];
    }
    
		if ([self hasServiceData]) {
			NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
			_sortedVisits = [visits sortedArrayUsingDescriptors:@[sorter]];
		} else {
			return [visits allObjects];
		}
	}
	return _sortedVisits;
}

@end
