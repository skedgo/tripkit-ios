//
//  TKUITripSegmentsView.h
//  TripKit
//
//  Created by Adrian Schoenig on 20/01/2014.
//
//

@import UIKit;

@protocol TKTripSegmentDisplayable;

@interface _TKUITripSegmentsView : UIView

@property (nonatomic, assign) BOOL tiny;

/**
 Whether the trip should be shown as cancelled, i.e., with a line through it
 
 @default `false`
 */
@property (nonatomic, assign) BOOL isCanceled;

/**
Whether to show wheelchair accessibility and inaccessibility icons

 @default `false`
*/
@property (nonatomic, assign) BOOL allowWheelchairIcon;

/**
 This property determines if the transit icon in the view should be color coded.
 */
@property (nonatomic, assign) BOOL colorCodingTransitIcon;

/**
 This color is used for darker texts. In addition, this is also the color which
 will be used to tint the transport mode icons if `colorCodingTransitIcon` is
 set to NO.
 
 @default `UIColor.tkLabelPrimary`
 */
@property (nonatomic, strong, nonnull) UIColor *darkTextColor;

/**
 This color is used on lighter texts. In addition, this is also the color which
 will be used to tint non-PT modes if `colorCodingTransitIcon` is set to YES.
 
 @default `UIColor.tkLabelSecondary`
 */
@property (nonatomic, strong, nonnull) UIColor *lightTextColor;

- (void)configureForSegments:(nonnull NSArray<id<TKTripSegmentDisplayable>> *)segments
              allowSubtitles:(BOOL)allowSubtitles
              allowInfoIcons:(BOOL)allowInfoIcons;

- (void)selectSegmentAtIndex:(NSInteger)index NS_SWIFT_NAME(select(segmentAtIndex:));

- (NSInteger)segmentIndexAtX:(CGFloat)x NS_SWIFT_NAME(segmentIndex(atX:));

// MARK: Helpers

- (void)prepare:(nonnull UIImageView *)imageView
       imageURL:(nonnull NSURL *)imageURL
     asTemplate:(BOOL)asTemplate
    placeholder:(nullable UIImage *)placeholder
     completion:(void (^ __nullable)(BOOL finished)) completion;

- (nonnull UIImageView *)realTimeAccessoryImageAnimated:(BOOL)animated
                                              tintColor:(nonnull UIColor *)tintColor;

- (nullable UIImageView *)accessibilityImageViewForDisplayable:(nonnull id<TKTripSegmentDisplayable>)displayable;

- (nonnull UILabel *)styledLabelWithFrame:(CGRect)frame;

@end

