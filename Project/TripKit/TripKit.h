//
//  TripKit.h
//  TripKit
//
//  Created by Adrian Schoenig on 24/06/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

#if TARGET_OS_IPHONE
@import UIKit;
#else
@import AppKit;
#endif

//! Project version number for TripKit.
FOUNDATION_EXPORT double TripKitVersionNumber;

//! Project version string for TripKit.
FOUNDATION_EXPORT const unsigned char TripKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <TripKit/PublicHeader.h>

#import "TKTripKit.h"
#import "TripKitShare.h"
