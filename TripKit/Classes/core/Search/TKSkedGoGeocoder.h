//
//  TKSkedGoGeocoder.h
//  TripKit
//
//  Created by Adrian Schönig on 24/02/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import "TKBaseGeocoder.h"

#import <MapKit/MapKit.h>

#import "SGAutocompletionDataProvider.h"

@class TKRegion;

@interface TKSkedGoGeocoder : TKBaseGeocoder <SGAutocompletionDataProvider>

@property (nonatomic, strong, nullable) TKRegion *fallbackRegion;

@end
