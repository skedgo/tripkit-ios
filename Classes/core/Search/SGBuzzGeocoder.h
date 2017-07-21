//
//  SGBuzzGeocoder.h
//  TripKit
//
//  Created by Adrian Schönig on 24/02/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import "SGBaseGeocoder.h"

#import <MapKit/MapKit.h>

#import "SGAutocompletionDataProvider.h"

@class SVKRegion;

@interface SGBuzzGeocoder : SGBaseGeocoder <SGAutocompletionDataProvider>

@property (nonatomic, strong, nullable) SVKRegion *fallbackRegion;

@end
