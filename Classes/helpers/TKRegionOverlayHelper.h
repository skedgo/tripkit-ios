//
//  TKRegionOverlayHelper.h
//  TripKit
//
//  Created by Adrian Schoenig on 15/05/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

@import Foundation;
@import MapKit;

NS_ASSUME_NONNULL_BEGIN

@interface TKRegionOverlayHelper : NSObject

+ (TKRegionOverlayHelper *)sharedInstance;

- (void)clearCache;

- (void)regionsPolygon:(void(^)(MKPolygon * _Nullable polygon))completion;

+ (NSURL *)cacheURL;

@end

NS_ASSUME_NONNULL_END
