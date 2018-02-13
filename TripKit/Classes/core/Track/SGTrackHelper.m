//
//  SGTrackHelper.m
//  TripKit
//
//  Created by Adrian Schoenig on 20/01/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

#import "SGTrackHelper.h"

#import "TripKit/TripKit-Swift.h"

#import "SGStyleManager.h"

@implementation SGTrackHelper

+ (NSTimeZone *)timeZoneForTrackItem:(id<SGTrackItem>)trackItem
{
  NSTimeZone *timeZone = [trackItem timeZone];
  if (! timeZone) {
    timeZone = [NSTimeZone defaultTimeZone];
  }
  return timeZone;
}

+ (NSTimeZone *)attendanceTimeZoneForTrackItem:(id<SGTrackItem>)trackItem
{
  BOOL affectsTimeZone = [self trackItemIsTrip:trackItem]
                      || CLLocationCoordinate2DIsValid([[trackItem mapAnnotation] coordinate]);
  if (affectsTimeZone) {
    return [trackItem timeZone];
  } else {
    return nil;
  }
}

+ (NSString *)titleForTrackItem:(id<SGTrackItemDisplayable>)trackItem
                 includingTimes:(BOOL)includeTime
{
  includeTime = includeTime && ! [trackItem hideTimes];
  
  NSTimeZone *timeZone = [self timeZoneForTrackItem:trackItem];
  NSMutableString *title = [NSMutableString string];
  
  if (includeTime && [trackItem startDate]) {
    [title appendString:[SGStyleManager timeString:[trackItem startDate]
                                       forTimeZone:timeZone]];
  }
  
  // The title
  if (title.length > 0)
    [title appendString:@": "];
  if (! [trackItem title]) {
    [title appendString:@"Unknown title"];
  } else {
    [title appendString:[trackItem title]];
  }
  
  if (includeTime) {
    NSTimeInterval duration = [trackItem duration];
    if (duration > 0) {
      NSString *durationString = [SGKObjcDateHelper durationStringForMinutes:(NSInteger)(duration + 59) / 60];
      [title appendFormat:@" (%@)", durationString];
    }
  }
  
  return title;
}

+ (NSAttributedString *)attributedTitleForTrackItem:(id<SGTrackItemDisplayable>)trackItem
{
  NSDictionary *atts = nil;
  switch ([trackItem trackItemStatus]) {
    case SGTrackItemStatusCanceled:
      atts = @{NSStrikethroughStyleAttributeName: @(NSUnderlineStyleSingle)};
      break;
      
    case SGTrackItemStatusExcluded:
      atts = @{NSForegroundColorAttributeName: [SGStyleManager lightTextColor]};
      break;
      
    default:
      break;
  }
  
  NSString *title = [self titleForTrackItem:trackItem includingTimes:NO];
  return [[NSAttributedString alloc] initWithString:title
                                         attributes:atts];
}

+ (NSString *)subtitleForTrackItem:(id<SGTrackItemDisplayable>)trackItem
{
  if ([trackItem mapAnnotation] == nil) {
    return nil;
  }
  if ([trackItem hideAddress]) {
    return nil;
  }
  
  id<MKAnnotation> itemLocation = [trackItem mapAnnotation];
  NSMutableString *address = nil;
  NSString *locationTitle = [itemLocation title];
  if (locationTitle.length > 0) {
    address = [NSMutableString stringWithString:locationTitle];
    if ([itemLocation respondsToSelector:@selector(subtitle)]) {
      NSString *locationAddress = [itemLocation subtitle];
      if (locationAddress.length > 0
          && [locationAddress rangeOfString:locationTitle].location == NSNotFound) {
        [address appendFormat:@" (%@)", locationAddress];
      }
    }
  } else {
    NSString *addressString = [trackItem address];
    if (addressString.length > 0) {
      address = [NSMutableString stringWithString:addressString];
    }
  }
  return address;
}

+ (NSAttributedString *)attributedSubtitleForTrackItem:(id<SGTrackItemDisplayable>)trackItem
{
  NSString *subtitle = [self subtitleForTrackItem:trackItem];
  if (subtitle) {
    return [[NSAttributedString alloc] initWithString:subtitle];
  } else {
    return nil;
  }
}

