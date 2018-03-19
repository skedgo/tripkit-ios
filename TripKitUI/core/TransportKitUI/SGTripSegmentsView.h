//
//  SGTripSegmentsView.h
//  TripKit
//
//  Created by Adrian Schoenig on 20/01/2014.
//
//

@import UIKit;

#ifndef TK_NO_MODULE

#endif

@protocol STKTripSegmentDisplayable;

@interface SGTripSegmentsView : UIView

@property (nonatomic, strong) UIColor *textColor;

@property (nonatomic, assign) BOOL tiny;

@property (nonatomic, assign) BOOL allowWheelchairIcon;

/**
 This property determines if the transit icon in the view should be color coded.
 */
@property (nonatomic, assign) BOOL colorCodingTransitIcon;

/**
 This color is used for darker texts. In addition, this is also the color which
 will be used to tint the transport mode icons if `colorCodingTransitIcon` is
 set to NO. If value is nil, then black is used.
 */
@property (nonatomic, strong, nullable) UIColor *darkTextColor;

/**
 This color is used on lighter texts. In addition, this is also the color which
 will be used to tint non-PT modes if `colorCodingTransitIcon` is set to YES. If
 value is nil, then light grey with value 148/255 is used.
 */
@property (nonatomic, strong, nullable) UIColor *lightTextColor;

- (void)configureForSegments:(NSArray<id<STKTripSegmentDisplayable>> *)segments
              allowSubtitles:(BOOL)allowSubtitles
              allowInfoIcons:(BOOL)allowInfoIcons;

@end

