//
//  Route.m
//  TripKit
//
//  Created by Adrian Schönig on 3/03/11.
//  Copyright (c) 2011 SkedGo. All rights reserved.
//

#import "Trip.h"

#import <TripKit/TripKit-Swift.h>

enum {
  SGTripFlagShowNoVehicleUUIDAsLift = 1 << 1,
  SGTripFlagHasFixedDeparture       = 1 << 3,
  SGTripFlagBookingWindowMissed     = 1 << 4,
};
typedef NSUInteger SGTripFlag;

@interface Trip ()

@property (nonatomic, strong) NSSet *usedModeIdentifiers;
@property (nonatomic, strong) NSMutableArray *sortedSegments;

@end

@implementation Trip

@dynamic arrivalTime;
@dynamic departureTime;
@dynamic flags;
@dynamic mainSegmentHashCode;
@dynamic minutes;
@dynamic saveURLString, shareURLString, temporaryURLString;
@dynamic updateURLString, progressURLString;
@dynamic plannedURLString, logURLString;
@dynamic totalCalories, totalCarbon, totalHassle, totalPrice, totalWalking, totalPriceUSD;
@dynamic currencySymbol;
@dynamic totalScore;
@dynamic toDelete;

@dynamic representedGroup;
@dynamic tripGroup;
@dynamic tripTemplate;
@dynamic segmentReferences;

@synthesize usedModeIdentifiers = _usedModeIdentifiers;
@synthesize sortedSegments = _sortedSegments;
@synthesize hasReminder;

+ (void)removeTripsBeforeDate:(NSDate *)date
		 fromManagedObjectContext:(NSManagedObjectContext *)context
{
	NSSet *objects = [context fetchObjectsForEntityClass:self
																	 withPredicateString:@"toDelete = NO AND arrivalTime <= %@", date];
	for (Trip *trip in objects) {
		DLog(@"Deleting trip %@ that arrived %@.", trip, trip.arrivalTime);
    [trip remove];
	}
}

+ (Trip *)findSimilarTripTo:(Trip *)trip
										 inList:(id<NSFastEnumeration>)trips
{
  // this is modelled after GenericPath.java (public boolean significantlyDifferentFrom(@NotNull GenericPath other))
#define departureDifference 90
#define arrivalDifference   90
#define costDifference      .1
  
  for (Trip* existing in trips) {
    if ([existing.usedModeIdentifiers isEqualToSet:trip.usedModeIdentifiers]
        && trip.departureTimeIsFixed == existing.departureTimeIsFixed
				&& (! trip.departureTimeIsFixed
            || (fabs([trip.departureTime timeIntervalSinceDate:existing.departureTime]) < departureDifference
                && fabs([trip.arrivalTime timeIntervalSinceDate:existing.arrivalTime])  < arrivalDifference))
        && fabs([self percentThisHigher:trip.totalCarbon than:existing.totalCarbon]) < costDifference
        && fabs([self percentThisHigher:trip.totalHassle than:existing.totalHassle]) < costDifference
        && (!trip.totalPrice
            || !existing.totalPrice
            || fabs([self percentThisHigher:trip.totalPrice than:existing.totalPrice]) < costDifference)
        )
      return existing;
  }
  return nil;
}

- (void)remove
{
  self.toDelete = YES;
}

- (BOOL)isValid
{
  return self.departureTime != nil && self.arrivalTime != nil;
}

#pragma mark - NSManagedObject

- (void)dealloc
{
	[self cleanUp];
}

- (void)didTurnIntoFault
{
	[super didTurnIntoFault];
	[self cleanUp];
}

- (void)cleanUp
{
	_sortedSegments = nil;
}



#pragma mark - Route properties

- (NSURL *)saveURL
{
  if (self.saveURLString) {
    return [NSURL URLWithString:self.saveURLString];
  } else {
    return nil;
  }
}

- (NSURL *)shareURL
{
  if (self.shareURLString) {
    return [NSURL URLWithString:self.shareURLString];
  } else {
    return nil;
  }
}

- (void)setShareURL:(NSURL *)shareURL
{
  self.shareURLString = [shareURL absoluteString];
}

