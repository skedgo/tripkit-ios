//
//  Geocoder.h
//  TripKit
//
//  Created by Adrian Schönig on 9/02/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <MapKit/MapKit.h>

#import "TKAutocompletionResult.h"

#define kSGErrorGeocoderNothingFound 64720

NS_ASSUME_NONNULL_BEGIN

@class TKRegion;
@class TKNamedCoordinate;

typedef void(^SGGeocoderSuccessBlock)(NSString *query, NSArray<TKNamedCoordinate *> *results);
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


@interface TKBaseGeocoder : NSObject <SGGeocoder>

+ (NSError *)errorForNoLocationFoundForInput:(NSString *)input;

+ (id<MKAnnotation>)pickBestFromResults:(NSArray <id<MKAnnotation>> *)results;

+ (void)namedCoordinatesForAutocompletionResults:(NSArray <TKAutocompletionResult *> *)autocompletionResults
                                   usingGeocoder:(nullable id<SGGeocoder>)geocoder
                                      nearRegion:(MKMapRect)mapRect
                                      completion:(void (^)(NSArray <TKNamedCoordinate *> *))completion;

@end

NS_ASSUME_NONNULL_END
