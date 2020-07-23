//
//  TKSegmentBuilder.m
//  TripKit
//
//  Created by Adrian Schönig on 3/03/11.
//  Copyright (c) 2011 SkedGo. All rights reserved.
//

#import "TKSegmentBuilder.h"

#import <TripKit/TripKit-Swift.h>

@implementation TKSegmentBuilder

#pragma mark - TKTripSegment

+ (nullable NSString *)_tripSegmentModeTitleOfSegment:(TKSegment *)segment
{
  if (segment.service) {
		return segment.service.number;
  
  } else if (segment.modeInfo.descriptor.length > 0) {
    return segment.modeInfo.descriptor;
  
  } else if (![segment.trip isMixedModalIgnoringWalking:NO] && segment.distanceInMetres) {
    MKDistanceFormatter *formatter = [[MKDistanceFormatter alloc] init];
    return [formatter stringFromDistance:segment.distanceInMetres.doubleValue];
    
  } else {
    return nil;
  }
}

+ (nullable NSString *)_tripSegmentModeSubtitleOfSegment:(TKSegment *)segment
{
  if ([segment timesAreRealTime]) {
    if ([segment isPublicTransport]) {
      return NSLocalizedStringFromTableInBundle(@"Real-time", @"TripKit", [TKTripKit bundle], nil);
    } else {
      return NSLocalizedStringFromTableInBundle(@"Live traffic", @"TripKit", [TKTripKit bundle], nil);
    }
  
  } else if ([segment.trip isMixedModalIgnoringWalking:NO] && ![segment isPublicTransport]) {
    return [self stringForDuration:YES ofSegment:segment];
  
  } else if (segment.distanceInMetresFriendly) {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterPercentStyle;
    double value = segment.distanceInMetresFriendly.doubleValue / segment.distanceInMetres.doubleValue;
    NSString *percentage = [formatter stringFromNumber:@(value)];

    if ([segment isCycling]) {
      NSString *format = NSLocalizedStringFromTableInBundle(@"%@ cycle friendly", @"TripKit", [TKTripKit bundle], @"Indicator for how cycle-friendly a cycling route is. Placeholder will get replaced with '75%'.");
      return [NSString stringWithFormat:format, percentage];
    } else if ([segment isWheelchair]) {
      NSString *format = NSLocalizedStringFromTableInBundle(@"%@ wheelchair friendly", @"TripKit", [TKTripKit bundle], @"Indicator for how wheelchair-friendly a wheeelchair route is. Placeholder will get replaced with '75%'.");
      return [NSString stringWithFormat:format, percentage];
    } else {
      return nil;
    }
  
  } else {
    return nil;
  }
}



#pragma mark - Private methods

+ (NSUInteger)numberOfStopsIncludingContinuationOfSegment:(TKSegment *)segment
{
  NSUInteger stops = 0;
  TKSegment *candidate = segment;
  while (candidate) {
    stops += candidate.scheduledServiceStops;
    
    // wrap-over
    candidate = [candidate next];
    if (! segment.isContinuation)
      break;
  }
  
  return stops;
}

+ (NSString *)scheduledServiceNumberOrModeOfSegment:(TKSegment *)segment
{
	NSString *number = [segment scheduledServiceNumber]; // number of this
  if (number.length > 0) {
    return number;
  } else {
    NSString *mode = [segment tripSegmentModeTitle]; // mode of the original
    return mode;
  }
}

+ (NSString *)departureLocationOfSegment:(TKSegment *)segment
{
  return [segment.start title];
}

+ (NSString *)arrivalLocation:(BOOL)includingContinuation ofSegment:(TKSegment *)segment
{
  TKSegment *candidate = includingContinuation ? [segment finalSegmentIncludingContinuation] : segment;
  return [candidate.end title];
}

