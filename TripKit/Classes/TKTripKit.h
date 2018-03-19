//
//  TripKit.h
//  TripKit
//
//  Created by Adrian Schoenig on 17/06/2014.
//
//


// Dependencies
@import Contacts;
@import CoreData;
@import CoreLocation;
@import MapKit;

#if TARGET_OS_IPHONE
@import QuartzCore;
@import CoreImage;
@import UIKit;
#else
@import AppKit;
#endif

// Kits
#import "SGRootKit.h"
#import "SVKServerKit.h"
#import "STKTransportKit.h"

// Helpers
#if TARGET_OS_IPHONE
#import "SGActions.h"
#import "SGAlert.h"
#import "SGImageCacher.h"
#endif

#import "SGCustomEvent.h"
#import "SGCustomEventRecurrenceRule.h"

// Headers
#import "TKConstants.h"

// Protocol headers
#import "TKRealTimeUpdatable.h"

// Core Data model classes
#import "TripRequest.h"
#import "TripGroup.h"
#import "Trip.h"
#import "DLSEntry.h"
#import "SegmentTemplate.h"
#import "SegmentReference.h"
#import "Service.h"
#import "StopLocation.h"
#import "Vehicle.h"
#import "Alert.h"
#import "Cell.h"

// Non-core data model classes
#import "TKSegment.h"
#import "TKPlainCell.h"
#import "TKTripFactory.h"

// Helpers
#import "TKNextSegmentScorer.h"
#import "NSManagedObject+TKPersistence.h"
#import "TripRequest+Classify.h"

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
#import "TKWaypointRouter.h"
#import "TKRealTimeUpdatableHelper.h"

// Track
#import "SGTrackHelper.h"

// Search
#import "SGAutocompletionDataProvider.h"
#import "SGAutocompletionDataSource.h"
#import "SGAutocompletionResult.h"
#import "SGBaseGeocoder.h"
#import "SGBuzzGeocoder.h"
#import "SGFoursquareGeocoder.h"
#import "SGRegionAutocompleter.h"
#import "SGSearchDataSource.h"

// Permissions
#import "SGAddressBookManager.h"
#import "SGCalendarManager.h"
#import "SGLocationManager.h"


NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const TKTripKitDidResetNotification;

@interface TKTripKit : NSObject

@property (nonatomic, strong) NSManagedObjectModel          *managedObjectModel;
@property (nonatomic, strong, null_resettable) NSPersistentStoreCoordinator  *persistentStoreCoordinator;
@property (nonatomic, strong, null_resettable) NSManagedObjectContext        *tripKitContext;

+ (NSManagedObjectModel *)tripKitModel;

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
