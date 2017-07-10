//
//  UIView+Helpers.m
//  TripGo
//
//  Created by Adrian Schönig on 23/04/12.
//  Copyright (c) 2012 SkedGo. All rights reserved.
//

#import "UIView+Helpers.h"

#import <QuartzCore/QuartzCore.h>

@implementation UIView (Helpers)

- (void)removeAllSubviews
{
  NSArray *subviewCopy = [[self subviews] copy];
  for (UIView *view in subviewCopy) {
    [view removeFromSuperview];
  }
}

+ (void)addBorderForView:(UIView *)view
									OnSide:(NSString *)side
						 borderWidth:(CGFloat)width
				 backgroundColor:(UIColor *)bgColor
						 shadowColor:(UIColor *)shadowColor
						shadowRadius:(CGFloat)radius
{
	CALayer *border = [CALayer layer];
	border.backgroundColor = bgColor.CGColor;
	border.name = @"border";
	border.shadowColor = shadowColor.CGColor;
	border.shadowOpacity = 0.5f;
	border.shadowRadius = radius;
	
	if ([side isEqualToString:@"left"]) {
		border.frame = CGRectMake(-1*width, 0, width, view.bounds.size.height);
		border.shadowOffset = CGSizeMake(radius, 0);
		[view.layer addSublayer:border];
		
	} else if ([side isEqualToString:@"right"]) {
		border.frame = CGRectMake(view.bounds.size.width-width , 0, width, view.bounds.size.height);
		border.shadowOffset = CGSizeMake(-1*radius, 0);
		[view.layer addSublayer:border];
		
	} else if ([side isEqualToString:@"bottom"]) {
		border.frame = CGRectMake(0, view.bounds.size.height-width, view.bounds.size.width, width);
		border.shadowOffset = CGSizeMake(0, radius);
		[view.layer addSublayer:border];
		
	} else if ([side isEqualToString:@"top"]) {
		border.frame = CGRectMake(0, -1*width, view.bounds.size.width, width);
		border.shadowOffset = CGSizeMake(0, -1*radius);
		[view.layer addSublayer:border];
	}
}


@end
