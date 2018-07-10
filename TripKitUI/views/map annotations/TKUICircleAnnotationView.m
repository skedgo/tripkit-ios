//
//  TKUICircleAnnotationView.m
//  TripKit
//
//  Created by Adrian Schönig on 16/06/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import "TKUICircleAnnotationView.h"

#import "UIColor+Variations.h"

#define kBHCircleSize   12.0
#define kBHSmallFactor    .8 // percentage

@implementation TKUICircleAnnotationView

- (id)initWithAnnotation:(id <MKAnnotation>)annotation 
               drawLarge:(BOOL)large 
         reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
  if (self) {
    CGFloat radius = kBHCircleSize;
    if (! large) radius *= kBHSmallFactor;

    self.isLarge = large;
    self.frame = CGRectMake(0.0f, 0.0f, radius, radius);
    self.opaque = YES;
    self.backgroundColor = [UIColor clearColor];
		self.isFaded = NO;
  }

  return self;
}

- (void)drawRect:(CGRect)rect
{
#pragma unused(rect) // we are inefficient :(

#define LINE_WIDTH 1.5f
	CGFloat lineWidth = LINE_WIDTH * (self.isLarge ? 1 : 0.8f);
	
	// determine the colors
	UIColor *lineColor = self.circleColor;
  if (nil == lineColor)
    lineColor = [UIColor blackColor];
	
	UIColor *borderColor = [lineColor darkerColorByPercentage:0.75];
  
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  // draw circle
  CGFloat lineOffset = lineWidth / 2.0f;
  CGRect  circleRect = CGRectMake(lineOffset, lineOffset, self.bounds.size.width - lineWidth, self.bounds.size.width - lineWidth);

	if (self.isFaded) {
		CGContextSetFillColorWithColor(context, lineColor.CGColor);
	} else {
		CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
	}
  CGContextFillEllipseInRect(context, circleRect);
	CGContextSetLineWidth(context, lineWidth);
	CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
  CGContextStrokeEllipseInRect(context, circleRect);
}
@end
