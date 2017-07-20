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

- (void)rotateForBearing:(CGFloat)bearing;

- (void)updateForMagneticHeading:(CGFloat)heading andBearing:(CGFloat)bearing;

@end
