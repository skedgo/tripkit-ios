//
//  TripKit.m
//  TripGo
//
//  Created by Adrian Schoenig on 17/06/2014.
//
//

#import "TKTripKit.h"

NSString *const TKTripKitDidResetNotification = @"TKTripKitDidResetNotification";

@interface TKTripKit ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDate *resetDateFromInitialization;

@end

@implementation TKTripKit

+ (TKTripKit *)sharedInstance
{
  DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
    return [[self alloc] init];
  });
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    // wake up context
    [self tripKitContext];
  }
  return self;
}

- (void)reload
{
  _tripKitContext = nil;
  _persistentStoreCoordinator = nil;
  
  [self tripKitContext];
}

- (void)reset
{
  _tripKitContext = nil;
  _persistentStoreCoordinator = nil;

  [self removeLocalFiles];
  
  [self tripKitContext];
}

#pragma mark - Private helpers

+ (NSManagedObjectModel *)tripKitModelInBundle:(NSBundle *)bundle
{
  NSURL *modelURL = [bundle URLForResource:@"TripKitModel" withExtension:@"momd"];
  return [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}

- (BOOL)didResetToday
{
  NSString *currentReset = [self resetStringForToday];
  NSString *lastReset = [[NSUserDefaults sharedDefaults] stringForKey:@"TripKitLastReset"];
  return [lastReset isEqualToString:currentReset];
}

- (NSString *)resetStringForToday
{
  return [self.dateFormatter stringFromDate:[NSDate date]];
}

- (NSURL *)localDirectory
{
  NSURL *directory = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:[SGKConfig appGroupName]];
  if (nil == directory) {
    [SGKLog warn:@"TKTripKit" format:@"Can't load container directory for app group (%@)!", [SGKConfig appGroupName]];
    directory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
  }
  return directory;
}

- (NSURL *)localFile
{
  return [[self localDirectory] URLByAppendingPathComponent:@"TripCache.sqlite"];
}

- (void)removeLocalFiles
{
  NSURL *directory = [self localDirectory];
  NSFileManager *fileMan = [NSFileManager defaultManager];
  for (NSURL *fileURL in [fileMan contentsOfDirectoryAtURL:directory
                                includingPropertiesForKeys:@[NSURLNameKey]
                                                   options:0
                                                     error:nil]) {
    if ([fileURL.lastPathComponent rangeOfString:@"TripCache.sqlite"].location != NSNotFound) {
      [fileMan removeItemAtURL:fileURL error:nil];
    }
  }
  
  // remember last reset
  NSString *currentReset = [self resetStringForToday];
  [[NSUserDefaults sharedDefaults] setObject:currentReset forKey:@"TripKitLastReset"];
  [[NSUserDefaults sharedDefaults] setObject:[NSDate date] forKey:@"TripKitLastResetDate"];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:TKTripKitDidResetNotification object:self];
}

- (NSDateFormatter *)dateFormatter
{
  if (!_dateFormatter) {
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.dateStyle = NSDateFormatterShortStyle;
    _dateFormatter.timeStyle = NSDateFormatterNoStyle;
  }
  return _dateFormatter;
}

#pragma mark - Core Data stack

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
  if (_managedObjectModel != nil) {
    return _managedObjectModel;
  }
  _managedObjectModel = [[self class] tripKitModelInBundle:[NSBundle mainBundle]];
  return _managedObjectModel;
}

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)tripKitContext
{
  if (_tripKitContext) {
    return _tripKitContext;
  }
  
  NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
  if (coordinator) {
    _tripKitContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _tripKitContext.persistentStoreCoordinator = coordinator;
    _tripKitContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
  }
  return _tripKitContext;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
  if (_persistentStoreCoordinator != nil) {
    return _persistentStoreCoordinator;
  }
  
  DLog(@"Setting up TripKit store...");
  if (! [self didResetToday]) {
    DLog(@"Clearing cache...");
    [self removeLocalFiles];
  }
  NSDate *lastResetDate = [[NSUserDefaults sharedDefaults] objectForKey:@"TripKitLastResetDate"];
  self.resetDateFromInitialization = lastResetDate ?: [NSDate date];
  
  _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
  
  NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption : @(YES),
                             NSInferMappingModelAutomaticallyOption       : @(YES)};
  
  NSError *error = nil;
  NSURL *storeURL = [self localFile];
  ZAssert(storeURL, @"Can't initialise without a storeURL!");
  if (! [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
    // if it failed, delete the file
    DLog(@"Deleting previous persistent store as lightweight migration failed.");
    [self removeLocalFiles];
    
    // let's try again. this time there's no file. so it has to succeed
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
      // otherwise, kill it
      ZAssert(false, @"That doesn't make sense. There's no file!");
      DLog(@"Unresolved migration error %@, %@", error, [error userInfo]);
    }
  }
  
  DLog(@"TripKit store set up.");
  return _persistentStoreCoordinator;
}

@end
