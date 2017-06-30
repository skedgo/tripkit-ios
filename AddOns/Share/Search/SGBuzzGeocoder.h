//
//  SGBuzzGeocoder.h
//  TripGo
//
//  Created by Adrian Schönig on 24/02/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import "SGBaseGeocoder.h"

#import <MapKit/MapKit.h>

#import "SGAutocompletionDataProvider.h"

@class TKTripKit;

@interface SGBuzzGeocoder : SGBaseGeocoder <SGAutocompletionDataProvider>

@end