+ (NSString *)stringForDurationWithoutTrafficOfSegment:(TKSegment *)segment {
  NSTimeInterval withoutTraffic = segment.durationWithoutTraffic;
  if (withoutTraffic == 0) {
    return nil;
  }
  
  NSTimeInterval withTraffic = [segment durationIncludingContinuation:NO];
  if (withTraffic > withoutTraffic + 60) {
    NSString *durationString = [TKObjcDateHelper durationStringForMinutes:(NSInteger) (withoutTraffic / 60)];
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ w/o traffic", @"TripKit", [TKTripKit bundle], @"Duration without traffic"), durationString];
  } else {
    return nil;
  }
}

+ (NSString *)stringForDuration:(BOOL)includingContinuation ofSegment:(TKSegment *)segment {
  TKSegment *candidate = includingContinuation ? [segment finalSegmentIncludingContinuation] : segment;
  return [TKObjcDateHelper durationStringForStart:segment.departureTime end:candidate.arrivalTime];
}


// MARK: - Builder

+ (BOOL)_fillInTemplates:(NSMutableString *)string
              forSegment:(TKSegment *)segment
                 inTitle:(BOOL)title
           includingTime:(BOOL)includeTime
       includingPlatform:(BOOL)includePlatform
{
  BOOL isDynamic = NO;
  NSRange range;
  range = [string rangeOfString:@"<NUMBER>"];
  if (range.location != NSNotFound) {
    NSString *replacement = [self scheduledServiceNumberOrModeOfSegment:segment]?: @"";
    [string replaceCharactersInRange:range withString:replacement];
  }

  range = [string rangeOfString:@"<LINE_NAME>"];
  if (range.location != NSNotFound) {
    NSString *replacement = segment.service.lineName ?: @"";
    [string replaceCharactersInRange:range withString:replacement];
  }

	range = [string rangeOfString:@"<DIRECTION>"];
  if (range.location != NSNotFound) {
    NSString *replacement = @"";
    if (segment.service.direction) {
      replacement = [NSString stringWithFormat:@"%@: %@", NSLocalizedStringFromTableInBundle(@"Direction", @"TripKit", [TKTripKit bundle], "Destination of the bus"), segment.service.direction];
    }
    [string replaceCharactersInRange:range withString:replacement];
	}

  range = [string rangeOfString:@"<LOCATIONS>"];
  if (range.location != NSNotFound) {
    [string replaceCharactersInRange:range withString:@""];
  }

  range = [string rangeOfString:@"<PLATFORM>"];
  if (range.location != NSNotFound) {
    NSString *platform = includePlatform ? [segment scheduledStartPlatform] : nil;
    NSString *replacement = platform ?: @"";
    [string replaceCharactersInRange:range withString:replacement];
  }

  range = [string rangeOfString:@"<STOPS>"];
  if (range.location != NSNotFound) {
    NSInteger visited = [self numberOfStopsIncludingContinuationOfSegment:segment];
    NSString *replacement = [Loc Stops:visited];
    [string replaceCharactersInRange:range withString:replacement];
  }
  
  range = [string rangeOfString:@"<TIME>"];
  if (range.location != NSNotFound) {
    if (includeTime) {
      NSString *timeString = [TKStyleManager timeString:segment.departureTime
                                            forTimeZone:segment.timeZone];
      BOOL prepend = range.location > 0 && [string characterAtIndex:range.location - 1] != '\n';
      NSString *replacement;
      if (prepend) {
        replacement = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"at %@", @"TripKit", [TKTripKit bundle], "Time of the bus departure. (old key: DepartureTime)"), timeString];
        replacement = [NSString stringWithFormat:@" %@", replacement];
      } else {
        replacement = timeString;
      }
      isDynamic = YES;
      [string replaceCharactersInRange:range withString:replacement];
      
    } else {
      [string replaceCharactersInRange:range withString:@""];
    }
  }
  
  range = [string rangeOfString:@"<DURATION>"];
  if (range.location != NSNotFound) {
    NSString *durationString = [self stringForDuration:YES ofSegment:segment];
    NSString *replacement;
    if (durationString.length == 0) {
      replacement = @"";
    } else {
      BOOL prepend = title && range.location > 0;
      if (prepend) {
        replacement = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"for %@", @"TripKit", [TKTripKit bundle], "Text indiction for how long a segment might take, where '%@' will be replaced with a duration. E.g., the instruction 'Take bus' might have this next to it as 'for 10 minutes'."), durationString];
        replacement = [NSString stringWithFormat:@" %@", replacement];
      } else {
        replacement = durationString;
      }
    }
    
    isDynamic = YES;
    [string replaceCharactersInRange:range withString:replacement];
  }
  
  range = [string rangeOfString:@"<TRAFFIC>"];
  if (range.location != NSNotFound) {
    NSString *durationString = [self stringForDurationWithoutTrafficOfSegment:segment];
    NSString *replacement;
    if (durationString.length == 0) {
      replacement = @"";
    } else {
      replacement = durationString;
    }
    
    isDynamic = YES; // even though the "duration without traffic" itself isn't time dependent, whether it is visible or not IS time dependent
    [string replaceCharactersInRange:range withString:replacement];
  }

  // replace empty lead-in
  [string replaceOccurrencesOfString:@"^: "
                          withString:@""
                             options:NSRegularExpressionSearch
                               range:NSMakeRange(0, string.length)];
  
  // replace empty lead-in
  [string replaceOccurrencesOfString:@"([\\n^])[ ]*⋅[ ]*"
                          withString:@"$1"
                             options:NSRegularExpressionSearch
                               range:NSMakeRange(0, string.length)];

  // replace empty lead-out
  [string replaceOccurrencesOfString:@"[ ]*⋅[ ]*$"
                          withString:@""
                             options:NSRegularExpressionSearch
                               range:NSMakeRange(0, string.length)];
  
  // replace empty stuff between dots
  [string replaceOccurrencesOfString:@"⋅[ ]*⋅"
                          withString:@"⋅"
                             options:NSRegularExpressionSearch
                               range:NSMakeRange(0, string.length)];
  
  // replace empty lines
  [string replaceOccurrencesOfString:@"^\\n*"
                          withString:@""
                             options:NSRegularExpressionSearch
                               range:NSMakeRange(0, string.length)];
  
  [string replaceOccurrencesOfString:@"  "
                          withString:@" "
                             options:NSLiteralSearch
                               range:NSMakeRange(0, string.length)];
  
  range = [string rangeOfString:@"\n\n"];
  while (range.location != NSNotFound) {
    [string replaceCharactersInRange:range withString:@"\n"];
    range = [string rangeOfString:@"\n\n"];
  }
  [string replaceOccurrencesOfString:@"\\n*$"
                          withString:@""
                             options:NSRegularExpressionSearch
                               range:NSMakeRange(0, string.length)];
  
  return isDynamic;
}

