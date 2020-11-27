//
//  TripKit.h
//  TripKit
//
//  Created by Adrian Schoenig on 24/06/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for TripKit.
/// :nodoc:
FOUNDATION_EXPORT double TripKitVersionNumber;

//! Project version string for TripKit.
/// :nodoc:
FOUNDATION_EXPORT const unsigned char TripKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <TripKit/PublicHeader.h>

// Dependencies

#if TARGET_OS_IPHONE
@import QuartzCore;
@import CoreImage;
@import UIKit;
#else
@import AppKit;
#endif

// Kits
#import "TKRootKit.h"
#import "TKServerKit.h"
#import "TKTransportKit.h"

// Helpers
#if TARGET_OS_IPHONE
#import "TKActions.h"
#import "TKAlertController.h"
#endif

// Headers
#import "TKTripKit.h"
#import "TKConstants.h"

// Core Data model classes
#import "TripRequest.h"
#import "TripGroup.h"
#import "Trip.h"
#import "DLSEntry.h"
#import "SegmentReference.h"
#import "Service.h"
#import "Vehicle.h"
#import "Alert.h"

// Non-core data model classes
#import "TKSegmentBuilder.h"

// Helpers
#import "NSManagedObject+TKPersistence.h"

// Classification
#import "TripRequest+Classify.h"
#import "TKTripClassifier.h"

// Routing
#import "TKSettings.h"
#import "TKCoreDataParserHelper.h"
#import "TKRoutingParser.h"
#import "TKTripFetcher.h"
#import "TKBuzzRealTime.h"
#import "TKBuzzInfoProvider.h"

// Search
#import "TKAutocompletionResult.h"
#import "TKSkedGoGeocoder.h"
#import "TKFoursquareGeocoder.h"
#import "TKRegionAutocompleter.h"

// Permissions
#import "TKCalendarManager.h"
#import "TKLocationManager.h"

// Deprecated
#import "SGDeprecatedAutocompletionDataProvider.h"
