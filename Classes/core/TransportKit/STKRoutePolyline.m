//
//  RouteAnnotation.m
//  Tracker
//
//  Created by Adrian Schönig on 13/04/10.
//  Copyright 2010 Adrian Schönig. All rights reserved.
//

#import "STKRoutePolyline.h"

#import <TripKit/TripKit-Swift.h>

@implementation STKRoutePolyline

+ (nullable instancetype)routePolylineForRoute:(id <STKDisplayableRoute>)originRoute pointsPerTrip:(NSInteger)pointsPerTrip {
  // create the array of coordinates for the line
  NSArray * pathPoints = [originRoute routePath];
  
  NSUInteger i, j, count = [pathPoints count];
  if (count == 0)
    return nil;
  
  // make sure that pointsPerTrip does not exceed the number of points that we have
  if (pointsPerTrip > (NSInteger)count) {
    pointsPerTrip = count;
  }
  
  NSInteger skipCount = 1;
  NSUInteger coordCount = count;
  if (pointsPerTrip > 1) {
    // adjust skipCount if we requested a limited number of points
    skipCount = count / (pointsPerTrip - 1); // 2 means skip all: start + end
    coordCount = pointsPerTrip;
  }
  
  ZAssert(coordCount > 0, @"'coordCount' needs to be > 0");
  if (coordCount > 0) {
    CLLocationCoordinate2D coords[coordCount];
    for (i = 0, j = 0; i < count && j < coordCount; i += skipCount, j ++) {
			id obj = [pathPoints objectAtIndex:i];
			if ([obj respondsToSelector:@selector(coordinate)]) {
				coords[j] = [obj coordinate];
			} else {
				ZAssert(false, @"Bad input: Route %@ has bad path point: %@", originRoute, obj);
				return nil;
			}
    }
    coords[coordCount - 1] = [[pathPoints objectAtIndex:count - 1] coordinate];
    
    STKRoutePolyline * routeAnnotation = (STKRoutePolyline *) [self polylineWithCoordinates:coords count:coordCount];
    routeAnnotation.route = originRoute;
    
    return routeAnnotation;
  } else {
    return nil;
  }
}

+ (nullable instancetype)routePolylineForRoute:(id <STKDisplayableRoute>)originRoute {
  return [self routePolylineForRoute:originRoute pointsPerTrip:-1];
}

+ (nullable MKGeodesicPolyline *)geodesicPolylineForAnnotations:(NSArray *)annotations
{
  if (annotations.count == 0) {
    return nil;
  }
  
  CLLocationCoordinate2D coordinates[annotations.count];
  for (NSUInteger i = 0; i < annotations.count; i++) {
    id<MKAnnotation> annotation = annotations[i];
    coordinates[i] = [annotation coordinate];
  }
  MKGeodesicPolyline *geodesicPolyline = [MKGeodesicPolyline polylineWithCoordinates:coordinates
                                                                               count:annotations.count];
  return geodesicPolyline;
}

@end
