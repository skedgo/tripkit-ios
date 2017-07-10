//
//  VehicleView.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 29/11/12.
//
//

#import "VehicleView.h"

#import "UIColor+Variations.h"


@interface VehicleView ()

@property (nonatomic, assign) CGFloat red;
@property (nonatomic, assign) CGFloat green;
@property (nonatomic, assign) CGFloat blue;
@property (nonatomic, assign) CGFloat alpha;

@end

@implementation VehicleView

- (id)initWithFrame:(CGRect)frame
							color:(UIColor *)color
{
	self = [super initWithFrame:frame];
	if (self) {
		// Initialization code
    [self breakColorIntoComponents:color];
    
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)setColor:(UIColor *)color
{
  _color = color;
  [self breakColorIntoComponents:color];
  [self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
	// Drawing code
  CGContextRef context = UIGraphicsGetCurrentContext();
  
	CGContextSetRGBStrokeColor(context, 1, 1, 1, 1); // the stroke is white
	CGContextSetLineWidth(context, 2);
	CGContextSetRGBFillColor(context, self.red, self.green, self.blue, self.alpha);
	
	// draw the shape
	CGFloat minX = CGRectGetMinX(rect);
	CGFloat maxX = CGRectGetMaxX(rect);
	CGFloat minY = CGRectGetMinY(rect);
	CGFloat midY = CGRectGetMidY(rect);
	CGFloat maxY = CGRectGetMaxY(rect);
	
	CGFloat midmidX = maxX - midY;
	
	CGContextMoveToPoint(context, minX, minY);
	CGContextAddLineToPoint(context, midmidX, minY);
	CGContextAddLineToPoint(context, maxX, midY);
	CGContextAddLineToPoint(context, midmidX, maxY);
	CGContextAddLineToPoint(context, minX, maxY);
	CGContextAddLineToPoint(context, minX, minY);
	CGContextClosePath(context);
	
	// draw it
	CGContextDrawPath(context, kCGPathFillStroke);
	CGContextFillPath(context);
	CGContextStrokePath(context);
}

- (void)breakColorIntoComponents:(UIColor *)color
{
  CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
  [color extractRed:&red green:&green blue:&blue alpha:&alpha];
  self.red = red;
  self.green = green;
  self.blue = blue;
  self.alpha = alpha;
}

@end
