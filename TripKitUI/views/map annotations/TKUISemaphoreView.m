//
//  TKUISemaphoreView.m
//  TripKit
//
//  Created by Adrian Schönig on 6/07/12.
//  Copyright (c) 2012 SkedGo. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
#import "TripKitUI/TripKitUI-Swift.h"
#endif

#import "TKUISemaphoreView.h"

#import "TKStyleManager+TripKitUI.h"
#import "UIView+BearingRotation.h"

@interface TKUISemaphoreView ()

@property (nonatomic, strong) UIImageView *headImageView;
@property (nonatomic, strong) UIImageView *modeImageView;
@property (nonatomic, strong) UIImageView *timeImageView;
@property (nonatomic, strong) UIImageView *shadowImageView;
@property (nonatomic, strong) UIView *wrapper;

@property (nonatomic, assign) SGSemaphoreLabel label;
@property (nonatomic, assign) BOOL isFlipped;
@property (nonatomic, strong) id observationToken;

@end

@implementation TKUISemaphoreView

- (void)dealloc
{
  self.observationToken = nil;
}

- (id)initWithAnnotation:(id<MKAnnotation>)annotation
         reuseIdentifier:(NSString *)reuseIdentifier
{
  return [self initWithAnnotation:annotation
                  reuseIdentifier:reuseIdentifier
                      withHeading:0];
}

- (id)initWithAnnotation:(id<MKAnnotation>)annotation
				 reuseIdentifier:(NSString *)reuseIdentifier
						 withHeading:(CLLocationDirection)heading
{
  self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
  if (self) {
    // Initialisation

#define SEMAPHORE_HEAD_SIZE         48 // size of the head images
#define SEMAPHORE_WIDTH             SEMAPHORE_HEAD_SIZE
#define SEMAPHORE_HEIGHT            58 // bottom of semaphore to top of head
#define SEMAPHORE_BASE_HEAD_OVERLAP 18
    
    self.frame = CGRectMake(0, 0, SEMAPHORE_WIDTH, SEMAPHORE_HEIGHT);
//    self.centerOffset = CGPointMake(0, self.frame.size.height * -0.5);
		
		self.wrapper = [[UIView alloc] initWithFrame:self.frame];
		self.wrapper.backgroundColor = [UIColor clearColor];
		[self addSubview:self.wrapper];
    
    UIImage *baseImage = [TripKitUIBundle imageNamed:@"map-pin-base"];
    UIImageView *base = [[UIImageView alloc] initWithImage:baseImage];
    CGPoint center = base.center;
    center.x += 16;
    center.y += SEMAPHORE_HEAD_SIZE - SEMAPHORE_BASE_HEAD_OVERLAP;
    base.center = center;
    [self.wrapper addSubview:base];
		
    [self updateForAnnotation:annotation
                  withHeading:heading];

    self.layer.anchorPoint = CGPointMake(0.5f, 1.0f);
  }
  return self;  
}

- (void)setAnnotation:(id<MKAnnotation>)annotation
{
	// stop observing the old
  BOOL didChange = (annotation != self.annotation);
	if (didChange && self.observationToken != nil) {
		self.observationToken = nil;
	}
	
	// set the new
	[super setAnnotation:annotation];
	
	// observe the new
  if (didChange && [TKUISemaphoreView shouldObserve:annotation]) {
    self.observationToken = [self observe:annotation];
	}
}

- (void)setTiny:(BOOL)tiny
{
	if (_tiny == tiny)
		return;
	
	// adjust it
	_tiny = tiny;
	CGAffineTransform transform = self.wrapper.transform;
	if (tiny) {
		CGFloat factor = 0.5;
		self.wrapper.transform = CGAffineTransformScale(transform, factor, factor);
	} else {
		self.wrapper.transform = CGAffineTransformIdentity;
	}

	CGRect wrapperFrame = self.wrapper.bounds;
	self.wrapper.frame = wrapperFrame;
	
	CGRect mainFrame = self.frame;
	mainFrame.size = wrapperFrame.size;
	self.frame = mainFrame;
}

