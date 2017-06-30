//
//  SGTripSummaryCell.h
//  TripGo
//
//  Created by Adrian Schoenig on 20/01/2014.
//
//

#import <UIKit/UIKit.h>

#ifndef TK_NO_FRAMEWORKS

#else
#import "STKTransportKit.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@protocol STKTrip;

typedef void(^SGTripSummaryCellActionBlock)(UIControl *sender);

@class SGTripSegmentsView, SGLabel, SGButton;

@interface SGTripSummaryCell : UITableViewCell

@property (nullable, weak, nonatomic) IBOutlet UIView *wrapper;
@property (nullable, weak, nonatomic) IBOutlet SGLabel *mainLabel;
@property (nullable, weak, nonatomic) IBOutlet SGLabel *costsLabel;
@property (nullable, weak, nonatomic) IBOutlet SGTripSegmentsView *segmentView;
@property (nullable, weak, nonatomic) IBOutlet UIView *lineView;
@property (nullable, weak, nonatomic) IBOutlet SGButton *actionButton;
@property (nullable, weak, nonatomic) IBOutlet UIImageView *tickView;
@property (nullable, weak, nonatomic) IBOutlet UIImageView *alertView;

@property (nonatomic, assign) BOOL showTickIcon;
@property (nonatomic, assign) BOOL showAlertIcon;
@property (nonatomic, assign) BOOL showCosts;
@property (nonatomic, assign) BOOL allowWheelchairIcon;
@property (nonatomic, assign) BOOL simpleTimes;
@property (nullable, nonatomic, strong) NSTimeZone *relativeTimeZone;

@property (nullable, nonatomic, strong) UIColor *preferredTintColor UI_APPEARANCE_SELECTOR;

+ (UINib *)nib;
+ (UINib *)nanoNib;

- (void)configureForTrip:(id<STKTrip>)trip;

- (void)configureForTrip:(id<STKTrip>)trip
               highlight:(/*STKTripCostType*/ NSInteger)costType
             actionTitle:(nullable NSString *)actionTitle
             actionBlock:(nullable SGTripSummaryCellActionBlock)actionBlock;


- (void)configureForTrip:(id<STKTrip>)trip
               highlight:(/*STKTripCostType*/ NSInteger)costType
                   faded:(BOOL)faded
             actionTitle:(nullable NSString *)actionTitle
             actionBlock:(nullable SGTripSummaryCellActionBlock)actionBlock;

- (void)configureForNanoTrip:(id<STKTrip>)trip
                   highlight:(/*STKTripCostType*/ NSInteger)costType;

- (void)updateForTrip:(id<STKTrip>)trip
            highlight:(/*STKTripCostType*/ NSInteger)costType;

- (void)adjustToFillContentView;
- (void)adjustToFillContentViewWidth;

@end

NS_ASSUME_NONNULL_END