+ (nullable NSString *)_buildPrimaryLocationStringForSegment:(TKSegment *)segment
{
  // build it
  if (segment.order != TKSegmentOrderingRegular) {
    // do nothing
  } else if ([segment isStationary] || [segment isContinuation]) {
    NSString *departure = [self departureLocationOfSegment:segment];
    if (departure.length > 0) {
      return departure;
    }
  } else if ([segment isPublicTransport]) {
    NSString *departure = [self departureLocationOfSegment:segment];
    if (departure.length > 0) {
      return [Loc FromLocation:departure];
    }
  } else {
    NSString *destination = [self arrivalLocation:YES ofSegment:segment];
    if (destination.length > 0) {
      return [Loc ToLocation: destination];
    }
  }
  return nil;
}

+ (NSString *)_buildSingleLineInstructionForSegment:(TKSegment *)segment
                                      includingTime:(BOOL)includeTime
                                  includingPlatform:(BOOL)includePlatform
                                    isTimeDependent:(BOOL *)isTimeDependent
{
  *isTimeDependent = NO;
  NSString *newString = nil;
  
  switch (segment.order) {
    case TKSegmentOrderingStart: {
      *isTimeDependent = includeTime && segment.trip.departureTimeIsFixed;
      NSString *name = [segment.trip.request.fromLocation name];
      if (!name && [segment.next isPublicTransport]) {
        name = [segment.next.start title];
      }
      if (!name) {
        name = [segment.trip.request.fromLocation address];
      }
      if (!name) {
        name = [segment.next.start title];
      }

      if ([segment matchesQuery]) {
        NSString *time = nil;
        if (*isTimeDependent) {
          time = [TKStyleManager timeString:segment.departureTime
                                forTimeZone:segment.timeZone];
        }
        
        newString = [Loc LeaveFromLocationNamed:name atTime:time];
      } else {
        newString = [Loc LeaveNearLocationNamed:name];
      }
      
      break;
    }

    case TKSegmentOrderingRegular: {
      if (!segment._rawAction) {
        return @"";
      }
      NSMutableString *actionRaw = [NSMutableString stringWithString:segment._rawAction];
      *isTimeDependent = [self _fillInTemplates:actionRaw forSegment:segment inTitle:YES includingTime:includeTime includingPlatform:includePlatform];
      newString = actionRaw;
      break;
    }
      
    case TKSegmentOrderingEnd: {
      *isTimeDependent = includeTime && segment.trip.departureTimeIsFixed;
      NSString *name = [segment.trip.request.toLocation name];
      if (!name && [segment.previous isPublicTransport]) {
        name = [segment.previous.end title];
      }
      if (!name) {
        name = [segment.trip.request.toLocation address];
      }
      if (!name) {
        name = [segment.previous.end title];
      }

      if ([segment matchesQuery]) {
        NSString *time = nil;
        if (*isTimeDependent) {
          time = [TKStyleManager timeString:segment.arrivalTime
                                forTimeZone:segment.timeZone];
        }
        newString = [Loc ArriveAtLocationNamed:name atTime:time];
      } else {
        newString = [Loc ArriveNearLocationNamed:name];
      }
      break;
    }
  }
  return newString;
}


