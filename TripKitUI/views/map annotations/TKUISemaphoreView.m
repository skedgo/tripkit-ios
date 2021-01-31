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
#endif

#import "TKUISemaphoreView.h"

#import "TKStyleManager+TripKitUI.h"
#import "UIView+BearingRotation.h"

@interface _TKUISemaphoreView ()

@property (nonatomic, strong) UIImageView *timeImageView;

@property (nonatomic, assign) SGSemaphoreLabel label;

@end

@implementation _TKUISemaphoreView

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
	self.tiny = NO;
	
	[self setTimeFlagOnSide:SGSemaphoreLabelDisabled withTime:nil isRealTime:NO atTimeZone:nil orFrequency:nil];
	
  [_headImageView removeFromSuperview];
  self.headImageView = nil;
  
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

- (nullable UIImage *)accessoryImageViewForRealTime:(BOOL)isRealTime
                                      showFrequency:(BOOL)showFrequency {
  return nil;
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
#define SEMAPHORE_HEAD_SIZE 48 // should match Swift
    
    NSInteger frequencyInt = freq.integerValue;
    BOOL showFrequency = (frequencyInt > 0);
    
    // What's the text and how big is it?
    NSString *timeString;
    if (showFrequency) {
      timeString = [TKObjcDateHelper durationStringForMinutes:frequencyInt];
    } else if (time != nil) {
			if (nil == timezone) {
				timezone = [NSTimeZone defaultTimeZone];
			}
			timeString = [TKStyleManager timeString:time forTimeZone:timezone];
    } else {
      timeString = @"";
    }
    
    timeLabel.text = timeString;
    CGSize textSize = [timeLabel textRectForBounds:CGRectMake(0, 0, 80.0f, CGFLOAT_MAX)
                            limitedToNumberOfLines:1].size;
    
    // Prepare background
    self.timeImageView = [[UIImageView alloc] initWithImage:self.timeBackgroundImage];
    
    // Determine sizing
    CGFloat timeViewHeight = textSize.height + TIME_LABEL_VERTICAL_PADDING * 2;
    CGFloat timeViewWidth = textSize.width + TIME_LABEL_HEAD_OVERLAP + TIME_LABEL_HORIZONTAL_PADDING * 2;
    CGFloat timeViewX = SGSemaphoreLabelOnLeft == side ? -(textSize.width + TIME_LABEL_HORIZONTAL_PADDING) : TIME_LABEL_HEAD_OVERLAP;
    
    CGFloat timeLabelX = TIME_LABEL_HORIZONTAL_PADDING;
    if (SGSemaphoreLabelOnRight == side) {
      timeLabelX += TIME_LABEL_HEAD_OVERLAP;
    }
    
    // Add image if necessary
    UIImageView *accessoryImageView = [self accessoryImageViewForRealTime:isRealTime showFrequency:showFrequency];
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

@end
