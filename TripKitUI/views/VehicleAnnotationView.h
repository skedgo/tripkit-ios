//
//  VehicleAnnotationView.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 29/11/12.
//
//

@import MapKit;

@import SGPulsingAnnotationView;

@class VehicleView;

@interface VehicleAnnotationView : SVPulsingAnnotationView

- (void)rotateVehicleForBearing:(CLLocationDirection)bearing;
- (void)rotateVehicleForHeading:(CLLocationDirection)heading andBearing:(CLLocationDirection)bearing;

- (void)updateForAge:(CGFloat)ageFactor;

@end
