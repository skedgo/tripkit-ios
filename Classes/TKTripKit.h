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

// Routing
#import "TKParserHelper.h"
#import "TKRoutingParser.h"
#import "TKRouter.h"
#import "TKBuzzRouter.h"
#import "TKFakeRouter.h"
#import "TKBuzzRealTime.h"
#import "TKBuzzInfoProvider.h"
#import "TKTimetableDownloader.h"

FOUNDATION_EXPORT NSString *const TKTripKitDidResetNotification;

@interface TKTripKit : NSObject

@property (nonatomic, strong) NSManagedObjectModel          *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator  *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectContext        *tripKitContext;

+ (NSManagedObjectModel *)tripKitModelInBundle:(NSBundle *)bundle;

+ (TKTripKit *)sharedInstance;

- (void)reset;

@end
