//
//  TripKit.m
//  TripKit
//
//  Created by Adrian Schoenig on 17/06/2014.
//
//

#import "TKTripKit.h"

#import "NSUserDefaults+SharedDefaults.h"
#import "TKConfig.h"
#import "TKServer.h"

#import <TripKit/TripKit-Swift.h>

NSString *const TKTripKitDidResetNotification = @"TKTripKitDidResetNotification";

@interface TKTripKit ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDate *resetDateFromInitialization;
@property (nonatomic, strong) NSCache *inMemoryCache;

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
    self.inMemoryCache = [[NSCache alloc] init];
    [self tripKitContext]; // wake up context
  }
  return self;
}

- (void)reload
{
  _tripKitContext = nil;
  _persistentStoreCoordinator = nil;
  
  [self tripKitContext]; // wake up
}

- (void)reset
{
  [TKLog debug:@"TKTripKit" text:@"Reseting TripKit."];
  
  _tripKitContext = nil;
  _persistentStoreCoordinator = nil;
  [self.inMemoryCache removeAllObjects];
  
  [self removeLocalFiles];
  
  [self tripKitContext]; // wake up
}

#pragma mark - Private helpers

+ (NSBundle *)bundle {
  return [NSBundle bundleForClass:[TKTripKit class]];
}

- (BOOL)didResetToday
{
  NSString *currentReset = [self resetStringForToday];
  NSString *lastReset = [[NSUserDefaults standardUserDefaults] stringForKey:@"TripKitLastReset"];
  if (lastReset == nil) {
    // Never reset yet, remember today so that we'll reset tomorrow, but
    // pretent we already reset today to not reset right at the start.
    [[NSUserDefaults standardUserDefaults] setObject:currentReset forKey:@"TripKitLastReset"];
    return true;
  } else {
    return [lastReset isEqualToString:currentReset];
  }
}

- (NSString *)resetStringForToday
{
  NSString *dateString = [self.dateFormatter stringFromDate:[NSDate date]];
  return [NSString stringWithFormat:@"%@-%@", [TKServer xTripGoVersion], dateString];
}

- (NSURL *)localDirectory
{
  NSURL *directory;
  NSString * appGroupName = [[TKConfig sharedInstance] appGroupName];
  if (appGroupName != nil) {
    directory = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:appGroupName];
    if (directory == nil) {
      ZAssert(false, @"Can't load container directory for app group (%@)! Check your settings.", appGroupName);
    }
  }
  if (nil == directory) {
    directory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    if (directory == nil) {
      ZAssert(false, @"Can't find local directory for TripKit!");
    }
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
  [[NSUserDefaults standardUserDefaults] setObject:currentReset forKey:@"TripKitLastReset"];
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
  
  [TKLog debug:@"TKTripKit" text:@"TripKit context initialised"];
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
  
  if (! [self didResetToday]) {
    [TKLog debug:@"TKTripKit" text:@"Reseting TripKit as it wasn't reset today."];
    [self removeLocalFiles];
  }
  NSDate *lastResetDate = [[NSUserDefaults sharedDefaults] objectForKey:@"TripKitLastResetDate"];
  self.resetDateFromInitialization = lastResetDate ?: [NSDate date];
  
  _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[TKTripKit tripKitModel]];
  
  NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption : @(YES),
                             NSInferMappingModelAutomaticallyOption       : @(YES)};
  
  NSError *error = nil;
  NSURL *storeURL = [self localFile];
  ZAssert(storeURL, @"Can't initialise without a storeURL!");
  if (! [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
    // if it failed, delete the file
    [TKLog debug:@"TKTripKit" text:@"Reseting TripKit due to failed migration."];
    [self removeLocalFiles];
    
    // let's try again. this time there's no file. so it has to succeed
    [[NSFileManager defaultManager] createDirectoryAtURL:[storeURL URLByDeletingLastPathComponent]
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:&error];
    
    if (! [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
      // otherwise, kill it
      ZAssert(false, @"Unresolved migration error: %@. File: %@", error, storeURL);
    }
  }
  
  return _persistentStoreCoordinator;
}

@end
