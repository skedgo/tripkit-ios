//
//  RouteAnnotation.h
//  Tracker
//
//  Created by Adrian Schönig on 13/04/10.
//  Copyright 2010 Adrian Schönig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "TKCrossPlatform.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TKDisplayableRoute;

@interface TKRoutePolyline : MKPolyline

@property(nonatomic, strong) id<TKDisplayableRoute> route;

+ (nullable instancetype)routePolylineForRoute:(id <TKDisplayableRoute>)route;

/**
 @param annotations An array of id<MKAnnotation> objects
 
 @return A geodesic polyline connecting the annotations
 */
+ (nullable MKGeodesicPolyline *)geodesicPolylineForAnnotations:(NSArray<id<MKAnnotation>> *)annotations;

@end

NS_ASSUME_NONNULL_END
