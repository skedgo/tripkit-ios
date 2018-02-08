//
//  SGCustomEventRecurrenceRule.m
//  TripKit
//
//  Created by Adrian Schoenig on 26/02/2014.
//
//

#import "SGCustomEventRecurrenceRule.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#endif

#import "TripKit/TripKit-Swift.h"

#import "SGRootKit.h"

@implementation SGCustomEventRecurrenceRule

+ (NSString *)humanReadableRecurrenceRule:(NSString *)recurrenceRule
                           firstDayOfWeek:(WeekdayIndex)firstDayOfWeek
{
  if (! recurrenceRule) {
    return Loc.Never;
  } else if ([recurrenceRule isEqualToString:@"W1111111"]) {
    return NSLocalizedStringFromTableInBundle(@"Everyday", @"Shared", [SGStyleManager bundle], "Everyday in context of repetitions (especially recurring events)");
  } else if ([recurrenceRule isEqualToString:@"W0111110"]) {
    return NSLocalizedStringFromTableInBundle(@"Weekdays", @"Shared", [SGStyleManager bundle], "Every weekday in context of repetitions (especially recurring events)");
  } else if ([recurrenceRule isEqualToString:@"W1000001"]) {
    return NSLocalizedStringFromTableInBundle(@"Weekends", @"Shared", [SGStyleManager bundle], "Every weekend day in context of repetitions (especially recurring events)");
  }
  
  NSIndexSet *weekdays = [self daysOfWeek:recurrenceRule];
  if (weekdays.count == 1) {
    NSString *day = [self longStringForWeekday:[weekdays firstIndex]];
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Every %@", @"Shared", [SGStyleManager bundle], "'Every %day' in context of repetitions (especially recurring events), e.g., 'Every Monday'. (old key: EveryDayFormat)"), day];
  }

  NSMutableString *days = [NSMutableString string];
  // first add everything after 'first day of week' (inclusive)
  [weekdays enumerateIndexesUsingBlock:^(NSUInteger weekday, BOOL *stop) {
#pragma unused(stop) // we need to go till the end
    if (weekday < firstDayOfWeek)
      return;
    if (days.length > 0)
      [days appendString:@" "];
    [days appendString:[self shortStringForWeekday:weekday]];
  }];
  
  // then add everything up to 'first day of week' (exclusive)
  [weekdays enumerateIndexesUsingBlock:^(NSUInteger weekday, BOOL *stop) {
    if (weekday >= firstDayOfWeek) {
      *stop = YES;
      return;
    }
    if (days.length > 0)
      [days appendString:@" "];
    [days appendString:[self shortStringForWeekday:weekday]];
  }];
  
  return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Every %@", @"Shared", [SGStyleManager bundle], @"'Every %day' in context of repetitions (especially recurring events), e.g., 'Every Monday'. (old key: EveryDayFormat)"), days];
}

+ (NSString *)recurrenceRuleFromWeekdays:(NSIndexSet *)weekdays
{
  if (0 == [weekdays count])
    return nil;
  NSMutableString *recurrenceRule = [NSMutableString stringWithString:@"W"];
  for (int i = 1; i <= 7; i++) {
    if ([weekdays containsIndex:i]) {
      [recurrenceRule appendString:@"1"];
    } else {
      [recurrenceRule appendString:@"0"];
    }
  }
  return recurrenceRule;
}

+ (NSIndexSet *)daysOfWeek:(NSString *)recurrenceRule
{
  NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];

  if ('1' == [recurrenceRule characterAtIndex:WeekdayIndex_Sunday]) {
    [indexes addIndex:WeekdayIndex_Sunday];
  }

  if ('1' == [recurrenceRule characterAtIndex:WeekdayIndex_Monday]) {
    [indexes addIndex:WeekdayIndex_Monday];
  }

  if ('1' == [recurrenceRule characterAtIndex:WeekdayIndex_Tuesday]) {
    [indexes addIndex:WeekdayIndex_Tuesday];
  }

  if ('1' == [recurrenceRule characterAtIndex:WeekdayIndex_Wednesday]) {
    [indexes addIndex:WeekdayIndex_Wednesday];
  }

  if ('1' == [recurrenceRule characterAtIndex:WeekdayIndex_Thursday]) {
    [indexes addIndex:WeekdayIndex_Thursday];
  }

  if ('1' == [recurrenceRule characterAtIndex:WeekdayIndex_Friday]) {
    [indexes addIndex:WeekdayIndex_Friday];
  }

  if ('1' == [recurrenceRule characterAtIndex:WeekdayIndex_Saturday]) {
    [indexes addIndex:WeekdayIndex_Saturday];
  }

  return indexes;
}

static NSDateFormatter *sWeekdayDateFormatter = nil;


+ (NSString *)shortStringForWeekday:(NSInteger)weekday
{
	if (nil == sWeekdayDateFormatter) {
		sWeekdayDateFormatter = [[NSDateFormatter alloc] init];
		[sWeekdayDateFormatter setLocale:[NSLocale currentLocale]];
  }
  return [[sWeekdayDateFormatter shortStandaloneWeekdaySymbols] objectAtIndex:weekday - 1];
}

