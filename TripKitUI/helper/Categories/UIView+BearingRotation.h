//
//  UIView+BearingRotation.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 20/11/12.
//
//

#import <UIKit/UIKit.h>

@interface UIView (BearingRotation)

+ (CGFloat)bearingToRotation:(CGFloat)bearing;

- (void)rotateForBearing:(CGFloat)bearing NS_SWIFT_NAME(rotate(bearing:)); 

- (void)updateForMagneticHeading:(CGFloat)heading andBearing:(CGFloat)bearing NS_SWIFT_NAME(update(magneticHeading:bearing:));

@end
