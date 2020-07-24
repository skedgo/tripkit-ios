//
//  NSDate+Helpers.m
//  TripKit
//
//  Created by Adrian Schönig on 15/06/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import "NSDate+Helpers.h"


@implementation NSDate(Helpers)

- (BOOL)isInBetweenStartDate:(NSDate *)start andEnd:(NSDate *)end
{
  if ([self timeIntervalSinceDate:start] < 0) {
    return NO;  // start date is after now => agenda hasn't started yet
  } else if ([self timeIntervalSinceDate:end] > 0) {
    return NO;  // end date is earlier than now => ended already
  } else {
    return YES;
  }
}


- (NSDate*)dateAt12HoursToNoonInTimeZone:(NSTimeZone *)timeZoneOrNil
{
  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  gregorian.timeZone = timeZoneOrNil ?: [NSTimeZone defaultTimeZone];
  
  NSCalendarUnit units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
  NSDateComponents *components = [gregorian components:units fromDate:self];
  components.hour = 12;
  components.minute = 0;
  components.second = 0;
  return [[gregorian dateFromComponents:components] dateByAddingTimeInterval:-12 * 3600];
}

- (NSDate*)dateAtMidnightInTimeZone:(NSTimeZone *)timeZoneOrNil
{
  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  gregorian.timeZone = timeZoneOrNil ?: [NSTimeZone defaultTimeZone];
  
  if ([gregorian respondsToSelector:@selector(startOfDayForDate:)]) {
    return [gregorian startOfDayForDate:self];
  } else {
    NSCalendarUnit units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents *components = [gregorian components:units fromDate:self];
    components.hour = 0;
    components.minute = 0;
    components.second = 0;
    return [gregorian dateFromComponents:components];
  }
}

- (NSDate *)dateAtNextMidnightInTimeZone:(NSTimeZone *)timeZoneOrNil
{
  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  gregorian.timeZone = timeZoneOrNil ?: [NSTimeZone defaultTimeZone];
  
  NSCalendarUnit units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
  NSDateComponents *components = [gregorian components:units fromDate:self];
  components.hour = 23;
  components.minute = 59;
  components.second = 59;
  return [[gregorian dateFromComponents:components] dateByAddingTimeInterval:1];
}

- (NSDate *)dateAtPreviousHourInTimeZone:(NSTimeZone *)timeZoneOrNil
{
  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  gregorian.timeZone = timeZoneOrNil ?: [NSTimeZone defaultTimeZone];
  
  NSCalendarUnit units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour;
  NSDateComponents *components = [gregorian components:units fromDate:self];
  components.minute = 0;
  components.second = 0;
  return [gregorian dateFromComponents:components];
}

- (NSDate *)dateAtNextHourInTimeZone:(NSTimeZone *)timeZoneOrNil
{
  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  gregorian.timeZone = timeZoneOrNil ?: [NSTimeZone defaultTimeZone];
  
  NSCalendarUnit units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour;
  NSDateComponents *components = [gregorian components:units fromDate:self];
  components.minute = 0;
  components.second = 0;
  return [[gregorian dateFromComponents:components] dateByAddingTimeInterval:3600];
}

- (NSDate *)dateAtSameTimeInTimeZone:(NSTimeZone *)timeZoneOrNil afterAddingDays:(NSInteger)days
{
  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  gregorian.timeZone = timeZoneOrNil ?: [NSTimeZone defaultTimeZone];
  
  NSCalendarUnit units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
  NSDateComponents *components = [gregorian components:units fromDate:self];
  components.day += days;
  return [gregorian dateFromComponents:components];
}

@end
