//
//  NSManagedObject+TKPersistence.m
//  TripPlanner
//
//  Created by Kuan Lun Huang on 20/11/12.
//
//

#import "TKMacro.h"
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
  
  __block NSManagedObject *object = nil;
  NSPersistentStoreCoordinator *coordinator = moc.persistentStoreCoordinator;
  [coordinator performBlockAndWait:^{
    NSManagedObjectID *objectID;
    @try {
      objectID = [coordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:urlString]];
    }
    @catch (NSException *exception) {
      // nothing to do
    }
    if (objectID != nil) {
      NSError *error;
      object = [moc existingObjectWithID:objectID error:&error];
    }
  }];
  
  if ([object isKindOfClass:self]) {
    return object;
  } else {
    return nil;
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
    
    NSError *error;
    [self.managedObjectContext save:&error];
    ZAssert(error == nil, @"Error while saving: %@", error);
    
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
