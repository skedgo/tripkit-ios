//
//  TKUITrackHelper.m
//  TripKit
//
//  Created by Adrian Schoenig on 20/01/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

#import "TKUITrackHelper.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
#import "TripKitUI/TripKitUI-Swift.h"
#endif

@implementation TKUITrackHelper

+ (NSTimeZone *)timeZoneForTrackItem:(id<TKTrackItem>)trackItem
{
  NSTimeZone *timeZone = [trackItem timeZone];
  if (! timeZone) {
    timeZone = [NSTimeZone defaultTimeZone];
  }
  return timeZone;
}

+ (NSTimeZone *)attendanceTimeZoneForTrackItem:(id<TKTrackItem>)trackItem
{
  BOOL affectsTimeZone = [trackItem conformsToProtocol:@protocol(TKTripTrackItem)]
                      || CLLocationCoordinate2DIsValid([[trackItem mapAnnotation] coordinate]);
  if (affectsTimeZone) {
    return [trackItem timeZone];
  } else {
    return nil;
  }
}

+ (NSString *)titleForTrackItem:(id<TKTrackItemDisplayable>)trackItem
                 includingTimes:(BOOL)includeTime
{
  includeTime = includeTime && ! [trackItem hideTimes];
  
  NSTimeZone *timeZone = [self timeZoneForTrackItem:trackItem];
  NSMutableString *title = [NSMutableString string];
  
  if (includeTime && [trackItem startDate]) {
    [title appendString:[TKStyleManager timeString:[trackItem startDate]
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
      NSString *durationString = [TKObjcDateHelper durationStringForMinutes:(NSInteger)(duration + 59) / 60];
      [title appendFormat:@" (%@)", durationString];
    }
  }
  
  return title;
}

+ (NSAttributedString *)attributedTitleForTrackItem:(id<TKTrackItemDisplayable>)trackItem
{
  NSDictionary *atts = nil;
  switch ([trackItem trackItemStatus]) {
    case TKTrackItemStatusCanceled:
      atts = @{NSStrikethroughStyleAttributeName: @(NSUnderlineStyleSingle)};
      break;
      
    case TKTrackItemStatusExcluded:
      atts = @{NSForegroundColorAttributeName: UIColor.tkLabelSecondary};
      break;
      
    default:
      break;
  }
  
  NSString *title = [self titleForTrackItem:trackItem includingTimes:NO];
  return [[NSAttributedString alloc] initWithString:title
                                         attributes:atts];
}

+ (NSString *)subtitleForTrackItem:(id<TKTrackItemDisplayable>)trackItem
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

+ (NSAttributedString *)attributedSubtitleForTrackItem:(id<TKTrackItemDisplayable>)trackItem
{
  NSString *subtitle = [self subtitleForTrackItem:trackItem];
  if (subtitle) {
    return [[NSAttributedString alloc] initWithString:subtitle];
  } else {
    return nil;
  }
}

+ (NSAttributedString *)attributedSideTitleForTrackItem:(id<TKTrackItemDisplayable>)trackItem
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
  if (includeStart && displayTimeZone) {
    startTimeString = [TKStyleManager timeString:startDate forTimeZone:displayTimeZone relativeToTimeZone:relativeTimeZone];
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
      endTimeString = [TKStyleManager timeString:endDate forTimeZone:displayTimeZone];
    }
  }
  
  if (startTimeString && endTimeString) {
    [sideTitle appendString:startTimeString];
    [sideTitle appendString:@"\n"];
    [sideTitle appendFormat:NSLocalizedStringFromTableInBundle(@"to %@", @"Shared", [TKStyleManager bundle], @"to %date. (old key: DateToFormat)"), endTimeString];
    
  } else if (! startTimeString && ! endTimeString) {
    [sideTitle appendString:Loc.AllDay];
  
  } else if (startTimeString) {
    [sideTitle appendFormat:NSLocalizedStringFromTableInBundle(@"starts at %@", @"Shared", [TKStyleManager bundle], @"Short indicator of start-time"), startTimeString];

  } else if (endTimeString) {
    [sideTitle appendFormat:NSLocalizedStringFromTableInBundle(@"ends at %@", @"Shared", [TKStyleManager bundle], @"Short indicator of end-time"), endTimeString];
  }
  

  NSString *nonBreaking = [sideTitle stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
  return [[NSAttributedString alloc] initWithString:nonBreaking];
}


+ (NSString *)timeStringForTrack:(id<TKTrack>)track
{
  NSTimeZone *timeZone = [NSTimeZone defaultTimeZone];
  for (id<TKTrackItem> trackItem in [track items]) {
    NSTimeZone *itemTimeZone = [self timeZoneForTrackItem:trackItem];
    if (itemTimeZone) {
      timeZone = itemTimeZone;
      break;
    }
  }
  
  NSString *startString = [TKStyleManager dateString:[track startDate] forTimeZone:timeZone];
  if ([track endDate]) {
    NSString *endString   = [TKStyleManager dateString:[track endDate] forTimeZone:timeZone];
    if ([startString isEqualToString:endString]) {
      return startString;
    } else {
      return [NSString stringWithFormat:@"%@ - %@", startString, endString];
    }
  } else {
    return startString;
  }
}

+ (id<MKAnnotation>)originOfTrackItem:(id<TKTrackItem>)trackItem
{
  if ([trackItem conformsToProtocol:@protocol(TKTripTrackItem)]) {
    id<TKTripTrackItem> tripTrackItem = (id<TKTripTrackItem>)trackItem;
    return [tripTrackItem routeStart];
  } else  {
    return [trackItem mapAnnotation];
  }
}

+ (id<MKAnnotation>)destinationOfTrackItem:(id<TKTrackItem>)trackItem
{
  if ([trackItem conformsToProtocol:@protocol(TKTripTrackItem)]) {
    id<TKTripTrackItem> tripTrackItem = (id<TKTripTrackItem>)trackItem;
    return [tripTrackItem routeEnd];
  } else {
    return [trackItem mapAnnotation];
  }
}

+ (BOOL)trackItemShouldBeIgnored:(id<TKTrackItem>)trackItem
{
  switch ([trackItem trackItemStatus]) {
    case TKTrackItemStatusCanceled:
    case TKTrackItemStatusExcluded:
      return YES;
      
    case TKTrackItemStatusCannotFit:
    case TKTrackItemStatusNone:
      return NO;
  }
}

+ (NSString *)debugDescriptionForTrackItem:(id<TKTrackItem>)trackItem
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
  for (id<TKTrackItem> trackItem in trackItems) {
    [description appendFormat:@"- %@\n", [TKUITrackHelper debugDescriptionForTrackItem:trackItem]];
  }
  return description;
}

@end
