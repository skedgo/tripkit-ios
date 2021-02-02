//
//  DLSEntry.m
//  TripKit
//
//  Created by Adrian Schoenig on 26/01/2014.
//
//

#import "DLSEntry.h"

#import "NSManagedObjectContext+SimpleFetch.h"
#import "TKEnums.h"

@implementation DLSEntry

@dynamic endStop;
@dynamic pairIdentifier;

+ (NSPredicate *)departuresPredicateForPairs:(NSSet *)pairs
                                    fromDate:(NSDate *)date
                                      filter:(NSString *)filter
{
	if (filter.length > 0) {
		return [NSPredicate predicateWithFormat:@"pairIdentifier IN %@ AND departure != nil AND departure > %@ AND (service.number CONTAINS[c] %@ OR service.name CONTAINS[c] %@ OR stop.shortName CONTAINS[c] %@ OR searchString CONTAINS[c] %@)", pairs, date, filter, filter, filter, filter];
	} else {
		return [NSPredicate predicateWithFormat:@"pairIdentifier IN %@ AND departure != nil AND departure > %@", pairs, date];
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

+ (void)clearAllEntriesInTripKitContext:(NSManagedObjectContext *)context
{
  NSArray *objects = [context fetchObjectsForEntityClass:self];
  for (DLSEntry *entry in objects) {
    [context deleteObject:entry];
  }
}

#pragma mark - StopVisit

- (TKGrouping)groupingWithPrevious:(StopVisits *)previous
                              next:(StopVisits *)next
{
#pragma unused(previous, next)
  // never break these up. we assume that dls entries to different locations are never displayed together.
  return TKGrouping_EdgeToEdge;
}

@end
