//
//  StopLocation.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 24/11/12.
//
//

#import "StopLocation.h"

#ifdef TK_NO_FRAMEWORKS
#import "TripKit.h"
#endif

#import "TripKit/TripKit-Swift.h"


@interface StopLocation ()

@property (nonatomic, copy) NSArray *alertsIncludingChildren;

@end

@implementation StopLocation

@dynamic name;
@dynamic location;
@dynamic stopCode;
@dynamic wheelchairAccessible;
@dynamic stopModeInfo;
@dynamic shortName;
@dynamic filter;
@dynamic sortScore;
@dynamic regionName;
@dynamic toDelete;

@dynamic cell;
@dynamic parent;
@dynamic children;
@dynamic visits;

@synthesize lastTopVisit = _lastTopVisit;
@synthesize lastEarliestDate = _lastEarliestDate;
@synthesize alertsIncludingChildren = _alertsIncludingChildren;

+ (instancetype)fetchStopForStopCode:(NSString *)stopCode
                       inRegionNamed:(NSString *)regionName
                   requireCoordinate:(BOOL)requireCoordinate
                    inTripKitContext:(NSManagedObjectContext *)tripKitContext
{
  if (!regionName) {
    return nil;
  }
  
  NSPredicate *predicate = requireCoordinate
  ? [NSPredicate predicateWithFormat:@"stopCode = %@ AND regionName = %@ AND toDelete = NO AND location != nil", stopCode, regionName]
  : [NSPredicate predicateWithFormat:@"stopCode = %@ AND regionName = %@ AND toDelete = NO", stopCode, regionName];
  
  StopLocation *stop = [tripKitContext fetchUniqueObjectForEntityClass:self withPredicate:predicate];
  if (stop) {
    return stop;
  }
  
  // region name might be missing, just match on stop code which might give you the wrong stop but it's unlikely.
  return [tripKitContext fetchUniqueObjectForEntityClass:self
                                     withPredicateString:@"stopCode = %@ AND toDelete = NO", stopCode];
}

+ (instancetype)fetchOrInsertStopForStopCode:(NSString *)stopCode
                               inRegionNamed:(NSString *)regionName
                          intoTripKitContext:(NSManagedObjectContext *)tripKitContext
{
  StopLocation *stopLocation = [self fetchOrInsertStopForStopCode:stopCode
                                                         modeInfo:nil
                                                       atLocation:nil
                                               intoTripKitContext:tripKitContext];
  stopLocation.regionName = regionName;
  return stopLocation;
}

+ (instancetype)fetchOrInsertStopForStopCode:(NSString *)stopCode
                                    modeInfo:(ModeInfo *)modeInfo
                                  atLocation:(SGKNamedCoordinate *)location
                          intoTripKitContext:(NSManagedObjectContext *)tripKitContext
{
  NSParameterAssert(tripKitContext);
	
  StopLocation *stop = nil;
  SVKRegion *region = nil;
  if (location && stopCode) {
    region = [[location regions] anyObject];
    stop = [self fetchStopForStopCode:stopCode
                        inRegionNamed:region.name
                    requireCoordinate:NO
                     inTripKitContext:tripKitContext];

  }
  
  if (stop) {
    stop.name = [location title];
    stop.location = location;
    stop.stopCode = stopCode;
    stop.stopModeInfo = modeInfo;
  } else {
    stop = [self insertStopForStopCode:stopCode
                              modeInfo:modeInfo
                            atLocation:location
                    intoTripKitContext:tripKitContext];
  }
  
  stop.regionName = region.name;
  return stop;
}

+ (instancetype)insertStopForStopCode:(NSString *)stopCode
                             modeInfo:(ModeInfo *)modeInfo
                           atLocation:(SGKNamedCoordinate *)location
                   intoTripKitContext:(NSManagedObjectContext *)tripKitContext
{
  NSString *entityName = NSStringFromClass(self);
  StopLocation *newStop = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                        inManagedObjectContext:tripKitContext];
  newStop.name = [location title];
  newStop.location = location;
  newStop.stopCode = stopCode;
  newStop.stopModeInfo = modeInfo;
  return newStop;
}

+ (NSString *)platformForStopCode:(NSString *)stopCode
                    inRegionNamed:(NSString *)regionName
                 inTripKitContext:(NSManagedObjectContext *)tripKitContext
{
#pragma unused(regionName)
  // NOTE: For performance reason we're ignoring the region name. Fingers crossed!
  
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
  request.entity = [NSEntityDescription entityForName:NSStringFromClass(self)
                               inManagedObjectContext:tripKitContext];
  request.resultType = NSDictionaryResultType;
  request.fetchLimit = 1;
  request.propertiesToFetch = @[@"shortName"];
  request.predicate = [NSPredicate predicateWithFormat:@"stopCode = %@", stopCode];
  
  NSError *error;
  NSArray *results = [tripKitContext executeFetchRequest:request error:&error];
  if (results.count > 0) {
    return [[results firstObject] objectForKey:@"shortName"];
  } else {
    ZAssert(!error, @"Error during fetch: %@", error);
    return nil;
  }
}

- (void)remove
{
  self.toDelete = YES;
}

- (nullable NSPredicate *)departuresPredicateFromDate:(nullable NSDate *)date
{
  if (!self.stopsToMatchTo || !date) {
    return nil;
  }
  
  return [StopVisits departuresPredicateForStops:[self stopsToMatchTo]
                                        fromDate:date
                                          filter:self.filter];
}

- (StopVisits *)lastDeparture
{
	NSPredicate *ourVisits = [NSPredicate predicateWithFormat:@"toDelete = NO AND stop IN %@", self.stopsToMatchTo];
	NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"departure"
																													 ascending:NO];
	NSArray *visits = [self.managedObjectContext fetchObjectsForEntityClass:[StopVisits class]
																														withPredicate:ourVisits
																											 andSortDescriptors:@[sorter]
																														andFetchLimit:1];
	if (visits.count > 0) {
		return [visits objectAtIndex:0];
	} else {
		return nil;
	}
}

- (NSArray *)stopsToMatchTo
{
	if (self.children.count > 0) {
		return [self.children allObjects];
	} else {
		return @[self];
	}
}

- (void)clearVisits
{
	for (StopVisits *visit in self.visits) {
		if (NO == visit.isActive.boolValue) {
      [visit remove];
		}
	}
	
	for (StopLocation *stop in self.children) {
		[stop clearVisits];
	}
}

#pragma mark - Lazy accessors

- (NSArray *)alertsIncludingChildren
{
  if (!_alertsIncludingChildren) {
    NSMutableArray *alerts = [NSMutableArray array];
    [alerts addObjectsFromArray:[Alert fetchAlertsForStopLocation:self]];
    
    for (StopLocation *child in self.children) {
      [alerts arrayByAddingObjectsFromArray:child.alertsIncludingChildren];
    }
    _alertsIncludingChildren = alerts;
  }
  return _alertsIncludingChildren;
}

@end
