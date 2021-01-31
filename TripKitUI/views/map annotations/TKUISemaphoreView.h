//
//  TKUISemaphoreView.h
//  TripKit
//
//  Created by Adrian Schönig on 6/07/12.
//  Copyright (c) 2012 SkedGo. All rights reserved.
//

@import MapKit;

#ifdef TK_NO_MODULE
#import "TripKit.h"
#else
@import TripKit;
#endif

typedef NS_ENUM(NSInteger, SGSemaphoreLabel) {
  SGSemaphoreLabelDisabled,
  SGSemaphoreLabelOnLeft,
  SGSemaphoreLabelOnRight
};

NS_ASSUME_NONNULL_BEGIN

@interface _TKUISemaphoreView : MKAnnotationView

@property (nonatomic, strong) UIView *wrapper;
@property (nonatomic, readonly) SGSemaphoreLabel label;
@property (nonatomic, strong, nullable) UIImageView *headImageView;

// Mark configuration

@property (nonatomic, assign) BOOL tiny;

@property (nonatomic, readonly, nullable) UIImage *timeBackgroundImage;

- (nullable UIImageView *)accessoryImageViewForRealTime:(BOOL)isRealTime
                                          showFrequency:(BOOL)showFrequency;

// Helpers

- (void)setFrequency:(NSInteger)frequency
              onSide:(SGSemaphoreLabel)side;

- (void)setTime:(nullable NSDate *)timeStamp
     isRealTime:(BOOL)isRealTime
		 inTimeZone:(NSTimeZone *)timezone
         onSide:(SGSemaphoreLabel)side;

@end

NS_ASSUME_NONNULL_END
