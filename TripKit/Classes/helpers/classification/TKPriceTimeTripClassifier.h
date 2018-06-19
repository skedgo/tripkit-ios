//
//  TKPriceTimeTripClassifier.h
//  TripKit
//
//  Created by Adrian Schoenig on 11/06/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

@import Foundation;
@import CoreGraphics;

#import "TKTripClassifier.h"

typedef NS_ENUM(NSInteger, TKPriceTimeClassification) {
  TKPriceTimeClassification_Cheap = 1 << 0,
  TKPriceTimeClassification_Fast  = 1 << 1,
};

@interface TKPriceTimeTripClassifier : NSObject <TKTripClassifier>

@end
