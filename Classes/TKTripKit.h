//
//  TripKit.h
//  TripGo
//
//  Created by Adrian Schoenig on 17/06/2014.
//
//

#import <CoreData/CoreData.h>

// Dependencies
#import "SVKServerKit.h"
#import "STKTransportKit.h"

// Headers
#import "TKConstants.h"

// Protocol headers
#import "TKStopAnnotation.h"
#import "TKRealTimeUpdatable.h"

// Core Data model classes
#import "TripRequest.h"
#import "TripGroup.h"
#import "Trip.h"
#import "DLSEntry.h"
#import "SegmentTemplate.h"
#import "SegmentReference.h"
#import "Service.h"
#import "Shape.h"
#import "StopLocation.h"
#import "Vehicle.h"
#import "Alert.h"

// Non-core data model classes
#import "TKColoredRoute.h"
#import "TKDLSTable.h"
#import "TKSegment.h"
#import "TKPlainCell.h"
#import "SGStopCoordinate.h"
#import "TKTripFactory.h"

// Helpers
#import "TKNextSegmentScorer.h"
#import "TKShareHelper.h"
#import "TKUserProfileHelper.h"

// Classification
#import "TKTripClassifier.h"
#import "TKPriceTimeTripClassifier.h"

// Routing
#import "TKSettings.h"
#import "TKParserHelper.h"
#import "TKRoutingParser.h"
#import "TKRouter.h"
#import "TKBuzzRouter.h"
#import "TKFakeRouter.h"
#import "TKBuzzRealTime.h"
#import "TKBuzzInfoProvider.h"
#import "TKTimetableDownloader.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const TKTripKitDidResetNotification;

@interface TKTripKit : NSObject

@property (nonatomic, strong) NSManagedObjectModel          *managedObjectModel;
@property (nonatomic, strong, null_resettable) NSPersistentStoreCoordinator  *persistentStoreCoordinator;
@property (nonatomic, strong, null_resettable) NSManagedObjectContext        *tripKitContext;

+ (NSManagedObjectModel *)tripKitModelInBundle:(NSBundle *)bundle;

+ (TKTripKit *)sharedInstance;

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

@end

NS_ASSUME_NONNULL_END