- (NSString *)constructPlainText
{
  NSMutableString *text = [NSMutableString string];
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
  [dateFormatter setDateStyle:NSDateFormatterNoStyle];
  [dateFormatter setLocale:[TKStyleManager applicationLocale]];
	
	NSTimeZone *tz = [self departureTimeZone];
  if(tz) {
		[dateFormatter setTimeZone:tz];
  }

  for (TKSegment *segment in [self segmentsWithVisibility:TKTripSegmentVisibilityInDetails]) {
    // this is related to SegmentSectionHeaderViews!
    
    // insert a new location as soon as we end up there
    if (segment.order == TKSegmentOrderingStart) {
      //
    } else if (! [segment isStationary]) {
      id<MKAnnotation> thisStart = segment.start;
      id<MKAnnotation> thisEnd   = segment.end;
      if (thisEnd) {
        if (! [TKLocationHelper coordinate:[thisStart coordinate]
                                    isNear:[thisEnd coordinate]]) {
          // simple case: start is far from end: add location
          [text appendString:[[self class] addressForObject:thisStart]];
          [text appendString:@", "];
        } else {
          // second chance: the next non-stationary section is public transport
          for (TKSegment *next = segment.next; next != nil; next = next.next) {
            if ([next isStationary]) {
              continue; // check next
            } else if ([next isPublicTransport]) {
              [text appendString:[[self class] addressForObject:thisStart]];
              [text appendString:@", "];
            } else {
              break; // next is neither stationary nor public
            }
          }
        }
      }
    }
    
    [text appendString:[segment singleLineInstruction]];
    [text appendString:@"\n"];


    NSString *string = segment.notes;
    if (string.length > 0) { // no empty lines
      [text appendString:@"\t"];
      [text appendString:string];
      [text appendString:@"\n"];
    }
    
    [text appendString:@"\n"];
  }
	
  return text;
}

- (NSString *)debugString
{
  // "11:10-16:00; W-C-B-T-W; $3, 50m, 2kg, 5h, $total

  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
  [dateFormatter setDateStyle:NSDateFormatterNoStyle];
  [dateFormatter setLocale:[NSLocale currentLocale]];
	
	NSTimeZone *tz = self.departureTimeZone;
  if(tz) {
		[dateFormatter setTimeZone:tz];
  }
  
  NSMutableString *output = [NSMutableString string];
  [output appendString:[dateFormatter stringFromDate:self.departureTime]];
  [output appendString:@"-"];
  [output appendString:[dateFormatter stringFromDate:self.arrivalTime]];
  [output appendString:@"; "];
  
  BOOL first = true;
  for (TKSegment *segment in [self segmentsWithVisibility:TKTripSegmentVisibilityInDetails]) {
    if (first) {
      first = false;
    } else {
      [output appendString:@"-"];
    }
    NSString *modeTitle = [segment.modeInfo alt];
    if(modeTitle.length > 0) {
			[output appendString:[modeTitle substringToIndex:2]];
    }
  }
  [output appendString:@"; "];
  
  if (self.totalPrice) {
    [output appendFormat:@"%@%.2f, ", self.currencySymbol, self.totalPrice.floatValue];
  }
  
  [output appendFormat:@"%@m, %.0fCal, %.1fkg, %.0fh => %.2f", [self calculateDuration], self.totalCalories.floatValue, self.totalCarbon.floatValue, self.totalHassle.floatValue, self.totalScore.floatValue];
  
  return output;
}

- (NSArray *)segments
{
  if (nil != _sortedSegments) {
    return _sortedSegments;
  }
  
  // order ascending by index
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"index" 
                                                                 ascending:YES];
  NSArray *sortedReferences = [self.segmentReferences sortedArrayUsingDescriptors:@[sortDescriptor]];
  NSMutableArray *sorted = [NSMutableArray arrayWithCapacity:sortedReferences.count + 2];
  
  TKSegment *start = [[TKSegment alloc] initAsTerminal:TKSegmentOrderingStart forTrip:self];
  [sorted addObject:start];
  
	TKSegment *previous = start;
  for (SegmentReference *reference in sortedReferences) {
    if (reference == nil)
      continue; // deprecated => old school terminals

    TKSegment *seg = [[TKSegment alloc] initWithReference:reference forTrip:self];
    [sorted addObject:seg];

		// link them up
		seg.previous  = previous;
		previous.next = seg;
		previous = seg;
  }
  
  TKSegment *end = [[TKSegment alloc] initAsTerminal:TKSegmentOrderingEnd forTrip:self];
  previous.next = end;
  end.previous = previous;
  [sorted addObject:end];
  
  _sortedSegments = sorted;
  return _sortedSegments;
}

