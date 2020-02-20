//
//  SGDeprecatedGeocoder.h
//  TripKit
//
//  Created by Adrian Schönig on 17.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

@import MapKit;

@class TKNamedCoordinate;

NS_ASSUME_NONNULL_BEGIN

typedef void(^SGGeocoderSuccessBlock)(NSString *query, NSArray<TKNamedCoordinate *> *results);

typedef void(^SGGeocoderFailureBlock)(NSString *query, NSError * __nullable error);

@protocol SGDeprecatedGeocoder
  
- (void)geocodeString:(NSString *)inputString
           nearRegion:(MKMapRect)mapRect
              success:(SGGeocoderSuccessBlock)success
              failure:(nullable SGGeocoderFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