- (void)prepareForReuse
{
	self.isFlipped = NO;
	self.tiny = NO;
	
  self.observationToken = nil;
  
	[self setTimeFlagOnSide:SGSemaphoreLabelDisabled withTime:nil isRealTime:NO atTimeZone:nil orFrequency:nil];
	
  [_headImageView removeFromSuperview];
  self.headImageView = nil;
  
  [_modeImageView removeFromSuperview];
  self.modeImageView = nil;
  
  [_shadowImageView removeFromSuperview];
  self.shadowImageView = nil;
	
  self.label = SGSemaphoreLabelDisabled;
}

- (void)setFrequency:(NSInteger)frequency
              onSide:(SGSemaphoreLabel)side
{
  [self setTimeFlagOnSide:side withTime:nil isRealTime:NO atTimeZone:nil orFrequency:@(frequency)];
}

- (void)setTime:(NSDate *)timeStamp
     isRealTime:(BOOL)isRealTime
		 inTimeZone:(NSTimeZone *) timezone
         onSide:(SGSemaphoreLabel)side
{
  [self setTimeFlagOnSide:side withTime:timeStamp isRealTime:isRealTime atTimeZone:timezone orFrequency:nil];
}

- (void)flipHead:(BOOL)flip {
  if (flip) {
    if (NO == self.isFlipped) {
      //          float w =  self.frame.size.width / 2 - self.modeImageView.image.size.width / 2;
      //          self.modeImageView.transform = CGAffineTransformMake(-1.0, 0.0, 0.0, 1.0, w, 0.0);
      self.modeImageView.transform = CGAffineTransformScale(self.modeImageView.transform, -1, 1);
      self.isFlipped = YES;
    }
  } else {
    if (self.isFlipped) {
      self.modeImageView.transform = CGAffineTransformIdentity;
      self.isFlipped = NO;
    }
  }
}

#pragma mark - Private methods

- (void)setTimeFlagOnSide:(SGSemaphoreLabel)side
								 withTime:(NSDate *)time
               isRealTime:(BOOL)isRealTime
							 atTimeZone:(NSTimeZone *) timezone
							orFrequency:(NSNumber *)freq
{
  // clean up first if necessary
  [_timeImageView removeFromSuperview];
	
	// disable the label and the side if there's no time supplied
	if (nil == time && nil == freq) {
		side = SGSemaphoreLabelDisabled;
	}
 
  self.label = side;
  
  // adjust the time view
  if (SGSemaphoreLabelDisabled == side) {
    self.timeImageView = nil;
		
  } else {
    UILabel *timeLabel = [[UILabel alloc] init];
    timeLabel.backgroundColor = [UIColor clearColor];
    timeLabel.font = [TKStyleManager systemFontWithSize:14];
    timeLabel.textColor = [UIColor whiteColor];
    
#define TIME_LABEL_VERTICAL_PADDING 4
#define TIME_LABEL_HORIZONTAL_PADDING 10
#define TIME_LABEL_HEAD_OVERLAP 18
    
    NSInteger frequencyInt = freq.integerValue;
    BOOL showFrequency = (frequencyInt > 0);
    
    // What's the text and how big is it?
    NSString *timeString;
    if (showFrequency) {
      timeString = [TKObjcDateHelper durationStringForMinutes:frequencyInt];
    } else {
			if (nil == timezone) {
				timezone = [NSTimeZone defaultTimeZone];
			}
			timeString = [TKStyleManager timeString:time forTimeZone:timezone];
    }
    
    timeLabel.text = timeString;
    CGSize textSize = [timeLabel textRectForBounds:CGRectMake(0, 0, 80.0f, CGFLOAT_MAX)
                            limitedToNumberOfLines:1].size;
    
    // Prepare background
    UIImage *background = [TripKitUIBundle imageNamed:@"map-pin-time"];
    self.timeImageView = [[UIImageView alloc] initWithImage:background];
    
    // Determine sizing
    CGFloat timeViewHeight = textSize.height + TIME_LABEL_VERTICAL_PADDING * 2;
    CGFloat timeViewWidth = textSize.width + TIME_LABEL_HEAD_OVERLAP + TIME_LABEL_HORIZONTAL_PADDING * 2;
    CGFloat timeViewX = SGSemaphoreLabelOnLeft == side ? -(textSize.width + TIME_LABEL_HORIZONTAL_PADDING) : TIME_LABEL_HEAD_OVERLAP;
    
    CGFloat timeLabelX = TIME_LABEL_HORIZONTAL_PADDING;
    if (SGSemaphoreLabelOnRight == side) {
      timeLabelX += TIME_LABEL_HEAD_OVERLAP;
    }
    
    // Add image if necessary
    UIImageView *accessoryImageView = nil;
    
    if (isRealTime) {
      accessoryImageView = [[UIImageView alloc] initAsRealTimeAccessoryImageAnimated:YES
                                                                           tintColor:[UIColor whiteColor]];
    }
    if (accessoryImageView == nil && showFrequency) {
      accessoryImageView = [[UIImageView alloc] initWithImage:[TripKitUIBundle imageNamed:@"repeat_icon"]];
    }
    
    
    if (accessoryImageView) {
      // place it
      CGSize size = accessoryImageView.image.size;
      CGFloat imageViewX = TIME_LABEL_HORIZONTAL_PADDING;
      if (SGSemaphoreLabelOnRight == side) {
        imageViewX += TIME_LABEL_HEAD_OVERLAP;
      }
      CGPoint origin = CGPointMake(imageViewX, (timeViewHeight - size.height) / 2);
      accessoryImageView.frame = CGRectMake(origin.x, origin.y, size.width, size.height);
      
      // make space
      CGFloat space = size.width + TIME_LABEL_HORIZONTAL_PADDING / 3;
      timeViewWidth += space;
      timeLabelX += space;
      if (SGSemaphoreLabelOnLeft == side) {
        timeViewX -= space;
      }
      
      [_timeImageView addSubview:accessoryImageView];
    }
    
    // Set sizing
    timeLabel.frame = CGRectMake(timeLabelX, TIME_LABEL_VERTICAL_PADDING, textSize.width, textSize.height);
    _timeImageView.frame = CGRectMake(timeViewX, (SEMAPHORE_HEAD_SIZE - timeViewHeight) / 2, timeViewWidth, timeViewHeight);
    
    [_timeImageView addSubview:timeLabel];
    [self.wrapper insertSubview:_timeImageView belowSubview:self.headImageView];
  }
}

