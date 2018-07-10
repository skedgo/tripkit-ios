//
//  MKMapView+ZoomToAnnotations.m
//  TripKit
//
//  Created by Adrian Schönig on 24/02/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import "MKMapView+ZoomToAnnotations.h"

@interface SGMapHelper : NSObject

+ (MKMapRect)mapRectForAnnotations:(NSArray<id<MKAnnotation>> *)annos;

@end

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

@implementation MKMapView(ZoomToAnnotations)

- (void)zoomToAnnotations:(NSArray *)annos
              edgePadding:(UIEdgeInsets)insets
								 animated:(BOOL)animated
{
  MKMapRect mapRect = [SGMapHelper mapRectForAnnotations:annos];
  
  // Extra padding to not have annotations at edge
  insets.left   = insets.left + 80;
  insets.right  = insets.right + 80;
  insets.top    = insets.top + 80;
  insets.bottom = insets.bottom + 80;
  
  // Zoom out a fair bit to show neighbourhood by default
  if (mapRect.size.height < 10000 || mapRect.size.width < 10000) {
    mapRect = MKMapRectInset(mapRect, -5000, -5000);
  }
  
  [self setVisibleMapRect:mapRect edgePadding:insets animated:animated];
}

- (void)zoomAnnotations:(NSArray *)annos 
      toLowerProportion:(CGFloat)lowerMultiplier
               animated:(BOOL)animated
{
  CGRect originalFrame = self.frame;
  
  // zoom the lower lect to the appointments
  CGRect lowerRect = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height * lowerMultiplier);
  self.frame = lowerRect;
  [self zoomToAnnotations:annos edgePadding:UIEdgeInsetsZero animated:NO];
  MKMapRect lowerMapRect = self.visibleMapRect;
  
  // take the new map rect
  self.frame = originalFrame;
  double newHeight = lowerMapRect.size.height / lowerMultiplier;
  MKMapRect paddingRect = MKMapRectMake(lowerMapRect.origin.x, lowerMapRect.origin.y - newHeight + lowerMapRect.size.height, lowerMapRect.size.width, newHeight);
	MKCoordinateRegion region = MKCoordinateRegionForMapRect(paddingRect);
	[self setRegion:region animated:animated];
}

- (BOOL)visibleMapContainsAll:(NSArray *)annos
{
	MKMapRect visibleRect = self.visibleMapRect;
	for (id<MKAnnotation> annotation in annos) {
		if (!MKMapRectContainsPoint(visibleRect, MKMapPointForCoordinate(annotation.coordinate)))
			return NO;
	}
	return YES;
}

- (BOOL)visibleMapContainsAny:(NSArray *)annos
{
  MKMapRect visibleRect = self.visibleMapRect;
  for (id<MKAnnotation> annotation in annos) {
    if (MKMapRectContainsPoint(visibleRect, MKMapPointForCoordinate(annotation.coordinate)))
      return YES;
  }
  return NO;
}

@end
