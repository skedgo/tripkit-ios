//
//  TKStyleManager.m
//  TripKit
//
//  Created by Adrian Schoenig on 24/10/2013.
//
//

#import "TKMacro.h"

#if SWIFT_PACKAGE
#import <TripKitObjc/TKConfig.h>
#import <TripKitObjc/TKStyleManager.h>
#else
#import "TKConfig.h"
#import "TKStyleManager.h"
#endif


@implementation TKStyleManager

+ (NSBundle *)bundle
{
  return [NSBundle bundleForClass:[TKStyleManager class]];
}


#pragma mark - Date formatting

NSString * const kTimeOnlyDateFormatterKey = @"TimeOnlyDateFormatterKey";

+ (NSString *)timeString:(NSDate *)time
             forTimeZone:(NSTimeZone *)timeZone
{
  return [self timeString:time forTimeZone:timeZone relativeToTimeZone:nil];
}

+ (NSString *)timeString:(NSDate *)time
             forTimeZone:(NSTimeZone *)timeZone
      relativeToTimeZone:(NSTimeZone *)relativeTimeZone
{
	NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
	NSDateFormatter *timeOnlyFormatter = [threadDictionary objectForKey:kTimeOnlyDateFormatterKey];
	
	if (!timeOnlyFormatter) {
		timeOnlyFormatter = [[NSDateFormatter alloc] init];
		timeOnlyFormatter.dateStyle = NSDateFormatterNoStyle;
		timeOnlyFormatter.timeStyle = NSDateFormatterShortStyle;
		timeOnlyFormatter.locale    = [NSLocale currentLocale];
    [threadDictionary setObject:timeOnlyFormatter forKey:kTimeOnlyDateFormatterKey];
	}
	
	if (timeZone) {
		timeOnlyFormatter.timeZone = timeZone;
	}
  NSString *string = [timeOnlyFormatter stringFromDate:time];
  NSString *compact = [[string stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
  
  if (relativeTimeZone && timeZone && ![[relativeTimeZone abbreviationForDate:time] isEqualToString:[timeZone abbreviationForDate:time]]) {
    return [NSString stringWithFormat:@"%@ (%@)", compact, [timeZone abbreviationForDate:time]];
  } else {
    return compact;
  }
}

NSString * const kDateOnlyDateFormatterKey = @"DateOnlyDateFormatterKey";

+ (NSString *)dateString:(NSDate *)time
						 forTimeZone:(NSTimeZone *)timeZone
{
	NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
	NSDateFormatter *dateOnlyFormatter = [threadDictionary objectForKey:kDateOnlyDateFormatterKey];
	
	if (nil == dateOnlyFormatter) {
		dateOnlyFormatter = [[NSDateFormatter alloc] init];
		dateOnlyFormatter.dateStyle = NSDateFormatterFullStyle;
		dateOnlyFormatter.timeStyle = NSDateFormatterNoStyle;
		dateOnlyFormatter.doesRelativeDateFormatting = YES;
		dateOnlyFormatter.locale    = [NSLocale currentLocale];
		[threadDictionary setObject:dateOnlyFormatter forKey:kDateOnlyDateFormatterKey];
	}
	
	if (nil != timeZone) {
		dateOnlyFormatter.timeZone = timeZone;
	}
  
	return [[dateOnlyFormatter stringFromDate:time] capitalizedStringWithLocale:dateOnlyFormatter.locale];
}

NSString * const kDateTimeDateFormatterKey = @"DateTimeDateFormatterKey";

+ (NSString *)stringForDate:(NSDate *)date
                forTimeZone:(NSTimeZone *)timeZone
                   showDate:(BOOL)showDate
                   showTime:(BOOL)showTime
{
  NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
	NSDateFormatter *formatter = [threadDictionary objectForKey:kDateTimeDateFormatterKey];
	
	if (nil == formatter) {
		formatter = [[NSDateFormatter alloc] init];
		[threadDictionary setObject:formatter forKey:kDateTimeDateFormatterKey];
	}
  
  formatter.timeStyle = showTime ? NSDateFormatterShortStyle : NSDateFormatterNoStyle;
  formatter.dateStyle = showDate ? NSDateFormatterMediumStyle : NSDateFormatterNoStyle;
  formatter.locale    = [NSLocale currentLocale];
	
	if (nil != timeZone) {
		formatter.timeZone = timeZone;
	}
	
	return [formatter stringFromDate:date];
}

+ (NSString *)stringForDate:(NSDate *)date
                forTimeZone:(NSTimeZone *)timeZone
                forceFormat:(NSString *)format
{
  return [self stringForDate:date forTimeZone:timeZone forceFormat:format orStyle:NSDateFormatterNoStyle];
}

+ (NSString *)stringForDate:(NSDate *)date
                forTimeZone:(NSTimeZone *)timeZone
                 forceStyle:(NSDateFormatterStyle)style
{
  return [self stringForDate:date forTimeZone:timeZone forceFormat:nil orStyle:style];
}

+ (NSString *)stringForDate:(NSDate *)date
                forTimeZone:(NSTimeZone *)timeZone
                forceFormat:(NSString *)format
                    orStyle:(NSDateFormatterStyle)style
{
  NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
	NSDateFormatter *formatter = [threadDictionary objectForKey:kDateTimeDateFormatterKey];
	
	if (nil == formatter) {
		formatter = [[NSDateFormatter alloc] init];
		[threadDictionary setObject:formatter forKey:kDateTimeDateFormatterKey];
	}
  
  formatter.locale    = [NSLocale currentLocale];
  if (format) {
    formatter.dateFormat = format;
  } else {
    formatter.dateFormat = nil;
    formatter.dateStyle = style;
  }
  
	if (nil != timeZone) {
		formatter.timeZone = timeZone;
	}
	
	return [formatter stringFromDate:date];
}

@end
