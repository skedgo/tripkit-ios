//
//  MKMapView+AttributionView.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 6/03/13.
//
//

#import "MKMapView+AttributionView.h"

@implementation MKMapView (AttributionView)

- (UIView *)attributionView
{
	for (UIView *subview in self.subviews) {
		if ([subview isKindOfClass:[UILabel class]]) {
			return subview;
		}
	}
	return nil;
}

@end
