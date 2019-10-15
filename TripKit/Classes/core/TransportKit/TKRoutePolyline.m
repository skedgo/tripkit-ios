//
//  RouteAnnotation.m
//  Tracker
//
//  Created by Adrian Schönig on 13/04/10.
//  Copyright 2010 Adrian Schönig. All rights reserved.
//

#import "TKRoutePolyline.h"

#import <TripKit/TripKit-Swift.h>

@implementation TKRoutePolyline

+ (nullable instancetype)routePolylineForRoute:(id <TKDisplayableRoute>)originRoute {
  // create the array of coordinates for the line
  NSArray * pathPoints = [originRoute routePath];
  
  NSUInteger i, j, count = [pathPoints count];
  if (count == 0) {
    return nil;
  }
  
  CLLocationCoordinate2D coords[count];
  for (i = 0, j = 0; i < count && j < count; i += 1, j ++) {
    id obj = [pathPoints objectAtIndex:i];
    if ([obj respondsToSelector:@selector(coordinate)]) {
      coords[j] = [obj coordinate];
    } else {
      ZAssert(false, @"Bad input: Route %@ has bad path point: %@", originRoute, obj);
      return nil;
    }
  }
  coords[count - 1] = [[pathPoints objectAtIndex:count - 1] coordinate];
  
  TKRoutePolyline * routeAnnotation = (TKRoutePolyline *) [self polylineWithCoordinates:coords count:count];
  routeAnnotation.route = originRoute;
  return routeAnnotation;
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
