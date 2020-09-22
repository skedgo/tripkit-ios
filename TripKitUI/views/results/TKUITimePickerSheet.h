//
//  TKUITimePickerSheet.h
//  TripKit
//
//  Created by Adrian Schoenig on 24/09/13.
//
//

@import UIKit;

@import TripKit;

#import <TripKitUI/TKUISheet.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^SGTimePickerSelectAction)(TKTimeType type, NSDate *date);

@class TKUITimePickerSheet;

@protocol TKUITimePickerSheetDelegate <NSObject>

@optional

- (void)timePicker:(TKUITimePickerSheet *)pickerSheet
        pickedDate:(NSDate *)date
           forType:(TKTimeType)type;

- (void)timePickerRequestsResign:(TKUITimePickerSheet *)pickerSheet;

@end


@interface TKUITimePickerSheet : TKUISheet

@property (copy, nonatomic, nullable) SGTimePickerSelectAction selectAction;
@property (weak, nonatomic, nullable) id<TKUITimePickerSheetDelegate> delegate;

// interface elements
@property (weak, nonatomic, null_resettable) IBOutlet UIDatePicker *timePicker;

- (NSDate *)selectedDate;
- (TKTimeType)selectedTimeType;

- (instancetype)initWithTime:(nullable NSDate *)time
                    timeType:(TKTimeType)timeType
                    timeZone:(NSTimeZone *)timeZone;

- (instancetype)initWithTime:(nullable NSDate *)time
                    timeZone:(NSTimeZone *)timeZone;

- (instancetype)initWithDate:(nullable NSDate *)time
                    timeZone:(NSTimeZone *)timeZone;

- (IBAction)timePickerChanged:(id)sender;

@end

NS_ASSUME_NONNULL_END