- (void)setHeadWithImage:(UIImage *)image
                imageURL:(NSURL *)imageURL
         imageIsTemplate:(BOOL)asTemplate
							forBearing:(NSNumber *)bearing
							andHeading:(CLLocationDirection)heading
									 inRed:(BOOL)red
						canFlipImage:(BOOL)canFlipImage
{
  UIImage *headImage;
  UIColor *headTintColor;
  if (nil != bearing) {
    headImage = TKUISemaphoreView.pointerImage;
    headTintColor = TKUISemaphoreView.headTintColor;
  } else {
    if (red) {
      headImage = [TripKitUIBundle imageNamed:@"map-pin-head-red"];
      headTintColor = [UIColor whiteColor];
    } else {
      headImage = TKUISemaphoreView.headImage;
      headTintColor = TKUISemaphoreView.headTintColor;
    }
  }
  
	CLLocationDirection totalBearing = bearing.floatValue - heading;
	
  self.headImageView = [[UIImageView alloc] initWithImage:headImage];
  self.headImageView.frame = CGRectMake((CGRectGetWidth(self.frame) - headImage.size.width) / 2, 0, headImage.size.width, headImage.size.height);
  
  if (nil != bearing) {
		[self.headImageView rotateForBearing:(CGFloat) totalBearing];
  }
  
  [self.wrapper addSubview:self.headImageView];
  
  // Add the mode image
  self.modeImageView = [[UIImageView alloc] initWithImage:image];
  _modeImageView.frame = CGRectMake((CGRectGetWidth(self.frame) - image.size.width) / 2,
                                    (headImage.size.height - image.size.height) / 2,
                                    image.size.width,
                                    image.size.height);
  self.modeImageView.tintColor = headTintColor;
  
  if (imageURL) {
    [self.modeImageView setImageWithURL:imageURL asTemplate:asTemplate placeholderImage:image];
  }
  
	self.isFlipped = NO;
	if (canFlipImage) {
		if (totalBearing > 180.0f || totalBearing < 0) {
			//		float w =  self.frame.size.width / 2 - image.size.width / 2;
			//		self.modeImageView.transform = CGAffineTransformMake(-1.0, 0.0, 0.0, 1.0, w, 0.0);
			self.modeImageView.transform = CGAffineTransformScale(self.modeImageView.transform, -1, 1);
			self.isFlipped = YES;
		}
	}
  
  [self.wrapper addSubview:_modeImageView];
}

@end
