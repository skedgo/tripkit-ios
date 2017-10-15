//
//  SGMapHelper.m
//  TripKit
//
//  Created by Adrian Schoenig on 13/02/2015.
//
//

#import "SGMapHelper.h"

@implementation SGMapHelper

+ (MKMapRect)mapRectForAnnotations:(NSArray<id<MKAnnotation>> *)annos
{
  MKMapRect mapRect = MKMapRectNull;
  for (id <MKAnnotation> annotation in annos) {
    MKMapPoint mapPoint = MKMapPointForCoordinate([annotation coordinate]);
    MKMapRect newRect = MKMapRectMake(mapPoint.x, mapPoint.y, 1.0, 1.0);
    
    mapRect = MKMapRectUnion(mapRect, newRect);
  }
  return mapRect;
}

@end
