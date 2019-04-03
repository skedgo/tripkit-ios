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

@interface TKUISemaphoreView : MKAnnotationView

@property (nonatomic, readonly) SGSemaphoreLabel label;
@property (nonatomic, readonly) UIImageView *headImageView;
@property (nonatomic, strong) TKObjCDisposeBag *objcDisposeBag;

@property (nonatomic, assign) BOOL tiny;

// Initialisers

- (id)initWithAnnotation:(id<MKAnnotation>)annotation
				 reuseIdentifier:(nullable NSString *)reuseIdentifier
						 withHeading:(CLLocationDirection)heading;

// Helpers

- (void)setHeadWithImage:(nullable UIImage *)image
                imageURL:(nullable NSURL *)imageURL
         imageIsTemplate:(BOOL)asTemplate
              forBearing:(nullable NSNumber *)bearing
							andHeading:(CLLocationDirection)heading
                   inRed:(BOOL)red
						canFlipImage:(BOOL)canFlipImage;

- (void)setFrequency:(NSInteger)frequency
              onSide:(SGSemaphoreLabel)side;

- (void)flipHead:(BOOL)isFlipped;

- (void)setTime:(nullable NSDate *)timeStamp
     isRealTime:(BOOL)isRealTime
		 inTimeZone:(NSTimeZone *)timezone
         onSide:(SGSemaphoreLabel)side;

@end

NS_ASSUME_NONNULL_END
