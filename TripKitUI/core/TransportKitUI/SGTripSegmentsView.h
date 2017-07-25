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

- (void)configureForSegments:(NSArray<id<STKTripSegmentDisplayable>> *)segments
              allowSubtitles:(BOOL)allowSubtitles
              allowInfoIcons:(BOOL)allowInfoIcons;

@end

