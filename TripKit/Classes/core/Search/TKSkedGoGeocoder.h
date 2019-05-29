//
//  TKSkedGoGeocoder.h
//  TripKit
//
//  Created by Adrian Schönig on 24/02/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import <MapKit/MapKit.h>

#import "SGDeprecatedAutocompletionDataProvider.h"
#import "SGDeprecatedGeocoder.h"

@class TKRegion;

NS_ASSUME_NONNULL_BEGIN

@interface TKSkedGoGeocoder : NSObject <SGDeprecatedAutocompletionDataProvider, SGDeprecatedGeocoder>

@property (nonatomic, strong, nullable) TKRegion *fallbackRegion;

@end

NS_ASSUME_NONNULL_END
