//
//  NSDate+Helpers.h
//  TripGo
//
//  Created by Adrian Schönig on 15/06/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface NSDate (NSDate_Helpers)

- (BOOL)isInBetweenStartDate:(NSDate *)start andEnd:(NSDate *)end;

- (NSDate *)dateAtMidnightInTimeZone:(nullable NSTimeZone *)timeZone;
- (NSDate *)dateAtNextMidnightInTimeZone:(nullable NSTimeZone *)timeZone;
- (NSDate*)dateAt12HoursToNoonInTimeZone:(NSTimeZone *)timeZone;

- (NSDate *)dateAtPreviousHourInTimeZone:(nullable NSTimeZone *)timeZone;
- (NSDate *)dateAtNextHourInTimeZone:(nullable NSTimeZone *)timeZone;

- (NSDate *)dateAtSameTimeInTimeZone:(NSTimeZone *)timeZone afterAddingDays:(NSInteger)days;

+ (nullable NSDate *)dateFromISO8601String:(NSString *)value;
- (NSString *)ISO8601String;

@end
NS_ASSUME_NONNULL_END

