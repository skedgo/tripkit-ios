//
//  NSManagedObject+SGPersistence.m
//  TripPlanner
//
//  Created by Kuan Lun Huang on 20/11/12.
//
//

#import "NSManagedObject+TKPersistence.h"

@implementation NSManagedObject (TKPersistence)

+ (instancetype)objectFromPersistentId:(NSString *)persistentId
                             inContext:(NSManagedObjectContext *)moc
{
  return [self objectFromPersistentId:persistentId
               withAppURLSchemeString:nil
                            inContext:moc];
}


+ (instancetype)objectFromPersistentId:(NSString *)persistentId
                withAppURLSchemeString:(NSString *)scheme
                             inContext:(NSManagedObjectContext *)moc
{
  NSMutableString *urlString = [NSMutableString stringWithString:persistentId];
  if (scheme) {
    NSRange toReplace = [urlString rangeOfString:scheme];
    if (toReplace.location == NSNotFound) {
      return nil;
    }
    
    [urlString replaceCharactersInRange:toReplace
                             withString:@"x-coredata"];
  }
  
	NSPersistentStoreCoordinator *coordinator = moc.persistentStoreCoordinator;
  NSManagedObject *(^onCoordinator)() = ^NSManagedObject *() {
    NSManagedObjectID *objectID;
    @try {
      objectID = [coordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:urlString]];
    }
    @catch (NSException *exception) {
      // nothing to do
    }
    if (objectID == nil)
      return nil;
    
    NSError *error;
    NSManagedObject *managedObject = [moc existingObjectWithID:objectID error:&error];
    return managedObject;
  };
  
  if ([coordinator respondsToSelector:@selector(performBlockAndWait:)]) {
    __block NSManagedObject *object = nil;
    [coordinator performBlockAndWait:^{
      object = onCoordinator();
    }];
    return object;
  } else {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated"
    if ([coordinator tryLock]) {
#pragma GCC diagnostic pop
      return onCoordinator();
    } else {
      return nil;
    }
  }
}

- (NSString *)persistentId
{
  return [self persistentIdWithAppURLSchemeString:nil];
}


- (NSString *)persistentIdWithAppURLSchemeString:(NSString *)scheme
{
  NSManagedObjectID *objectID = [self objectID];
  if ([objectID isTemporaryID]) {
    [self.managedObjectContext obtainPermanentIDsForObjects:@[self] error:NULL];
		objectID = [self objectID];
  }
  
	NSURL *url = [objectID URIRepresentation];
  if (scheme) {
    return [NSString stringWithFormat:@"%@:%@", scheme, [url resourceSpecifier]];
  } else {
    return [url absoluteString];
  }
}



@end
