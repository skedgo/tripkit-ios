//
//  StopVisits.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 24/11/12.
//
//

#import "StopVisits.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#endif

#import "TripKit/TripKit-Swift.h"

#import "TKRootKit.h"
#import "StopLocation.h"

#import "TKStyleManager.h"

@implementation StopVisits

@dynamic arrival;
@dynamic bearing;
@dynamic departure;
@dynamic originalTime;
@dynamic flags;
@dynamic index;
@dynamic isActive;
@dynamic regionDay;
@dynamic searchString;
@dynamic toDelete;
@dynamic service;
@dynamic stop;
@dynamic shapes;

+ (NSArray *)fetchStopVisitsForStopLocation:(StopLocation *)stopLocation
                           startingFromDate:(NSDate *)earliestDate
{
  NSArray *visits = [stopLocation.managedObjectContext fetchObjectsForEntityClass:self
                                                                 withFetchRequest:
                   ^(NSFetchRequest *request) {
                     request.predicate       = [stopLocation departuresPredicateFromDate:earliestDate];
                     request.sortDescriptors = [StopVisits defaultSortDescriptors];
                     
                     request.relationshipKeyPathsForPrefetching = @[@"stop"];
                   }];
  return visits;
}

- (void)remove
{
  self.toDelete = YES;
}

+ (NSArray *)defaultSortDescriptors
{
	return @[ [NSSortDescriptor sortDescriptorWithKey:@"departure" ascending:YES] ];
}

+ (NSPredicate *)departuresPredicateForStops:(NSArray *)stops
                                    fromDate:(NSDate *)date
                                      filter:(nullable NSString *)filter
{
	if (filter.length > 0) {
		return [NSPredicate predicateWithFormat:@"toDelete = NO AND stop IN %@ AND ((departure != nil AND departure > %@) OR (arrival != nil AND arrival > %@)) AND (service.number CONTAINS[c] %@ OR service.name CONTAINS[c] %@ OR stop.shortName CONTAINS[c] %@ OR searchString CONTAINS[c] %@)", stops, date, date, filter, filter, filter, filter];
	} else {
		return [NSPredicate predicateWithFormat:@"toDelete = NO AND stop IN %@ AND ((departure != nil AND departure > %@) OR (arrival != nil AND arrival > %@))", stops, date, date];
	}
}

- (void)adjustRegionDay
{
	if (self.departure) {
		self.regionDay = [self.departure dateAtMidnightInTimeZone:self.stop.region.timeZone];
	} else if (self.arrival) {
		self.regionDay = [self.departure dateAtMidnightInTimeZone:self.stop.region.timeZone];
	} else {
		ZAssert(false, @"We neither have an arrival nor a departure!");
	}
}

- (NSString *)smsString
{
	NSTimeZone *timeZone = self.stop.region.timeZone;
  NSString *departure = self.frequency != nil
    ? [TKStyleManager timeString:self.departure forTimeZone:timeZone]
    : @"";
  NSMutableString *output = [NSMutableString stringWithFormat:@"%@ %@", [self.service shortIdentifier], departure];
  if ([self.service isRealTime])
    [output appendString:@"*"];
  return output;
}

- (NSString *)secondaryInformation
{
  NSMutableString *subtitle = [NSMutableString string];
  
  // start and end times for frequency-based services
  if (self.service.frequency.integerValue > 0 && self.departure != nil && self.arrival != nil) {
    NSTimeZone *timeZone = self.stop.region.timeZone;
    [subtitle appendFormat:@"%@ - %@",
     [TKStyleManager timeString:self.departure forTimeZone:timeZone],
     [TKStyleManager timeString:self.arrival forTimeZone:timeZone]];
  }
  
  // platforms
  NSCharacterSet *whites = [NSCharacterSet whitespaceCharacterSet];
  NSString *standName = [self.stop.shortName stringByTrimmingCharactersInSet:whites];
  if (standName.length > 0) {
    if (subtitle.length > 0) {
      [subtitle appendString:@" ⋅ "];
    }
    [subtitle appendString:standName];
  }
  
  // service name
  NSString *serviceName = [self.service.direction stringByTrimmingCharactersInSet:whites];
  if (serviceName.length > 0) {
    if (subtitle.length > 0) {
      [subtitle appendString:@" ⋅ "];
    }
    [subtitle appendString:serviceName];
  }
  return subtitle;
}

