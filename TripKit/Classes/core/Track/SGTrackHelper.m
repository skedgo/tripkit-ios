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
  BOOL affectsTimeZone = [trackItem conformsToProtocol:@protocol(SGTripTrackItem)]
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
  if (displayTimeZone) {
    calendar.timeZone = displayTimeZone;
  }
  
  BOOL includeStart = YES;
  if (dayComponents && timeZoneMatchesDevice) {
    NSDateComponents *startComponents = [calendar components:dateFlags fromDate:startDate];
    // normalise for comparison
    startComponents.calendar = dayComponents.calendar;
    startComponents.timeZone = dayComponents.timeZone;
    includeStart = [startComponents isEqual:dayComponents];
  }
  if (includeStart) {
    startTimeString = [SGStyleManager timeString:startDate forTimeZone:displayTimeZone relativeToTimeZone:relativeTimeZone];
  }

  NSTimeInterval duration = [trackItem duration];
  if (duration > 0) {
    NSDate *endDate = [startDate dateByAddingTimeInterval:duration];
    BOOL includeEnd = YES;
    if (dayComponents && timeZoneMatchesDevice) {
      NSDateComponents *endComponents = [calendar components:dateFlags
                                                    fromDate:endDate];
      endComponents.calendar = dayComponents.calendar;
      endComponents.timeZone = dayComponents.timeZone;
      includeEnd = [endComponents isEqual:dayComponents];
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


+ (NSString *)timeStringForTrack:(id<SGTrack>)track
{
  NSTimeZone *timeZone = [NSTimeZone defaultTimeZone];
  for (id<SGTrackItem> trackItem in [track items]) {
    NSTimeZone *itemTimeZone = [self timeZoneForTrackItem:trackItem];
    if (itemTimeZone) {
      timeZone = itemTimeZone;
      break;
    }
  }
  
  NSString *startString = [SGStyleManager dateString:[track startDate] forTimeZone:timeZone];
  if ([track endDate]) {
    NSString *endString   = [SGStyleManager dateString:[track endDate] forTimeZone:timeZone];
    if ([startString isEqualToString:endString]) {
      return startString;
    } else {
      return [NSString stringWithFormat:@"%@ - %@", startString, endString];
    }
  } else {
    return startString;
  }
}

+ (id<MKAnnotation>)originOfTrackItem:(id<SGTrackItem>)trackItem
{
  if ([trackItem conformsToProtocol:@protocol(SGTripTrackItem)]) {
    id<SGTripTrackItem> tripTrackItem = (id<SGTripTrackItem>)trackItem;
    return [tripTrackItem routeStart];
  } else  {
    return [trackItem mapAnnotation];
  }
}

+ (id<MKAnnotation>)destinationOfTrackItem:(id<SGTrackItem>)trackItem
{
  if ([trackItem conformsToProtocol:@protocol(SGTripTrackItem)]) {
    id<SGTripTrackItem> tripTrackItem = (id<SGTripTrackItem>)trackItem;
    return [tripTrackItem routeEnd];
  } else {
    return [trackItem mapAnnotation];
  }
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
