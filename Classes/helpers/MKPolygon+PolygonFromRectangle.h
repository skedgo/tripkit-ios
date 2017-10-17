//
//  MKPolygon+PolygonFromRectangle.h
//  TripGo
//
//  Created by Adrian Schönig on 29/08/11.
//  Copyright (c) 2011 SkedGo. All rights reserved.
//

@import MapKit;

NS_ASSUME_NONNULL_BEGIN

@interface MKPolygon (PolygonFromRectangle)

+ (MKPolygon *)polygonFromRectangle:(MKMapRect)rect;
+ (MKPolygon *)polygonFromRectangle:(MKMapRect)rect interiorPolygons:(NSArray *)interiors;

@end

NS_ASSUME_NONNULL_END
