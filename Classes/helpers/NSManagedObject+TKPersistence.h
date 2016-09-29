//
//  NSManagedObject+SGPersistence.h
//  TripPlanner
//
//  Created by Kuan Lun Huang on 20/11/12.
//
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSManagedObject (TKPersistence)

+ (nullable instancetype)objectFromPersistentId:(NSString *)persistentId
                                      inContext:(NSManagedObjectContext *)moc;
- (NSString *)persistentId;


+ (nullable instancetype)objectFromPersistentId:(NSString *)persistentId
                         withAppURLSchemeString:(nullable NSString *)scheme
                                      inContext:(NSManagedObjectContext *)moc;
- (NSString *)persistentIdWithAppURLSchemeString:(nullable NSString *)scheme;

@end

NS_ASSUME_NONNULL_END
