//
//  TKCustomEventRecurrenceRule.h
//  TripKit
//
//  Created by Adrian Schoenig on 26/02/2014.
//
//

#import <Foundation/Foundation.h>

#import <EventKit/EventKit.h>

typedef NS_ENUM(NSInteger, TKWeekdayIndex) {
  TKWeekdayIndex_Sunday = 1,
  TKWeekdayIndex_Monday,
  TKWeekdayIndex_Tuesday,
  TKWeekdayIndex_Wednesday,
  TKWeekdayIndex_Thursday,
  TKWeekdayIndex_Friday,
  TKWeekdayIndex_Saturday,
};

NS_ASSUME_NONNULL_BEGIN

@interface TKCustomEventRecurrenceRule : NSObject

+ (NSString *)humanReadableRecurrenceRule:(NSString *)recurrenceRule
                           firstDayOfWeek:(TKWeekdayIndex)firstDayOfWeek;

+ (nullable NSString *)recurrenceRuleFromWeekdays:(NSIndexSet *)weekdays;

+ (NSIndexSet *)daysOfWeek:(NSString *)recurrenceRule;

+ (NSString *)shortStringForWeekday:(NSInteger)weekday;

+ (NSString *)longStringForWeekday:(NSInteger)weekday;

+ (TKWeekdayIndex)weekdayFromDate:(NSDate *)date;


///-----------------------------------------------------------------------------
/// @name Converting to and from EKRecurrenceRule arrays
///-----------------------------------------------------------------------------

+ (nullable TKCustomEventRecurrenceRule *)recurrenceRuleFromEKRecurrenceRules:(NSArray *)recurrenceRules sampleDate:(NSDate *)sampleDate;

+ (EKRecurrenceRule *)EKRecurrenceRuleFromRecurrenceRule:(TKCustomEventRecurrenceRule *)recurrenceRule;

+ (nullable NSString *)humanReadableVersionOfEKRecurrenceRules:(NSArray *)recurrenceRules;

///-----------------------------------------------------------------------------
/// @name Simple instances to represent rules with end dates
///-----------------------------------------------------------------------------


+ (nullable TKCustomEventRecurrenceRule *)ruleWithRecurrence:(NSString *)recurrence
                                                     endDate:(nullable NSDate *)end;

@property (nonatomic, copy) NSString *recurrence;

@property (nonatomic, strong, nullable) NSDate *end;

@end

NS_ASSUME_NONNULL_END
