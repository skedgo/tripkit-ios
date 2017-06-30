//
//  UIView+Hop.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 11/03/13.
//
//

#import "UIView+Hop.h"

#include <QuartzCore/QuartzCore.h>


@implementation UIView (Hop)

- (void)hop
{
	[self hop:YES];
}

- (void)hopDown
{
	[self hop:NO];
}

#pragma mark - Private helpers


- (void)hop:(BOOL)up
{
	CGFloat animationDuration = 0.75;
	
	// the mover animation
	CAKeyframeAnimation *swapperAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
	CGFloat highPoint = self.center.y + 25 * (up ? -1 : 1);
	CGFloat lowPoint  = self.center.y + 5  * (up ? -1 : 1);
	swapperAnimation.values = @[
														 [NSValue valueWithCGPoint:self.center],
							 [NSValue valueWithCGPoint:CGPointMake(self.center.x, highPoint)],
							 [NSValue valueWithCGPoint:self.center],
							 [NSValue valueWithCGPoint:CGPointMake(self.center.x, lowPoint)],
							 [NSValue valueWithCGPoint:self.center]
							 ];
	swapperAnimation.timingFunctions = @[
																			[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault],
									 [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
									 [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
									 [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]
									 ];
	swapperAnimation.keyTimes = @[
															 @0,
								@0.5,
								@0.75,
								@0.875,
								@1
								];
	
	swapperAnimation.duration = animationDuration;
	
	// greying out the back
	CAKeyframeAnimation *greyAnimation;
	greyAnimation = [CAKeyframeAnimation animationWithKeyPath:@"shadowOpacity"];
	greyAnimation.values = @[ @0, @0.5, @0 ];
	greyAnimation.duration = animationDuration;
	
	// all of them
	CAAnimationGroup *group = [CAAnimationGroup animation];
	group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	group.animations = @[swapperAnimation, greyAnimation];
	group.duration = animationDuration;
	
	[self.layer addAnimation:group forKey:@"hopAnimation"];
}



@end
