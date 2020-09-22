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
#import <TripKit/TKRootKit.h>
#import <TripKit/TKServerKit.h>
#import <TripKit/TKTransportKit.h>

// Helpers
#if TARGET_OS_IPHONE
#import <TripKit/TKActions.h>
#import <TripKit/TKAlertController.h>
#endif

// Headers
#import <TripKit/TKTripKit.h>
#import <TripKit/TKConstants.h>

// Core Data model classes
#import <TripKit/TripRequest.h>
#import <TripKit/TripGroup.h>
#import <TripKit/Trip.h>
#import <TripKit/DLSEntry.h>
#import <TripKit/SegmentReference.h>
#import <TripKit/Service.h>
#import <TripKit/Vehicle.h>
#import <TripKit/Alert.h>

// Non-core data model classes
#import <TripKit/TKSegmentBuilder.h>

// Helpers
#import <TripKit/NSManagedObject+TKPersistence.h>

// Classification
#import <TripKit/TripRequest+Classify.h>
#import <TripKit/TKTripClassifier.h>

// Routing
#import <TripKit/TKSettings.h>
#import <TripKit/TKCoreDataParserHelper.h>
#import <TripKit/TKRoutingParser.h>
#import <TripKit/TKRouter.h>
#import <TripKit/TKBuzzRealTime.h>
#import <TripKit/TKBuzzInfoProvider.h>

// Search
#import <TripKit/TKAutocompletionResult.h>
#import <TripKit/TKSkedGoGeocoder.h>
#import <TripKit/TKFoursquareGeocoder.h>
#import <TripKit/TKRegionAutocompleter.h>

// Permissions
#import <TripKit/TKCalendarManager.h>
#import <TripKit/TKLocationManager.h>

// Deprecated
#import <TripKit/SGDeprecatedAutocompletionDataProvider.h>
