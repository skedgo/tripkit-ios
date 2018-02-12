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

typedef void(^FetchRequestBlock)(NSFetchRequest *);

@interface NSManagedObjectContext(SimpleFetch)

#pragma mark - Existence

- (BOOL)containsObjectForEntityClass:(Class)entityClass
                       withPredicate:(NSPredicate *)predOrNil;

- (BOOL)containsObjectForEntityName:(NSString *)entityName
                       withPredicate:(NSPredicate *)predOrNil;

#pragma mark - Fetch

- (NSArray *)fetchObjectsForEntityClass:(Class)entityClass
                       withFetchRequest:(FetchRequestBlock)requestBlock;

- (NSArray *)fetchObjectsForEntityClass:(Class)entityClass
                          withPredicate:(NSPredicate *)predOrNil
                     andSortDescriptors:(NSArray *)sortDescriptorsOrNil
                          andFetchLimit:(NSInteger)limit;

- (NSArray *)fetchObjectsForEntityClass:(Class)entityClass
                          withPredicate:(NSPredicate *)predOrNil
                     andSortDescriptors:(NSArray *)sortDescriptorsOrNil;

- (NSSet *)fetchObjectsForEntityClass:(Class)entityClass
                        withPredicate:(NSPredicate *)predOrNil;

- (NSSet *)fetchObjectsForEntityClass:(Class)entityClass
                  withPredicateString:(NSString *)predicateString, ...;

- (NSArray *)fetchObjectsForEntityName:(NSString *)entityName
                      withFetchRequest:(FetchRequestBlock)requestBlock;

- (NSArray *)fetchObjectsForEntityName:(NSString *)entityName
                         withPredicate:(NSPredicate *)predOrNil
                    andSortDescriptors:(NSArray *)sortDescriptorsOrNil 
                         andFetchLimit:(NSInteger)limit;

- (NSArray *)fetchObjectsForEntityName:(NSString *)entityName
                         withPredicate:(NSPredicate *)predOrNil
                    andSortDescriptors:(NSArray *)sortDescriptorsOrNil;

- (NSSet *)fetchObjectsForEntityName:(NSString *)newEntityName
                       withPredicate:(NSPredicate *)predOrNil;

- (NSSet *)fetchObjectsForEntityName:(NSString *)newEntityName
                 withPredicateString:(NSString *)predicateString, ...;

- (id)fetchUniqueObjectForEntityClass:(Class)entityClass
                        withPredicate:(NSPredicate *)predicate;

- (id)fetchUniqueObjectForEntityName:(NSString *)entityName
                       withPredicate:(NSPredicate *)predicate;

- (id)fetchUniqueObjectForEntityClass:(Class)entityClass
                  withPredicateString:(NSString *)predicateString, ...;

- (id)fetchUniqueObjectForEntityName:(NSString *)entityName
                 withPredicateString:(NSString *)predicateString, ...;


@end
