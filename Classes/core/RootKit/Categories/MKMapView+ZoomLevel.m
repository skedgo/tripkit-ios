//
//  MKMapView+ZoomLevel.m
//  TripGo
//
//  Created by Adrian Schoenig on 13/02/2015.
//
//

#import "MKMapView+ZoomLevel.h"

@implementation MKMapView (ZoomLevel)

- (NSUInteger)zoomLevel
{
  return (NSInteger) [self zoomLevelOfMapRect:self.visibleMapRect];
}

- (void)setZoomLevel:(NSUInteger)zoomLevel animated:(BOOL)animated
{
  MKMapRect mapRect = [self mapRectForZoomLevel:zoomLevel];
  [self setVisibleMapRect:mapRect animated:animated];
}

#pragma mark - Private helper

- (double)zoomLevelOfMapRect:(MKMapRect) mapRect
{
  return log(mapRect.size.width / self.frame.size.height) / log(2.0) + 1.0;
}

- (MKMapRect)mapRectForZoomLevel:(double)zoomLevel
{
  MKMapPoint center = MKMapPointForCoordinate(self.centerCoordinate);

  double ratio = pow(2, zoomLevel - 1);
  
  CGFloat viewHeight = CGRectGetHeight(self.frame);
  CGFloat viewRatio = CGRectGetWidth(self.frame) / viewHeight;
  double width = viewHeight * ratio;
  double height = width / viewRatio;
  
  return MKMapRectMake(center.x - width / 2, center.y - height / 2, width, height);
}


@end
