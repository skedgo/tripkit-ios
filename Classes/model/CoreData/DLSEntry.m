//
//  DLSEntry.m
//  TripGo
//
//  Created by Adrian Schoenig on 26/01/2014.
//
//

#import "DLSEntry.h"

#import <TripKit/TKTripKit.h>

#import "TKRealTimeUpdatableHelper.h"

@implementation DLSEntry

@dynamic endStop;
@dynamic pairIdentifier;

+ (NSPredicate *)departuresPredicateForPairs:(NSSet *)pairs
                                    fromDate:(NSDate *)date
                                      filter:(NSString *)filter
{
	if (filter.length > 0) {
		return [NSPredicate predicateWithFormat:@"toDelete = NO AND pairIdentifier IN %@ AND departure != nil AND departure > %@ AND (service.number CONTAINS[c] %@ OR service.name CONTAINS[c] %@ OR stop.shortName CONTAINS[c] %@ OR searchString CONTAINS[c] %@)", pairs, date, filter, filter, filter, filter];
	} else {
		return [NSPredicate predicateWithFormat:@"toDelete = NO AND pairIdentifier IN %@ AND departure != nil AND departure > %@", pairs, date];
	}
}

+ (NSArray *)fetchDLSEntriesPairs:(NSSet *)pairs
                         fromDate:(NSDate *)date
                            limit:(NSUInteger)limit
                 inTripKitContext:(NSManagedObjectContext *)context
{
  NSArray *visits = [context fetchObjectsForEntityClass:self
                                       withFetchRequest:
                     ^(NSFetchRequest *request) {
                       request.predicate = [self departuresPredicateForPairs:pairs
                                                                    fromDate:date
                                                                      filter:nil];
                       request.sortDescriptors = [self defaultSortDescriptors];
                       request.fetchLimit = limit;
                     }];
  return visits;
}

+ (void)clearEntriesWithIdentifiers:(NSSet *)pairIdentifiers
                   inTripKitContext:(NSManagedObjectContext *)context
{
  if (pairIdentifiers.count == 0)
    return;
  
  NSSet *objects = [context fetchObjectsForEntityClass:self
                                   withPredicateString:@"toDelete = NO AND pairIdentifier IN %@", pairIdentifiers];
  for (DLSEntry *entry in objects) {
    [entry remove];
  }
}

+ (void)clearAllEntriesInTripKitContext:(NSManagedObjectContext *)context
{
  NSSet *objects = [context fetchObjectsForEntityClass:self
                                   withPredicateString:@"toDelete = NO"];
  for (DLSEntry *entry in objects) {
    [entry remove];
  }
}

#pragma mark - TKRealTimeUpdatable

- (BOOL)wantsRealTimeUpdates
{
  return self.service.isRealTimeCapable && [TKRealTimeUpdatableHelper wantsRealTimeUpdatesForStart:self.departure andEnd:self.arrival forPreplanning:NO];
}


#pragma mark - StopVisit

- (SGKGrouping)groupingWithPrevious:(StopVisits *)previous
                              next:(StopVisits *)next
{
#pragma unused(previous, next)
  // never break these up. we assume that dls entries to different locations are never displayed together.
  return SGKGrouping_EdgeToEdge;
}

@end