- (StopVisitRealTime)realTimeStatus
{
  if (self.service.isCancelled) {
    return StopVisitRealTimeCancelled;
  } else if (!self.service.isRealTimeCapable) {
    return StopVisitRealTimeNotApplicable;
  } else if (!self.service.isRealTime) {
    return StopVisitRealTimeNotAvailable;
  }
  
  NSDate *time = self.departure ?: self.arrival;
  if ([time isEqual:self.originalTime]) {
    return StopVisitRealTimeOnTime;
  } else {
    // do they also display differently?
    NSTimeInterval realTime = [time timeIntervalSince1970];
    realTime -= (NSInteger)realTime % 60;
    
    NSTimeInterval timeTable = [self.originalTime timeIntervalSince1970];
    timeTable -= (NSInteger)timeTable % 60;
    
    if (realTime - timeTable > 59) {
      return StopVisitRealTimeLate;
    } else if (timeTable - realTime > 59) {
      return StopVisitRealTimeEarly;
    } else {
      return StopVisitRealTimeOnTime;
    }
  }
}

- (NSString *)realTimeInformation:(BOOL)withOriginalTime
{
  switch ([self realTimeStatus]) {
    case StopVisitRealTimeNotApplicable:
      // TODO: Localize
      return @"Scheduled";
      
    case StopVisitRealTimeNotAvailable:
      return NSLocalizedStringFromTableInBundle(@"No real-time available", @"TripKit", [TKTripKit bundle], @"Indicator to show when a service does not have real-time data (even though we usually get it for services like this.)");

    case StopVisitRealTimeCancelled:
      return Loc.Cancelled;
      
    case StopVisitRealTimeOnTime:
      return NSLocalizedStringFromTableInBundle(@"On time", @"TripKit", [TKTripKit bundle], @"Indicator to show when a service is on time according to real-time data.");
      
    case StopVisitRealTimeEarly: {
      NSString *mins = [self minsForRealTimeInformation];
      if (withOriginalTime) {
        NSTimeZone *timeZone = self.stop.region.timeZone;
        NSString *service = [TKStyleManager timeString:self.originalTime forTimeZone:timeZone];
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%1$@ early (%2$@ service)", @"TripKit", [TKTripKit bundle], @"Format for a service's real-time indicator for a service which is early, e.g., '1 min early (1:10 pm service). This means #1 is replaced with something like '1 min' and #2 is replaced with the original time, e.g., '1:10 pm')."), mins, service];
      } else {
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%1$@ early", @"TripKit", [TKTripKit bundle], @"Format for a service's real-time indicator for a service which is early, e.g., '1 min early. This means #1 is replaced with something like '1 min'."), mins];
      }
    }
      
    case StopVisitRealTimeLate: {
      NSString *mins = [self minsForRealTimeInformation];
      if (withOriginalTime) {
        NSTimeZone *timeZone = self.stop.region.timeZone;
        NSString *service = [TKStyleManager timeString:self.originalTime forTimeZone:timeZone];
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%1$@ late (%2$@ service)", @"TripKit", [TKTripKit bundle], @"Format for a service's real-time indicator for a service which is late, e.g., '1 min late (1:10 pm service). This means #1 is replaced with something like '1 min' and #2 is replaced with the original time, e.g., '1:10 pm').") , mins, service];
      } else {
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%1$@ late", @"TripKit", [TKTripKit bundle], @"Format for a service's real-time indicator for a service which is late, e.g., '1 min late. This means #1 is replaced with something like '1 min'") , mins];
      }
    }
      
  }
}

- (NSString *)minsForRealTimeInformation
{
  NSDate *time = self.departure ?: self.arrival;
  NSTimeInterval realTime = [time timeIntervalSince1970];
  realTime -= (NSInteger)realTime % 60;
  NSTimeInterval timeTable = [self.originalTime timeIntervalSince1970];
  timeTable -= (NSInteger)timeTable % 60;
  return [TKObjcDateHelper durationStringForMinutes:(NSInteger) fabs(realTime - timeTable) / 60];
}

- (NSDate *)countdownDate
{
  if (self.service.frequency.integerValue > 0) {
    return nil;
  } else {
    return self.departure;
  }
}

- (NSComparisonResult)compare:(StopVisits *)other
{
  if (self.index && [self.service isEqual:other.service]) {
    return [self.index compare:other.index];
  } else {
    NSDate *time = self.departure ?: self.arrival;
    NSDate *otherTime = other.departure ?: other.arrival;
    return [time compare:otherTime];
  }
}

@end