#define UNTRAVELLED_EACH_SIDE 5

+ (NSDictionary<NSString *, NSNumber *> *)_buildSegmentVisitsForSegment:(TKSegment *)segment
{
  if ([segment.service hasServiceData]) { // if we didn't yet fetch multiple visits, we return nil
    NSArray *sortedVisits = segment.service.sortedVisits;
    NSMutableDictionary *segmentVisits = [NSMutableDictionary dictionaryWithCapacity:sortedVisits.count];

    NSMutableArray *unvisited = [NSMutableArray arrayWithCapacity:sortedVisits.count];
    
    BOOL isTravelled = NO;
    BOOL isEnd = NO;
    NSString *target = segment.scheduledStartStopCode;
    for (StopVisits *visit in sortedVisits) {
      NSString *current = visit.stop.stopCode;
      if (! current) {
        ZAssert(false, @"Visit had bad stop with no code: %@", visit);
        continue;
      }
      
      if ([target isEqualToString:current]) {
        if (NO == isTravelled) {
          // found start
          target = segment.scheduledEndStopCode;
          isTravelled = YES;
        } else {
          // found end => all untravelled from here
          isTravelled = NO;
          isEnd = YES;
          target = nil;
        }
        [segmentVisits setValue:@(YES) forKey:current];
      } else {
        // on the way
        [segmentVisits setValue:@(isTravelled) forKey:current];
        
        if (NO == isTravelled) {
          [unvisited addObject:current];
          if (isEnd && unvisited.count >= UNTRAVELLED_EACH_SIDE)
            break; // added enough
          
        }
      }
      
      // remove unvisited if we have to
      if (YES == isTravelled && unvisited.count > 0) {
        // remove unvisited
        NSInteger toRemove = unvisited.count - UNTRAVELLED_EACH_SIDE;
        NSInteger removed = 0;
        while (toRemove > 0) {
          NSString *removeMe = unvisited[removed++];
          [segmentVisits removeObjectForKey:removeMe];
          toRemove--;
        }
        
        [unvisited removeAllObjects];
      }

    }
    
    return segmentVisits;
  }
  return nil;
}

@end
