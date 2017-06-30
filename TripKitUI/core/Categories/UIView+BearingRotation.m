//
//  UIView+BearingRotation.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 20/11/12.
//
//

#import "UIView+BearingRotation.h"

@implementation UIView (BearingRotation)

+ (CGFloat)bearingToRotation:(CGFloat)bearing
{
  // 0 = North, 90 = East, 180 = South and 270 = West
  CGFloat start = 90.0f;
  CGFloat rotation = -1 * (start - bearing);
  return (rotation * (CGFloat)M_PI) / 180.0f;
}

- (void)rotateForBearing:(CGFloat)bearing
{
	CGFloat rotation = [[self class] bearingToRotation:bearing];
	self.transform = CGAffineTransformMakeRotation(rotation);
}

- (void)updateForMagneticHeading:(CGFloat)heading andBearing:(CGFloat)bearing
{
	[self rotateForBearing:bearing - heading];
}

@end
