//
//  VehicleAnnotationView.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 29/11/12.
//
//

#import "VehicleAnnotationView.h"

@import QuartzCore;
@import AFNetworking; // ImageView category

@import SGCoreKit;
@import SGCoreUIKit;

#ifndef TK_NO_FRAMEWORKS
@import TripKit;
#else
#import "TripKit.h"
#import <TripKit/TripKit-Swift.h>
#endif

#import "VehicleView.h"

@interface VehicleAnnotationView ()

@property (nonatomic, weak) VehicleView *vehicleShape;
@property (nonatomic, weak) UIImageView *vehicleImageView;
@property (nonatomic, weak) UILabel *label;
@property (nonatomic, weak) UIView *wrapper;

@end

@implementation VehicleAnnotationView

- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
	if (self) {
		[self updateForAnnotation:annotation];
	}
	return self;
}

- (void)setAnnotation:(id<MKAnnotation>)annotation
{
	[super setAnnotation:annotation];
	
	[self updateForAnnotation:annotation];
}

- (void)updateForAnnotation:(id<MKAnnotation>)annotation
{
	[self removeAllSubviews];
	if (annotation == nil)
		return; // happens on getting removed
	
	Vehicle *vehicle = (Vehicle *)annotation;
	
	self.calloutOffset = CGPointMake(0, 10);
	self.frame = CGRectMake(0, 0, 44, 44);
	self.backgroundColor = [UIColor clearColor];
	self.opaque = NO;
	
	self.showDot = NO;
	
	// the wrapper
	UIView *wrapper = [[UIView alloc] initWithFrame:self.frame];
	wrapper.backgroundColor = [UIColor clearColor];
	wrapper.opaque = NO;
	
#define VEHICLE_WIDTH  30
#define VEHICLE_HEIGHT 15
	CGRect vehicleRect = CGRectMake((self.frame.size.width - VEHICLE_WIDTH) / 2, (self.frame.size.height - VEHICLE_HEIGHT) / 2, VEHICLE_WIDTH, VEHICLE_HEIGHT);
	UIColor *serviceColor = [vehicle serviceColor];
	if (nil == serviceColor) {
		serviceColor = [UIColor blackColor];
	}
  
  UIView *vehicleView = nil;
  if (vehicle.icon) {
    NSURL *URL = [SVKServer imageURLForIconFileNamePart:vehicle.icon
                                             ofIconType:SGStyleModeIconTypeVehicle];
    if (URL) {
      UIImageView *vehicleImageView = [[UIImageView alloc] initWithFrame:vehicleRect];
      vehicleImageView.contentMode = UIViewContentModeScaleAspectFit;
      [vehicleImageView setImageWithURL:URL];
      self.vehicleImageView = vehicleImageView;
      vehicleView = vehicleImageView;
    }
  }
  if (!vehicleView) {
    VehicleView *vehicleShape = [[VehicleView alloc] initWithFrame:vehicleRect color:serviceColor];
    self.vehicleShape = vehicleShape;
    vehicleView = vehicleShape;
  }
  [wrapper addSubview:vehicleView];
  vehicleView.alpha = vehicle.displayAsPrimary ? 1 : 0.66f;

  
	CGRect rect = CGRectInset(vehicleRect, 2, 2);
	rect.size.width -= rect.size.height / 2;
	UILabel *label = [[UILabel alloc] initWithFrame:rect];
	label.text = [vehicle serviceNumber];
	label.backgroundColor = [UIColor clearColor];
	label.opaque = NO;
	label.textAlignment = NSTextAlignmentCenter;
	label.textColor = [self textColorForBackground:serviceColor];
	label.font = [SGStyleManager systemFontWithSize:10];
	label.adjustsFontSizeToFitWidth = YES;
	label.minimumScaleFactor = 0.75;
	[wrapper addSubview:label];
	self.label = label;
	
	[self addSubview:wrapper];
	self.wrapper = wrapper;
	
	// rotate it
	[self rotateVehicleForBearing:vehicle.bearing.floatValue];
}

- (void)rotateVehicleForBearing:(CLLocationDirection)bearing
{
	[self.vehicleShape setNeedsDisplay];
  [self.vehicleImageView setNeedsDisplay];
	
	// rotate the wrapper
	[self.wrapper rotateForBearing:(CGFloat) bearing];
	
	// flip the label
	if (bearing > 180) {
		self.label.transform = CGAffineTransformMakeRotation((CGFloat) M_PI);
	} else {
		self.label.transform = CGAffineTransformIdentity;
	}
}

- (void)rotateVehicleForHeading:(CLLocationDirection)heading andBearing:(CLLocationDirection)bearing
{
	[self rotateVehicleForBearing:bearing - heading];
}

- (void)updateForAge:(CGFloat)ageFactor
{
	self.wrapper.alpha = 1 - ageFactor;
	
	if (ageFactor > 0.9 ) {
		if (self.delayBetweenPulseCycles != INFINITY) {
			self.delayBetweenPulseCycles = INFINITY;
			[self setNeedsLayout];
		}
	} else {
		if (self.delayBetweenPulseCycles == INFINITY) {
			self.delayBetweenPulseCycles = 1;
			[self setNeedsLayout];
		}
	}
}

- (UIColor *)textColorForBackground:(UIColor *)backgroundColor
{
	CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
	[backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
	if ((red + green + blue) * alpha / 3 < 0.5) {
		return [UIColor whiteColor];
	} else {
		return [UIColor blackColor];
	}
}

@end
