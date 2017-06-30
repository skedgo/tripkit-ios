//
//  SGPolylineRenderer.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 01/08/13.
//
//

#import "SGPolylineRenderer.h"

#import "UIColor+Variations.h"

@implementation SGPolylineRenderer

- (id)initWithPolyline:(MKPolyline *)polyline
{
  self = [super initWithPolyline:polyline];
  self.lineWidth      = 12.f;
  self.lineJoin				= kCGLineJoinRound;
  self.lineCap				= kCGLineCapSquare;
  self.alpha          = 1.0f;
  
  self.borderMultiplier = 16/12.f;
  
  return self;
}

- (void)setStrokeColor:(UIColor *)strokeColor
{
  [super setStrokeColor:strokeColor];
  
  self.borderColor = [self darkerColorThan:strokeColor byPercentage:0.50f];
}

- (UIColor *)darkerColorThan:(UIColor *)color byPercentage:(CGFloat)percentToBlack
{
  CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
  [color extractRed:&red green:&green blue:&blue alpha:&alpha];
  
  CGFloat multiplier = (1 - percentToBlack);
  return [UIColor colorWithRed:multiplier * red
                         green:multiplier * green
                          blue:multiplier * blue
                         alpha:alpha];
}


@end