- (void)clearSegmentCaches
{
  _sortedSegments = nil;
}

- (BOOL)timesAreRealTime
{
  for (TKSegment *segment in self.segments) {
    if ([segment timesAreRealTime]) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)isImpossible
{
  for (TKSegment *segment in self.segments) {
    if ([segment isImpossible]) {
      return YES;
    }
  }
  return NO;
}

- (TKTimeType)tripTimeType
{
  return (TKTimeType) self.request.timeType.integerValue;
}

- (NSTimeInterval)sortOrderTime
{
  NSTimeInterval seconds;
	TKTimeType timeType = [self tripTimeType];
	switch (timeType) {
		case TKTimeTypeArriveBefore:
      // tis one is backwards!
      seconds = -1 * [self.departureTime timeIntervalSinceReferenceDate];
			break;
      
		case TKTimeTypeLeaveAfter:
    case TKTimeTypeNone: // no selection also sort by time from now
		case TKTimeTypeLeaveASAP:
			seconds = [self.arrivalTime timeIntervalSinceReferenceDate];
			break;
	}
  return seconds / 60; // we'd like minutes
}

- (NSTimeInterval)calculateOffset
{
  NSTimeInterval seconds;
	TKTimeType timeType = [self tripTimeType];
	switch (timeType) {
		case TKTimeTypeArriveBefore:
			seconds = [self.request.arrivalTime timeIntervalSinceDate:self.arrivalTime];
			break;
		
		case TKTimeTypeLeaveAfter:
			seconds = [self.departureTime timeIntervalSinceDate:self.request.departureTime];
			break;
		
    case TKTimeTypeNone: // no selection also sort by time from now
		case TKTimeTypeLeaveASAP:
			seconds = [self.departureTime timeIntervalSinceNow];
			break;
	}
  return seconds / 60; // we'd like minutes
}

- (NSTimeInterval)calculateDurationFromQuery
{
  NSTimeInterval seconds;
	TKTimeType timeType = [self tripTimeType];
	switch (timeType) {
		case TKTimeTypeArriveBefore:
			seconds = [self.request.arrivalTime timeIntervalSinceDate:self.departureTime];
			break;
      
		case TKTimeTypeLeaveAfter:
			seconds = [self.arrivalTime timeIntervalSinceDate:self.request.departureTime];
			break;
      
    case TKTimeTypeNone: // no selection also sort by time from now
		case TKTimeTypeLeaveASAP:
			seconds = [self.arrivalTime timeIntervalSinceNow];
			break;
	}
  return seconds;
}

- (NSNumber *)calculateDuration
{
  self.minutes = @([TKObjcDateHelper minutesForStart:self.departureTime end:self.arrivalTime]);
  return self.minutes;
}

- (void)setShowNoVehicleUUIDAsLift:(BOOL)showNoVehicleUUIDAsLift
{
	[self setFlag:SGTripFlagShowNoVehicleUUIDAsLift to:showNoVehicleUUIDAsLift];
}

- (BOOL)showNoVehicleUUIDAsLift
{
	return 0 != (self.flags.integerValue & SGTripFlagShowNoVehicleUUIDAsLift);
}

- (void)setDepartureTimeIsFixed:(BOOL)departureTimeIsFixed
{
	[self setFlag:SGTripFlagHasFixedDeparture to:departureTimeIsFixed];
}

- (BOOL)departureTimeIsFixed
{
	return 0 != (self.flags.integerValue & SGTripFlagHasFixedDeparture);
}

- (void)setMissedBookingWindow:(BOOL)missedBookingWindow
{
  [self setFlag:SGTripFlagBookingWindowMissed to:missedBookingWindow];
}

- (BOOL)missedBookingWindow
{
  return 0 != (self.flags.integerValue & SGTripFlagBookingWindowMissed);
}


#pragma mark - Request

- (TripRequest *)request
{
  return self.tripGroup.request;
}

- (void)removeFromRequest
{
  if (self.request.preferredGroup == self.tripGroup) {
    self.request.preferredGroup = nil;
  }
  
  self.tripGroup.request = nil;
}

- (void)moveToRequest:(TripRequest *)request markAsPreferred:(BOOL)preferred
{
  self.tripGroup.request = request;
  
  if (preferred) {
    [self setAsPreferredTrip];
  }
}

#pragma mark - Segment accessors

- (void)setAsPreferredTrip
{
  self.tripGroup.visibleTrip = self;
  self.tripGroup.request.lastSelection = self.tripGroup;
}

- (BOOL)usesVisit:(StopVisits *)visit
{
	// find the segment and ask it
	for (TKSegment *segment in self.segments) {
		if (segment.service == visit.service) {
			// we found the service, now check the shapes
			return [segment usesVisit:visit];
		}
	}
	return NO;
}

- (BOOL)shouldShowVisit:(StopVisits *)visit
{
	// find the segment and ask it
	for (TKSegment *segment in self.segments) {
		if (segment.service == visit.service) {
			// we found the service, now check the shapes
			return [segment shouldShowVisit:visit];
		}
	}
	return NO;
}

- (TKSegment *)inferMainSegment
{
  // Deprecated. Shouldn't be used anymore.
  TKSegment *mainSegment = nil;
  for (TKSegment * segment in self.segments) {
    if (YES == [segment isStationary])
      continue;
    if (mainSegment == nil)
      mainSegment = segment;
    else if (! [segment isWalking] && [mainSegment isWalking])
      mainSegment = segment;
    else if ([segment isWalking] && ! [mainSegment isWalking])
      continue;
    else if ([segment.departureTime timeIntervalSinceDate:mainSegment.departureTime] < 0)
      mainSegment = segment;
  }
  return mainSegment;
}

- (BOOL)allowImpossibleSegments
{
  // we allow impossible segments if there's any public transport, we could be
  // more conservative and require at least two public segments.
  return self.firstPublicTransport != nil;
}

- (TKSegment *)firstPublicTransport
{
	for (TKSegment *aSegment in self.segments) {
		if (aSegment.isPublicTransport == YES) {
			return aSegment;
		}
	}
	return nil;
}

- (NSArray *)allPublicTransport
{
	NSMutableArray *publicTransport = [NSMutableArray array];
	
	for (TKSegment *aSegment in self.segments) {
		if (aSegment.isPublicTransport && NO == aSegment.isContinuation) {
			[publicTransport addObject:aSegment];
		}
	}
	
	return publicTransport;
}

- (NSSet *)changes
{
  NSMutableSet *result = [NSMutableSet set];
  for (TKSegment *segment in [self segments]) {
    if (NO == [segment isStationary]) {
      ZAssert(nil != segment.start, @"Segment needs a start: %@", segment);
      [result addObject:segment.start];
    }
  }
  return result;
}

- (BOOL)changesAt:(id<MKAnnotation>) annotation
{
	NSSet *changes = self.changes;
	CLLocation *annoLocation = [[CLLocation alloc] initWithLatitude:annotation.coordinate.latitude longitude:annotation.coordinate.longitude];
	for (id<MKAnnotation> change in changes) {
		CLLocation *candidate = [[CLLocation alloc] initWithLatitude:change.coordinate.latitude
																											 longitude:change.coordinate.longitude];
		if ([candidate distanceFromLocation:annoLocation] < 10) {
			return YES;
		}
	}
	return NO;
}

- (NSSet *)usedModeIdentifiers
{
	if (! _usedModeIdentifiers) {
    NSString *walkingIdentifier = nil;
    NSMutableSet *modes = [NSMutableSet setWithCapacity:10];
		for (TKSegment *segment in [self segments]) {
      NSString *modeIdentifier = [segment modeIdentifier];
      if (modeIdentifier) {
        if ([segment isWalking]) {
          walkingIdentifier = modeIdentifier;
        } else {
          [modes addObject:modeIdentifier];
        }
      }
		}
    if (modes.count == 0 && walkingIdentifier) {
      [modes addObject:walkingIdentifier];
    }
    _usedModeIdentifiers = modes;
	}
  return _usedModeIdentifiers;
}

- (Alert *)primaryAlert
{
  for (TKSegment *segment in self.segments) {
    if (segment.alerts.count > 0) {
      return [segment.alerts firstObject];
    }
  }
  return nil;
}

- (NSString *)accessibilityLabel
{
  // prepare accessibility title
  NSMutableString *accessibleLabel = [NSMutableString string];
	static NSDateFormatter *sTripAccessibilityDateFormatter = nil;
	if (nil == sTripAccessibilityDateFormatter) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sTripAccessibilityDateFormatter = [[NSDateFormatter alloc] init];
      sTripAccessibilityDateFormatter.dateStyle = NSDateFormatterNoStyle;
      sTripAccessibilityDateFormatter.timeStyle = NSDateFormatterShortStyle;
      sTripAccessibilityDateFormatter.locale = [TKStyleManager applicationLocale];
    });
	}
	NSTimeZone *timeZone = [self departureTimeZone];
  if (!timeZone) {
    timeZone = [self arrivalTimeZone];
  }
  sTripAccessibilityDateFormatter.timeZone = timeZone;
	
  BOOL separateByComma = NO;
  for (TKSegment *segment in [self segmentsWithVisibility:TKTripSegmentVisibilityInSummary]) {
    if (separateByComma) {
      [accessibleLabel appendString:@", "];
    } else {
      separateByComma = YES;
    }
    TKModeInfo *modeInfo = segment.modeInfo;
    if (modeInfo) {
      [accessibleLabel appendString:[modeInfo alt]];
    }
    
    NSString *modeCode = [segment tripSegmentModeTitle];
    if (modeCode.length > 0) {
      [accessibleLabel appendString:@" "];
      [accessibleLabel appendString:modeCode];
    }
  }
  
  [accessibleLabel appendString:@" - "];
  if ([self departureTimeIsFixed]) {
    NSString *format = NSLocalizedStringFromTableInBundle(@"%@ to %@", @"TripKit", [TKTripKit bundle], "From %time1 to %time2. (old key: TimeFromToShortFormat)");
    [accessibleLabel appendFormat:format, [sTripAccessibilityDateFormatter stringFromDate:[self departureTime]], [sTripAccessibilityDateFormatter stringFromDate:[self arrivalTime]]];
    [accessibleLabel appendFormat:@" - %@", [self durationString]];
  } else {
    [accessibleLabel appendFormat:@"%@ - ", [self durationString]];

    NSString *arrival = [sTripAccessibilityDateFormatter stringFromDate:[self arrivalTime]];
    [accessibleLabel appendString:[Loc ArriveAtDate:arrival]];
  }
  
  return accessibleLabel;

}