+ (NSString *)longStringForWeekday:(NSInteger)weekday
{
	if (nil == sWeekdayDateFormatter) {
		sWeekdayDateFormatter = [[NSDateFormatter alloc] init];
		[sWeekdayDateFormatter setLocale:[NSLocale currentLocale]];
  }
  return [[sWeekdayDateFormatter standaloneWeekdaySymbols] objectAtIndex:weekday - 1];
}

+ (WeekdayIndex)weekdayFromDate:(NSDate *)date
{
  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  NSDateComponents *weekdayComponents = [gregorian components:NSCalendarUnitWeekday
                                                     fromDate:date];
  return (WeekdayIndex) [weekdayComponents weekday];
}


#pragma mark - Converting to and from EKRecurrenceRule arrays

+ (SGCustomEventRecurrenceRule *)recurrenceRuleFromEKRecurrenceRules:(NSArray *)recurrenceRules
                                                          sampleDate:(NSDate *)sampleDate
{
  if (recurrenceRules.count != 1) {
    return nil; // only supporting single recurrences
  }
  
  EKRecurrenceRule *rule = [recurrenceRules firstObject];

  if (rule.frequency != EKRecurrenceFrequencyWeekly) {
    return nil; // only supporting weekly recurrences
  }
  
  if (rule.interval != 1) {
    return nil; // only supporting recurrence every week
  }

  if (rule.setPositions) {
    return nil; // not supporting set positions ("every 2nd or every last ...")
  }

  NSMutableIndexSet *weekdays = [NSMutableIndexSet indexSet];
  if (rule.daysOfTheWeek) {
    for (EKRecurrenceDayOfWeek *dayOfWeek in rule.daysOfTheWeek) {
      if (dayOfWeek.weekNumber != 0) {
        return nil; // no support for recurring only on special weeks
      }
      [weekdays addIndex:dayOfWeek.dayOfTheWeek];
    }
  } else {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *component = [gregorian components:NSCalendarUnitWeekday
                                               fromDate:sampleDate];
    NSInteger weekday = [component weekday];
    [weekdays addIndex:weekday];
  }
  
  EKRecurrenceEnd *end = rule.recurrenceEnd;
  NSDate *endDate = nil;
  if (end) {
    if (end.endDate) {
      return nil; // no support for count-based ends
    }
    endDate = end.endDate;
  }
  
  NSString *rawRule = [self recurrenceRuleFromWeekdays:weekdays];
  return [self ruleWithRecurrence:rawRule endDate:endDate];
}

+ (NSString *)humanReadableVersionOfEKRecurrenceRules:(NSArray *)recurrenceRules
{
  if (recurrenceRules.count == 0) {
    return nil;
  } else if (recurrenceRules.count > 1) {
    return [Loc Recurrences:recurrenceRules.count];
  }
  
  EKRecurrenceRule *rule = [recurrenceRules firstObject];
  NSString *frequency;
  switch (rule.frequency) {
    case EKRecurrenceFrequencyDaily:
      frequency = NSLocalizedStringFromTableInBundle(@"Repeats daily", @"Shared", [SGStyleManager bundle], "Repeats daily");
      break;
      
    case EKRecurrenceFrequencyWeekly:
      frequency = NSLocalizedStringFromTableInBundle(@"Repeats weekly", @"Shared", [SGStyleManager bundle], "Repeats weekly");
      break;
      
    case EKRecurrenceFrequencyMonthly:
      frequency = NSLocalizedStringFromTableInBundle(@"Repeats monthly", @"Shared", [SGStyleManager bundle], "Repeats monthly");
      break;
      
    case EKRecurrenceFrequencyYearly:
      frequency = NSLocalizedStringFromTableInBundle(@"Repeats yearly", @"Shared", [SGStyleManager bundle], "Repeats yearly");
      break;
  }
  return frequency;
}

+ (EKRecurrenceRule *)EKRecurrenceRuleFromRecurrenceRule:(SGCustomEventRecurrenceRule *)rule
{
  NSMutableArray *weekdaysArray = [NSMutableArray arrayWithCapacity:7];
  NSIndexSet *weekdaysIndices = [self daysOfWeek:rule.recurrence];
  [weekdaysIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
#pragma unused(stop)
    EKRecurrenceDayOfWeek *dayOfWeek = [EKRecurrenceDayOfWeek dayOfWeek:idx];
    [weekdaysArray addObject:dayOfWeek];
  }];

  EKRecurrenceEnd *end = rule.end ? [EKRecurrenceEnd recurrenceEndWithEndDate:rule.end] : nil;
  
  return [[EKRecurrenceRule alloc] initRecurrenceWithFrequency:EKRecurrenceFrequencyWeekly
                                                      interval:1
                                                 daysOfTheWeek:weekdaysArray
                                                daysOfTheMonth:nil
                                               monthsOfTheYear:nil
                                                weeksOfTheYear:nil
                                                 daysOfTheYear:nil
                                                  setPositions:nil
                                                           end:end];
}

#pragma mark - Simple instances to represent rules with end dates

+ (SGCustomEventRecurrenceRule *)ruleWithRecurrence:(NSString *)recurrence
                                            endDate:(NSDate *)end
{
  if (recurrence) {
    SGCustomEventRecurrenceRule *rule = [[SGCustomEventRecurrenceRule alloc] init];
    rule.recurrence = recurrence;
    rule.end = end;
    return rule;
  } else {
    return nil;
  }
}

@end
