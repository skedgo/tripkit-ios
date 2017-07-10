//
//  MKMapView+ZoomToAnnotations.m
//  TripGo
//
//  Created by Adrian Schönig on 24/02/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import "MKMapView+ZoomToAnnotations.h"

#import "SGMapHelper.h"

@implementation MKMapView(ZoomToAnnotations)

- (void)zoomToAnnotations:(NSArray *)annos
              edgePadding:(UIEdgeInsets)insets
								 animated:(BOOL)animated
{
  MKMapRect mapRect = [SGMapHelper mapRectForAnnotations:annos];
  
  // Extra padping to not have annotations at edge
  insets.left   = insets.left + 80;
  insets.right  = insets.right + 80;
  insets.top    = insets.top + 80;
  insets.bottom = insets.bottom + 80;
  
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
