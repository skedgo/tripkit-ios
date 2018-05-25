//
//  NSManagedObjectContext+SimpleFetch.m
//  RouteDrawer
//
//  Created by Adrian Schönig on 29/05/10.
//  Copyright 2010 Adrian Schönig. All rights reserved.
//

#import "NSManagedObjectContext+SimpleFetch.h"


@implementation NSManagedObjectContext(SimpleFetch)

- (BOOL)containsObjectForEntityClass:(Class)entityClass
                       withPredicate:(NSPredicate *)predOrNil
{
  ZAssert(self.parentContext != nil || [NSThread isMainThread], @"Not on the right thread!");

  NSString *entityName = NSStringFromClass(entityClass);
  NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                            inManagedObjectContext:self];
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
  [request setEntity:entity];
  
  if (predOrNil) {
    [request setPredicate:predOrNil];
  }

  NSUInteger count = [self countForFetchRequest:request error:NULL];
  return count > 0;
}

#pragma mark - Fetch

- (NSArray *)fetchObjectsForEntityName:(NSString *)entityName
											withFetchRequest:(FetchRequestBlock)requestBlock
{
  ZAssert(self.parentContext != nil || [NSThread isMainThread], @"Not on the right thread!");
  
  if (!entityName) {
    ZAssert(false, @"Entity name is missing!");
    return nil;
  }
  
  NSEntityDescription *entity = [NSEntityDescription entityForName:entityName
                                            inManagedObjectContext:self];
  if (! entity) {
    ZAssert(false, @"Entity %@ doesn't exist!", entity);
    return nil;
  }
	
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
  [request setEntity:entity];
	
	// let the request be filled in
  if (requestBlock) {
    requestBlock(request);
  }
	
  NSArray *array = [self executeFetchRequest:request error:NULL];
  if (nil == array) {
    return nil;
  } else {
    return array;
  }
}

- (NSArray *)fetchObjectsForEntityClass:(Class)entityClass
											 withFetchRequest:(FetchRequestBlock)requestBlock
{
  NSArray *array = [self fetchObjectsForEntityName:NSStringFromClass(entityClass)
                                  withFetchRequest:requestBlock];
  ZAssert([[self class] objects:array areOfClass:entityClass], @"Bad class: %@", array);
  return array;
}

- (NSArray *)fetchObjectsForEntityName:(NSString *)entityName
                         withPredicate:(NSPredicate *)predOrNil
                    andSortDescriptors:(NSArray *)sortDescriptorsOrNil 
                         andFetchLimit:(NSInteger)limit
{
  return [self fetchObjectsForEntityName:entityName
								 withFetchRequest:
	 ^(NSFetchRequest *request) {
		 if (nil != predOrNil) {
			 [request setPredicate:predOrNil];
		 }
		 
		 if (nil != sortDescriptorsOrNil) {
			 [request setSortDescriptors:sortDescriptorsOrNil];
		 }
		 
		 if (-1 != limit) {
			 [request setFetchLimit:limit];
		 }
	 }];
}

- (NSArray *)fetchObjectsForEntityName:(NSString *)entityName
                         withPredicate:(NSPredicate *)predOrNil
                    andSortDescriptors:(NSArray *)sortDescriptorsOrNil
{
  return [self fetchObjectsForEntityName:entityName
                           withPredicate:predOrNil
                      andSortDescriptors:sortDescriptorsOrNil
                           andFetchLimit:-1];
}

- (NSSet *)fetchObjectsForEntityName:(NSString *)newEntityName
                       withPredicate:(NSPredicate *)predOrNil
{
  NSArray *array = [self fetchObjectsForEntityName:newEntityName
                                     withPredicate:predOrNil
                                andSortDescriptors:nil];
  
  if (nil != array) {
    return [NSSet setWithArray:array];
  } else {
    return nil;
  }
}

- (NSSet *)fetchObjectsForEntityName:(NSString *)newEntityName
                 withPredicateString:(NSString *)predicateString, ...
{
  va_list variadicArguments;
  va_start(variadicArguments, predicateString);
  NSPredicate * predicate = [NSPredicate predicateWithFormat:predicateString
                                                   arguments:variadicArguments];
  va_end(variadicArguments);
  
  return [self fetchObjectsForEntityName:(NSString *)newEntityName
                           withPredicate:(NSPredicate *)predicate];
}

- (NSArray *)fetchObjectsForEntityClass:(Class)entityClass
                          withPredicate:(NSPredicate *)predOrNil
                     andSortDescriptors:(NSArray *)sortDescriptorsOrNil
                          andFetchLimit:(NSInteger)limit
{
  NSArray * array = [self fetchObjectsForEntityName:NSStringFromClass(entityClass)
                                      withPredicate:predOrNil
                                 andSortDescriptors:sortDescriptorsOrNil
                                      andFetchLimit:limit];
  ZAssert([[self class] objects:array areOfClass:entityClass], @"Bad class: %@", array);
  return array;
}

- (NSArray *)fetchObjectsForEntityClass:(Class)entityClass
                          withPredicate:(NSPredicate *)predOrNil
                     andSortDescriptors:(NSArray *)sortDescriptorsOrNil
{
  NSArray *array = [self fetchObjectsForEntityName:NSStringFromClass(entityClass)
                                     withPredicate:predOrNil
                                andSortDescriptors:sortDescriptorsOrNil];
  ZAssert([[self class] objects:array areOfClass:entityClass], @"Bad class: %@", array);
  return array;
}


- (NSSet *)fetchObjectsForEntityClass:(Class)entityClass
                        withPredicate:(NSPredicate *)predOrNil
{
  NSSet *set = [self fetchObjectsForEntityName:NSStringFromClass(entityClass)
                                 withPredicate:predOrNil];
  ZAssert([[self class] objects:[set allObjects] areOfClass:entityClass], @"Bad class: %@", set);
  return set;
}

- (NSSet *)fetchObjectsForEntityClass:(Class)entityClass
                  withPredicateString:(NSString *)predicateString, ...
{
  va_list variadicArguments;
  va_start(variadicArguments, predicateString);
  NSPredicate * predicate = [NSPredicate predicateWithFormat:predicateString
                                                   arguments:variadicArguments];
  va_end(variadicArguments);
  
  return [self fetchObjectsForEntityClass:entityClass
                            withPredicate:predicate];
}

- (id)fetchUniqueObjectForEntityClass:(Class)entityClass
                        withPredicate:(NSPredicate *)predicate
{
  NSString *entityName = NSStringFromClass(entityClass);
  NSArray *matches = [self fetchObjectsForEntityName:entityName
                                       withPredicate:predicate
                                  andSortDescriptors:nil
                                       andFetchLimit:1];
  id object = [matches firstObject];
  ZAssert(object == nil || [object isKindOfClass:entityClass], @"Bad class: %@", [object class]);
  return object;
}

- (id)fetchUniqueObjectForEntityClass:(Class)entityClass
                  withPredicateString:(NSString *)predicateString, ...
{
  va_list variadicArguments;
  va_start(variadicArguments, predicateString);
  NSPredicate * predicate = [NSPredicate predicateWithFormat:predicateString
                                                   arguments:variadicArguments];
  va_end(variadicArguments);
  
  return [self fetchUniqueObjectForEntityClass:entityClass withPredicate:predicate];
}

+ (BOOL)objects:(NSArray *)objects areOfClass:(Class)klass
{
  return YES;
  
//  for (id object in objects) {
//    if (![object isKindOfClass:klass]) {
//      return NO;
//    }
//  }
//  return YES;
}

@end
