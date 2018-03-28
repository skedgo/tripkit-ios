//
//  Geocoder.h
//  TripKit
//
//  Created by Adrian Schönig on 9/02/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <MapKit/MapKit.h>

#import "SGAutocompletionResult.h"

#define kSGErrorGeocoderNothingFound 64720

NS_ASSUME_NONNULL_BEGIN

@class SVKRegion;
@class SGKNamedCoordinate;

typedef void(^SGGeocoderSuccessBlock)(NSString *query, NSArray<SGKNamedCoordinate *> *results);
typedef void(^SGGeocoderFailureBlock)(NSString *query, NSError * __nullable error);

NS_CLASS_DEPRECATED(10_10, 10_13, 2_0, 11_0, "Use TKGeocoding instead")
@protocol SGGeocoder <NSObject>

/**
 Note: The callbacks can be executed on an arbitrary thread. The caller needs to handle this.
 */
- (void)geocodeString:(NSString *)inputString
           nearRegion:(MKMapRect)mapRect
              success:(SGGeocoderSuccessBlock)success
              failure:(nullable SGGeocoderFailureBlock)failure;

@end


@interface SGBaseGeocoder : NSObject <SGGeocoder>

+ (NSError *)errorForNoLocationFoundForInput:(NSString *)input;

+ (id<MKAnnotation>)pickBestFromResults:(NSArray <id<MKAnnotation>> *)results;

+ (void)namedCoordinatesForAutocompletionResults:(NSArray <SGAutocompletionResult *> *)autocompletionResults
                                   usingGeocoder:(nullable id<SGGeocoder>)geocoder
                                      nearRegion:(MKMapRect)mapRect
                                      completion:(void (^)(NSArray <SGKNamedCoordinate *> *))completion;

@end

NS_ASSUME_NONNULL_END
