//
//  UIColor+Variations.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 21/02/13.
//
//

#import <UIKit/UIKit.h>

@interface UIColor (Variations)

- (void)extractRed:(CGFloat *)red
						 green:(CGFloat *)green
							blue:(CGFloat *)blue
						 alpha:(CGFloat *)alpha;

- (UIColor *)darkerColorByPercentage:(CGFloat)percentToBlack;

- (UIColor *)invert;

- (BOOL)isDark;

@end
