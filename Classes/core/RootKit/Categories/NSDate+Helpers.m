//
//  NSDate+Helpers.m
//  TripGo
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

- (NSDate *)dateAtSameTimeInTimeZone:(NSTimeZone *)timeZone afterAddingDays:(NSInteger)days
{
  if (! timeZone) {
    timeZone = [NSTimeZone defaultTimeZone];
  }
  
  CFTimeZoneRef tz = (__bridge CFTimeZoneRef)(timeZone);
  
  CFAbsoluteTime startTime = CFDateGetAbsoluteTime((__bridge CFDateRef)(self));
  CFGregorianDate gregorianStartDate = CFAbsoluteTimeGetGregorianDate(startTime, tz);
  gregorianStartDate.day = gregorianStartDate.day + (SInt8) days;
  return [NSDate dateWithTimeIntervalSinceReferenceDate:CFGregorianDateGetAbsoluteTime(gregorianStartDate, tz)];
}


+ (NSDate *)dateFromISO8601String:(NSString *)value
{
	if (! value.length)
		return nil;
  
	struct tm tm;
	strptime(value.UTF8String, "%Y-%m-%dT%H:%M:%S%z", &tm);
	time_t time = mktime(&tm);
  
	return [NSDate dateWithTimeIntervalSince1970:time + [[NSTimeZone localTimeZone] secondsFromGMT]];
}

- (NSString *)ISO8601String
{
	struct tm *timeinfo;
	char buffer[80];
  
	time_t rawtime = (time_t)[self timeIntervalSince1970];
	timeinfo = gmtime(&rawtime);
	strftime(buffer, 80, "%Y-%m-%dT%H:%M:%SZ", timeinfo);
	return [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
}

@end
