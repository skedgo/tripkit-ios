//
//  DLSEntry.h
//  TripGo
//
//  Created by Adrian Schoenig on 26/01/2014.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "StopVisits.h"

@class StopLocation;

/**
 A `DLSEntry` represents the connection of a particular service starting at a particular stop and going all the way an end stop without the passanger having to get off.
 
 @note The _arrival_ represents arriving at the `endStop` not arriving at the starting `stop` as is the case for usual instances of `StopVisits`. This means that `arrival` is always after (or at the same time as) as `departure`.
 
 @note The `service` might not be the same when arriving at `endStop` but it can instead be one of the start's
 */
@interface DLSEntry : StopVisits

/**
 Indexed identifier to quickly look up entries for a particular pair of stops. 
 */
@property (nonatomic, retain) NSString *pairIdentifier;

/**
 The destination. It should not be a parent stop. The time to get off is the `arrival` of this `DLSEntry`.
 
 @see StopVisit superclass
 */
@property (nonatomic, retain) StopLocation *endStop;

/**
 Creates a predicate to query the database for DLS entries for the specified list of pair identifiers after the given date and using the specific filter.
 
 @param pairs  Strings matched against the `pairIdentifier` of the DLS entries.
 @param date   Starting date and time.
 @param filter Filter which the returnes DLS entries must match.
 
 @return Predicate to query CoreData with
 */
+ (NSPredicate *)departuresPredicateForPairs:(NSSet *)pairs
                                    fromDate:(NSDate *)date
                                      filter:(NSString *)filter;

+ (NSArray *)fetchDLSEntriesPairs:(NSSet *)pairs
                         fromDate:(NSDate *)date
                            limit:(NSUInteger)limit
                 inTripKitContext:(NSManagedObjectContext *)context;

/**
 Deletes all the entries from CoreData that have a matching pair identifier
 
 @param pairIdentifiers Set of pair identifier string that should get deleted
 @param context         Managed object context to delete the entries in
 */
+ (void)clearEntriesWithIdentifiers:(NSSet *)pairIdentifiers
                   inTripKitContext:(NSManagedObjectContext *)context;

+ (void)clearAllEntriesInTripKitContext:(NSManagedObjectContext *)context;

@end
