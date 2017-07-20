//
//  MKMapView+ZoomLevel.h
//  TripGo
//
//  Created by Adrian Schoenig on 13/02/2015.
//
//
// You want to pick a zoom level in the 1-20 range. Where 1 is zoomed in. 20 is zoomed out.

#import <MapKit/MapKit.h>

@interface MKMapView (ZoomLevel)

- (NSUInteger)zoomLevel;

- (void)setZoomLevel:(NSUInteger)zoomLevel animated:(BOOL)animated;

@end
