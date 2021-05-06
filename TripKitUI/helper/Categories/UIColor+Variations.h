//
//  UIColor+Variations.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 21/02/13.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (Variations)

- (void)extractRed:(CGFloat *)red
						 green:(CGFloat *)green
							blue:(CGFloat *)blue
						 alpha:(CGFloat *)alpha;

- (UIColor *)darkerColorByPercentage:(CGFloat)percentToBlack;

- (BOOL)isDark;

@end

NS_ASSUME_NONNULL_END
