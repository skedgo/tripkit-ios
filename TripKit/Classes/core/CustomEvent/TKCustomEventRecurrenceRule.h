//
//  TKCustomEventRecurrenceRule.h
//  TripKit
//
//  Created by Adrian Schoenig on 26/02/2014.
//
//

#import <Foundation/Foundation.h>

#import <EventKit/EventKit.h>

typedef NS_ENUM(NSInteger, WeekdayIndex) {
  WeekdayIndex_Sunday = 1,
  WeekdayIndex_Monday,
  WeekdayIndex_Tuesday,
  WeekdayIndex_Wednesday,
  WeekdayIndex_Thursday,
  WeekdayIndex_Friday,
  WeekdayIndex_Saturday,
};

NS_ASSUME_NONNULL_BEGIN

@interface TKCustomEventRecurrenceRule : NSObject

+ (NSString *)humanReadableRecurrenceRule:(NSString *)recurrenceRule
                           firstDayOfWeek:(WeekdayIndex)firstDayOfWeek;

+ (nullable NSString *)recurrenceRuleFromWeekdays:(NSIndexSet *)weekdays;

+ (NSIndexSet *)daysOfWeek:(NSString *)recurrenceRule;

+ (NSString *)shortStringForWeekday:(NSInteger)weekday;

+ (NSString *)longStringForWeekday:(NSInteger)weekday;

+ (WeekdayIndex)weekdayFromDate:(NSDate *)date;


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
