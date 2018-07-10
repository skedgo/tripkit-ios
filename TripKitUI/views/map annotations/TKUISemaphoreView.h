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

@interface TKUISemaphoreView : MKAnnotationView

@property (nonatomic, readonly) SGSemaphoreLabel label;

@property (nonatomic, assign) BOOL tiny;

// Initialisers

- (id)initWithAnnotation:(id<MKAnnotation>)annotation
				 reuseIdentifier:(NSString *)reuseIdentifier
						 withHeading:(CLLocationDirection)heading;

// Helpers

- (void)updateForAnnotation:(id<MKAnnotation>)annotation;

- (void)updateForAnnotation:(id<MKAnnotation>)annotation
								withHeading:(CLLocationDirection)heading;

- (void)setHeadWithImage:(UIImage *)image
                imageURL:(NSURL *)imageURL
         imageIsTemplate:(BOOL)asTemplate
              forBearing:(NSNumber *)bearing
							andHeading:(CLLocationDirection)heading
						canFlipImage:(BOOL)canFlipImage;

- (void)setFrequency:(NSNumber *)frequency
              onSide:(SGSemaphoreLabel)side;

- (void)setTime:(NSDate *)timeStamp
     isRealTime:(BOOL)isRealTime
		 inTimeZone:(NSTimeZone *)timezone
         onSide:(SGSemaphoreLabel)side;

- (void)updateHeadForMagneticHeading:(CLLocationDirection)heading
													andBearing:(CLLocationDirection)bearing;

@end
