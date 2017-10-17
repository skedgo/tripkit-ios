//
//  MKPolygon+PolygonFromRectangle.m
//  TripGo
//
//  Created by Adrian Schönig on 29/08/11.
//  Copyright (c) 2011 SkedGo. All rights reserved.
//

#import "MKPolygon+PolygonFromRectangle.h"

static void fillInPoints(MKMapRect rect, MKMapPoint **pointsOut, NSUInteger *pointsOutLength) {
  NSUInteger c = 0, space = 4;
  MKMapPoint* points = malloc(sizeof(MKMapPoint) * space);
  MKMapPoint topLeft = rect.origin;
  points[c++] = MKMapPointMake(topLeft.x, topLeft.y);
  points[c++] = MKMapPointMake(topLeft.x + rect.size.width, topLeft.y);
  points[c++] = MKMapPointMake(topLeft.x + rect.size.width, topLeft.y + rect.size.height);
  points[c++] = MKMapPointMake(topLeft.x, topLeft.y + rect.size.height);
  
  *pointsOut = points;
  *pointsOutLength = c;
}


@implementation MKPolygon (PolygonFromRectangle)


+ (MKPolygon *)polygonFromRectangle:(MKMapRect)rect {
  MKMapPoint *points = NULL;
  NSUInteger pointsLength = 0;
  
  fillInPoints(rect, &points, &pointsLength);
  MKPolygon *polygon = [MKPolygon polygonWithPoints:points 
                                              count:pointsLength];
  free(points);
  return polygon;
}

+ (MKPolygon *)polygonFromRectangle:(MKMapRect)rect interiorPolygons:(NSArray *)interiors {
  
  MKMapPoint *outerPoints = NULL;
  NSUInteger outerPointsLength = 0;
  
  fillInPoints(rect, &outerPoints, &outerPointsLength);
  MKPolygon *polygon = [MKPolygon polygonWithPoints:outerPoints 
                                              count:outerPointsLength
                                   interiorPolygons:interiors];
  free(outerPoints);
  return polygon;
}


@end
