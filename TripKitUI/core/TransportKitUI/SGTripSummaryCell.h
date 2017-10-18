//
//  SGTripSummaryCell.h
//  TripKit
//
//  Created by Adrian Schoenig on 20/01/2014.
//
//

#import <UIKit/UIKit.h>

#ifndef TK_NO_MODULE

#else
#import "STKTransportKit.h"
#endif

NS_ASSUME_NONNULL_BEGIN

typedef void(^SGTripSummaryCellActionBlock)(UIControl *sender);

@class SGTripSegmentsView, SGLabel, SGButton, SGObjCDisposeBag;
@protocol STKTrip;

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
@property (nonatomic, assign) BOOL preferNoPaddings;

@property (nullable, nonatomic, strong) NSTimeZone *relativeTimeZone;

@property (nullable, nonatomic, strong) UIColor *preferredTintColor UI_APPEARANCE_SELECTOR;

+ (UINib *)nib;
+ (UINib *)nanoNib;

// Internals
@property (nullable, nonatomic, copy) SGTripSummaryCellActionBlock _actionBlock;
@property (nullable, nonatomic, copy) NSString *_tripAccessibilityLabel;
@property (null_resettable, nonatomic, weak) id<STKTrip> _trip;
@property (nonatomic, strong) SGObjCDisposeBag *_objcDisposeBag;

- (void)_addTimeStringForDeparture:(NSDate *)departure
                           arrival:(NSDate *)arrival
                 departureTimeZone:(NSTimeZone *)departureTimeZone
                   arrivalTimeZone:(NSTimeZone *)arrivalTimeZone
                   focusOnDuration:(BOOL)durationFirst
               queryIsArriveBefore:(BOOL)arriveBefore;

- (void)_updateTimeStringForDeparture:(NSDate *)departure
                              arrival:(NSDate *)arrival;

- (void)_addCosts:(NSDictionary *)costDict;

@end

NS_ASSUME_NONNULL_END
