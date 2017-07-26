//
//  UIView+Helpers.h
//  TripKit
//
//  Created by Adrian Schönig on 23/04/12.
//  Copyright (c) 2012 SkedGo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Helpers)

- (void)removeAllSubviews;

+ (void)addBorderForView:(UIView *)view
									OnSide:(NSString *)side
						 borderWidth:(CGFloat)width
				 backgroundColor:(UIColor *)bgColor
						 shadowColor:(UIColor *)shadowColor
						shadowRadius:(CGFloat)radius;

@end
