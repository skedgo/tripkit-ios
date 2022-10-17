//
//  TripKit.h
//  TripKit
//
//  Created by Adrian Schoenig on 24/06/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>

//! Project version number for TripKit.
/// :nodoc:
FOUNDATION_EXPORT double TripKitVersionNumber;

//! Project version string for TripKit.
/// :nodoc:
FOUNDATION_EXPORT const unsigned char TripKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <TripKit/PublicHeader.h>

// Dependencies

#import "TKTripKit.h"

// Basics
#import "TKEnums.h"
#import "TKConfig.h"
#import "TKCrossPlatform.h"

// Server logic
#import "TKAutocompletionResult.h"

// Helpers
#import "NSManagedObject+TKPersistence.h"
#import "NSUserDefaults+SharedDefaults.h"

#import "TKStyleManager.h"

// Permissions
#import "TKLocationManager.h"

// UI
#if TARGET_OS_IPHONE
#import "TKStyleManager+UIKit.h"
#import "UIFont+CustomFonts.h"
#endif
