//
//  RouteAnnotation.h
//  Tracker
//
//  Created by Adrian Schönig on 13/04/10.
//  Copyright 2010 Adrian Schönig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "SGKCrossPlatform.h"

NS_ASSUME_NONNULL_BEGIN

@protocol STKDisplayableRoute <NSObject>
- (NSArray *)routePath; // NSArray of objects that have a coordinate, e.g., <MKAnnotation> or CLLocation
- (nullable SGKColor *)routeColour;
@optional
- (BOOL)showRoute;
- (BOOL)routeIsTravelled;
- (nullable NSArray<NSNumber *> *)routeDashPattern;

@end

@interface STKRoutePolyline : MKPolyline

@property(nonatomic, strong) id<STKDisplayableRoute> route;

+ (nullable instancetype)routePolylineForRoute:(id <STKDisplayableRoute>)route;
+ (nullable instancetype)routePolylineForRoute:(id <STKDisplayableRoute>)route pointsPerTrip:(NSInteger)pointsPerTrip;

/**
 @param annotations An array of id<MKAnnotation> objects
 
 @return A geodesic polyline connecting the annotations
 */
+ (nullable MKGeodesicPolyline *)geodesicPolylineForAnnotations:(NSArray<id<MKAnnotation>> *)annotations;

@end

NS_ASSUME_NONNULL_END