+ (NSAttributedString *)attributedSideTitleForTrackItem:(id<SGTrackItemDisplayable>)trackItem
                                       forDayComponents:(NSDateComponents *)dayComponents
                                     relativeToTimeZone:(NSTimeZone *)relativeTimeZone
{
  if ([trackItem hideTimes]) {
    return nil;
  }

  NSMutableString *sideTitle = [NSMutableString string];
  NSTimeZone *displayTimeZone = relativeTimeZone ?: [NSTimeZone defaultTimeZone];
  NSString *startTimeString = nil;
  NSString *endTimeString = nil;
  BOOL timeZoneMatchesDevice = displayTimeZone && [displayTimeZone isEqualToTimeZone:displayTimeZone];

  NSDate *startDate = [trackItem startDate];
  if (! startDate) {
    return nil;
  }

  unsigned dateFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
  NSCalendar *calendar = dayComponents.calendar;
  calendar.timeZone = displayTimeZone;
  
  NSDateComponents *normalisedDayComponents = nil;
  if (dayComponents) {
    normalisedDayComponents = [[NSDateComponents alloc] init];
    normalisedDayComponents.calendar = dayComponents.calendar;
    normalisedDayComponents.timeZone = dayComponents.timeZone;
    normalisedDayComponents.year = dayComponents.year;
    normalisedDayComponents.month = dayComponents.month;
    normalisedDayComponents.day = dayComponents.day;
  }
  
  BOOL includeStart = YES;
  if (normalisedDayComponents && timeZoneMatchesDevice) {
    NSDateComponents *startComponents = [calendar components:dateFlags fromDate:startDate];
    // normalise for comparison
    startComponents.calendar = normalisedDayComponents.calendar;
    startComponents.timeZone = normalisedDayComponents.timeZone;
    includeStart = [startComponents isEqual:normalisedDayComponents];
  }
  if (includeStart) {
    startTimeString = [SGStyleManager timeString:startDate forTimeZone:displayTimeZone relativeToTimeZone:relativeTimeZone];
  }

  NSTimeInterval duration = [trackItem duration];
  if (duration > 0) {
    NSDate *endDate = [startDate dateByAddingTimeInterval:duration];
    BOOL includeEnd = YES;
    if (normalisedDayComponents && timeZoneMatchesDevice) {
      NSDateComponents *endComponents = [calendar components:dateFlags
                                                    fromDate:endDate];
      endComponents.calendar = normalisedDayComponents.calendar;
      endComponents.timeZone = normalisedDayComponents.timeZone;
      includeEnd = [endComponents isEqual:normalisedDayComponents];
    }
    if (includeEnd) {
      endTimeString = [SGStyleManager timeString:endDate forTimeZone:displayTimeZone];
    }
  }
  
  if (startTimeString && endTimeString) {
    [sideTitle appendString:startTimeString];
    [sideTitle appendString:@"\n"];
    [sideTitle appendFormat:NSLocalizedStringFromTableInBundle(@"to %@", @"Shared", [SGStyleManager bundle], @"to %date. (old key: DateToFormat)"), endTimeString];
    
  } else if (! startTimeString && ! endTimeString) {
    [sideTitle appendString:NSLocalizedStringFromTableInBundle(@"all-day", @"Shared", [SGStyleManager bundle], @"Indicator that an event is all-day")];
  
  } else if (startTimeString) {
    [sideTitle appendFormat:NSLocalizedStringFromTableInBundle(@"starts at %@", @"Shared", [SGStyleManager bundle], @"Short indicator of start-time"), startTimeString];

  } else if (endTimeString) {
    [sideTitle appendFormat:NSLocalizedStringFromTableInBundle(@"ends at %@", @"Shared", [SGStyleManager bundle], @"Short indicator of end-time"), endTimeString];
  }
  

  NSString *nonBreaking = [sideTitle stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
  return [[NSAttributedString alloc] initWithString:nonBreaking];
}


+ (BOOL)trackItemShouldBeIgnored:(id<SGTrackItem>)trackItem
{
  switch ([trackItem trackItemStatus]) {
    case SGTrackItemStatusCanceled:
    case SGTrackItemStatusExcluded:
      return YES;
      
    case SGTrackItemStatusCannotFit:
    case SGTrackItemStatusNone:
      return NO;
  }
}

+ (NSString *)debugDescriptionForTrackItem:(id<SGTrackItem>)trackItem
{
  NSMutableString *description = [NSMutableString stringWithString:[self titleForTrackItem:trackItem includingTimes:YES]];
  NSString *subtitle = [self subtitleForTrackItem:trackItem];
  if (subtitle) {
    [description appendFormat:@" (%@)", subtitle];
  }
  return description;
}

+ (NSString *)debugDescriptionForTrackItems:(NSArray *)trackItems
{
  NSMutableString *description = [NSMutableString string];
  for (id<SGTrackItem> trackItem in trackItems) {
    [description appendFormat:@"- %@\n", [SGTrackHelper debugDescriptionForTrackItem:trackItem]];
  }
  return description;
}

@end
