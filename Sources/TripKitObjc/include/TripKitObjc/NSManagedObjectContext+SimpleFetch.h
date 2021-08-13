//
//  NSManagedObjectContext+SimpleFetch.h
//  RouteDrawer
//
//  Created by Adrian Schönig on 29/05/10.
//  Copyright 2010 Adrian Schönig. All rights reserved.
//
// Convenience methods to fetch the array of objects for a given Entity
// name in the context, optionally limiting by a predicate or by a predicate
// made from a format NSString and variable arguments.
//
// see http://cocoawithlove.com/2008/03/core-data-one-line-fetch.html

#import <CoreData/CoreData.h>

typedef void(^TKFetchRequestBlock)(NSFetchRequest *);

@interface NSManagedObjectContext(SimpleFetch)

#pragma mark - Existence

- (BOOL)containsObjectForEntityClass:(Class)entityClass
                       withPredicate:(NSPredicate *)predOrNil NS_SWIFT_UNAVAILABLE("Use containsObject<E>");

#pragma mark - Fetch

- (NSArray *)fetchObjectsForEntityClass:(Class)entityClass NS_SWIFT_UNAVAILABLE("Use fetchObjects<E>");

- (NSArray *)fetchObjectsForEntityClass:(Class)entityClass
                       withFetchRequest:(TKFetchRequestBlock)requestBlock NS_SWIFT_UNAVAILABLE("Use fetchObjects<E>");

- (NSArray *)fetchObjectsForEntityClass:(Class)entityClass
                          withPredicate:(NSPredicate *)predOrNil
                     andSortDescriptors:(NSArray *)sortDescriptorsOrNil
                          andFetchLimit:(NSInteger)limit NS_SWIFT_UNAVAILABLE("Use fetchObjects<E>");

- (NSArray *)fetchObjectsForEntityClass:(Class)entityClass
                          withPredicate:(NSPredicate *)predOrNil
                     andSortDescriptors:(NSArray *)sortDescriptorsOrNil NS_SWIFT_UNAVAILABLE("Use fetchObjects<E>");

- (NSSet *)fetchObjectsForEntityClass:(Class)entityClass
                        withPredicate:(NSPredicate *)predOrNil NS_SWIFT_UNAVAILABLE("Use fetchObjects<E>");

- (NSSet *)fetchObjectsForEntityClass:(Class)entityClass
                  withPredicateString:(NSString *)predicateString, ... NS_SWIFT_UNAVAILABLE("Use fetchObjects<E>");

- (id)fetchUniqueObjectForEntityClass:(Class)entityClass
                        withPredicate:(NSPredicate *)predicate NS_SWIFT_UNAVAILABLE("Use fetchUniqueObject<E>");

- (id)fetchUniqueObjectForEntityClass:(Class)entityClass
                  withPredicateString:(NSString *)predicateString, ... NS_SWIFT_UNAVAILABLE("Use fetchUniqueObject<E>");

@end
