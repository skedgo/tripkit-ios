//
//  UIColor+Variations.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 21/02/13.
//
//

#import "UIColor+Variations.h"

@implementation UIColor (Variations)

- (void)extractRed:(CGFloat *)red
						 green:(CGFloat *)green
							blue:(CGFloat *)blue
						 alpha:(CGFloat *)alpha
{
  if ([self respondsToSelector:@selector(getRed:green:blue:alpha:)]) {
    BOOL worked = [self getRed:red green:green blue:blue alpha:alpha];
    
    if (NO == worked) {
      [self getWhite:red alpha:alpha];
      (*green) = (*red);
      (*blue)  = (*red);
    }
    
  } else {
    const CGFloat *components = CGColorGetComponents(self.CGColor);
    if (CGColorGetNumberOfComponents(self.CGColor) == 2) {
      (*red)   = (*green) = (*blue) = components[0];
      (*alpha) = components[1];
    } else {
      (*red)   = components[0];
      (*green) = components[1];
      (*blue)  = components[2];
      (*alpha) = components[3];
    }
  }
}

- (UIColor *)darkerColorByPercentage:(CGFloat)percentToBlack
{
  CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
	[self extractRed:&red green:&green blue:&blue alpha:&alpha];
	
	CGFloat multiplier = (1 - percentToBlack);
	return [UIColor colorWithRed:multiplier * red
												 green:multiplier * green
													blue:multiplier * blue
												 alpha:alpha];
}

- (UIColor *)invert
{
  CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
	[self extractRed:&red green:&green blue:&blue alpha:&alpha];
	
	return [UIColor colorWithRed:1 - red
												 green:1 - green
													blue:1 - blue
												 alpha:alpha];
}

- (BOOL)isDark
{
  CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
	[self extractRed:&red green:&green blue:&blue alpha:&alpha];
	
	return (red + green + blue) * alpha <= 1.75f; // mid-range colours are dark, too
}

@end
