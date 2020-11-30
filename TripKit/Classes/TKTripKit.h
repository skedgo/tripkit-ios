//
//  TripKit.h
//  TripKit
//
//  Created by Adrian Schoenig on 17/06/2014.
//
//

@import CoreData;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const TKTripKitDidResetNotification;

@interface TKTripKit : NSObject

@property (nonatomic, strong, null_resettable) NSPersistentStoreCoordinator  *persistentStoreCoordinator;
@property (nonatomic, strong, null_resettable) NSManagedObjectContext        *tripKitContext;

+ (NSBundle *)bundle;

+ (TKTripKit *)sharedInstance NS_REFINED_FOR_SWIFT;

/**
 Reloads the coordinator and context, which will be set to new instances. Call this when using multiple TripKit instances in different processes and they went out of sync.
 */
- (void)reload;

/**
 Wipes TripKit and effectively clears the cache. Following calls to the context and coordinator will return new instances, so make sure you clear local references to those.
 */
- (void)reset;

/**
 The date TripKit was last reset when the context and coordinator were initialised. If you have multiple TripKit instances in different processes accessing the same underlying store, you can use this to determine if they are still in sync. If they aren't you'll likely want to call `reload` on the TripKit instance which wasn't reloaded since the other one was reset.
 
 @return Reset date as when the context/coordinator were initialised
 */
- (nonnull NSDate *)resetDateFromInitialization;

- (NSCache *)inMemoryCache;

@end

NS_ASSUME_NONNULL_END