- (NSString *)durationString
{
  if (!self.departureTime || !self.arrivalTime) {
    return @"";
  }
  
  return [TKObjcDateHelper durationStringLongForStart:self.departureTime end:self.arrivalTime];
}

- (NSDictionary *)accessibleCostValues
{
  return [self accessibleCostValues:YES];
}

- (NSDictionary *)accessibleCostValues:(BOOL)includeTime
{
	NSMutableDictionary *values = [NSMutableDictionary dictionaryWithCapacity:3];
  if (includeTime) {
    NSString *durationString = [self durationString];
    if (durationString) {
      values[@(TKTripCostTypeDuration)] = durationString;
    }
  }
  values[@(TKTripCostTypeCalories)] = [TKStyleManager exerciseStringForCalories: self.totalCalories.doubleValue];
  values[@(TKTripCostTypeCarbon)]   = [self.totalCarbon toCarbonString];
  if (self.totalPrice) {
    values[@(TKTripCostTypePrice)]  = [self.totalPrice toMoneyString:[self currencySymbol]];
  }
  return values;
}


#pragma mark - Private methods

- (void)setFlag:(SGTripFlag)flag to:(BOOL)value
{
	SGTripFlag flags = (SGTripFlag) self.flags.integerValue;
	if (value) {
		self.flags = @(flags | flag);
	} else {
		self.flags = @(flags & ~flag);
	}
}

+ (double)percentThisHigher:(NSNumber *)this than:(NSNumber*)that
{
  if (this.doubleValue < 0.0001)
    return 0.0;
  if (that.doubleValue < 0.0001)
    return 1.0;
  
  return 1.0 - (this.doubleValue / that.doubleValue);
}


#pragma mark - Private: Others

+ (NSString *)addressForObject:(id<MKAnnotation>)object
{
  // we prefer the subtitle over the title
  NSString *address = nil;
  
  if ([object respondsToSelector:@selector(subtitle)]) {
    address = [object subtitle];
  }
  
  if (! address) {
    address = [object title];
  }
  
  return address;
}

@end
