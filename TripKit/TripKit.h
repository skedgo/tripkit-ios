//
//  TripKit.h
//  TripKit
//
//  Created by Adrian Schoenig on 24/06/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for TripKit.
FOUNDATION_EXPORT double TripKitVersionNumber;

//! Project version string for TripKit.
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
#import "TKTripKit.h"
#import "TKConstants.h"

// Protocol headers
#import "TKRealTimeUpdatable.h"

// Core Data model classes
#import "TripRequest.h"
#import "TripGroup.h"
#import "Trip.h"
#import "DLSEntry.h"
#import "SegmentReference.h"
#import "Service.h"
#import "StopLocation.h"
#import "Vehicle.h"
#import "Alert.h"
#import "Cell.h"

// Non-core data model classes
#import "TKSegment.h"
#import "TKTripFactory.h"
#import "TKCellHelper.h"

// Helpers
#import "TKNextSegmentScorer.h"
#import "NSManagedObject+TKPersistence.h"
#import "TripRequest+Classify.h"
#import "TKRegionOverlayHelper.h"

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
