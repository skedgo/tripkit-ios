//
//  StopVisits.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 24/11/12.
//
//

#import "StopVisits.h"

#ifdef TK_NO_FRAMEWORKS
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#endif

#import "SGStyleManager.h"

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
  NSMutableString *output = [NSMutableString stringWithFormat:@"%@ %@", [self.service shortIdentifier], [SGStyleManager timeString:self.departure forTimeZone:timeZone]];
  if ([self.service isRealTime])
    [output appendString:@"*"];
  return output;
}

- (NSString *)secondaryInformation
{
  NSMutableString *subtitle = [NSMutableString string];
  
  // start and end times for frequency-based services
  if (self.service.frequency.integerValue > 0) {
    NSTimeZone *timeZone = self.stop.region.timeZone;
    [subtitle appendFormat:@"%@ - %@",
     [SGStyleManager timeString:self.departure forTimeZone:timeZone],
     [SGStyleManager timeString:self.arrival forTimeZone:timeZone]];
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
  if (!self.service.isRealTimeCapable) {
    return StopVisitRealTime_NotApplicable;
  } else if (!self.service.isRealTime) {
    return StopVisitRealTime_NotAvailable;
  }
  
  if ([self.time isEqual:self.originalTime]) {
    return StopVisitRealTime_OnTime;
  } else {
    // do they also display differently?
    NSTimeInterval realTime = [self.time timeIntervalSince1970];
    realTime -= (NSInteger)realTime % 60;
    
    NSTimeInterval timeTable = [self.originalTime timeIntervalSince1970];
    timeTable -= (NSInteger)timeTable % 60;
    
    if (realTime - timeTable > 59) {
      return StopVisitRealTime_Late;
    } else if (timeTable - realTime > 59) {
      return StopVisitRealTime_Early;
    } else {
      return StopVisitRealTime_OnTime;
    }
  }
}

- (NSString *)realTimeInformation:(BOOL)withOriginalTime
{
  switch ([self realTimeStatus]) {
    case StopVisitRealTime_NotApplicable:
    case StopVisitRealTime_NotAvailable:
      return nil;

    case StopVisitRealTime_OnTime:
      return NSLocalizedStringFromTableInBundle(@"On time", @"TripKit", [TKTripKit bundle], @"Indicator to show when a service is on time according to real-time data.");
      
    case StopVisitRealTime_Early: {
      NSString *mins = [self minsForRealTimeInformation];
      if (withOriginalTime) {
        NSTimeZone *timeZone = self.stop.region.timeZone;
        NSString *service = [SGStyleManager timeString:self.originalTime forTimeZone:timeZone];
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%1$@ early (%2$@ service)", @"TripKit", [TKTripKit bundle], @"Format for a service's real-time indicator for a service which is early, e.g., '1 min early (1:10 pm service). This means #1 is replaced with something like '1 min' and #2 is replaced with the original time, e.g., '1:10 pm')."), mins, service];
      } else {
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%1$@ early", @"TripKit", [TKTripKit bundle], @"Format for a service's real-time indicator for a service which is early, e.g., '1 min early. This means #1 is replaced with something like '1 min'."), mins];
      }
    }
      
    case StopVisitRealTime_Late: {
      NSString *mins = [self minsForRealTimeInformation];
      if (withOriginalTime) {
        NSTimeZone *timeZone = self.stop.region.timeZone;
        NSString *service = [SGStyleManager timeString:self.originalTime forTimeZone:timeZone];
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%1$@ late (%2$@ service)", @"TripKit", [TKTripKit bundle], @"Format for a service's real-time indicator for a service which is late, e.g., '1 min late (1:10 pm service). This means #1 is replaced with something like '1 min' and #2 is replaced with the original time, e.g., '1:10 pm').") , mins, service];
      } else {
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%1$@ late", @"TripKit", [TKTripKit bundle], @"Format for a service's real-time indicator for a service which is late, e.g., '1 min late. This means #1 is replaced with something like '1 min'") , mins];
      }
    }
      
  }
}

- (NSString *)minsForRealTimeInformation
{
  NSTimeInterval realTime = [self.time timeIntervalSince1970];
  realTime -= (NSInteger)realTime % 60;
  NSTimeInterval timeTable = [self.originalTime timeIntervalSince1970];
  timeTable -= (NSInteger)timeTable % 60;
  return [SGKObjcDateHelper durationStringForMinutes:(NSInteger) fabs(realTime - timeTable) / 60];
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
    return [self.time compare:other.time];
  }
}

#pragma mark - TKRealTimeUpdatable

- (BOOL)wantsRealTimeUpdates
{
	return [self.service wantsRealTimeUpdates];
}

- (id)objectForRealTimeUpdates
{
  return self;
}

- (SVKRegion *)regionForRealTimeUpdates
{
  return [self.stop region];
}

#pragma mark ASDirectionalTimePoint

- (NSString *)title
{
	NSTimeZone *timeZone = self.stop.region.timeZone;
	if (self.departure) {
		return [SGStyleManager timeString:self.departure forTimeZone:timeZone];
	} else if (self.arrival) {
		return [SGStyleManager timeString:self.arrival forTimeZone:timeZone];
	} else {
    return self.stop.title;
  }
}

- (NSString *)subtitle
{
  if (self.departure || self.arrival)
    return self.stop.title;
  else
    return nil;
}

- (CLLocationCoordinate2D)coordinate
{
	return self.stop.coordinate;
}

- (void)setTime:(NSDate *)time
{
	ZAssert([time timeIntervalSince1970] > 0, @"Bad time: %@", time);
	self.departure = time;
}

- (NSDate *)time
{
	if (self.departure)
		return self.departure;
	else
		return self.arrival;
}

- (BOOL)timeIsRealTime
{
  return [self.service isRealTime];
}

- (NSTimeZone *)timeZone
{
	return self.stop.region.timeZone;
}

- (BOOL)pointDisplaysImage
{
	return YES;
}

- (SGKImage *)pointImage
{
  return [self.service modeImageFor:SGStyleModeIconTypeListMainMode];
}

- (NSURL *)pointImageURL
{
  return [self.service modeImageURLFor:SGStyleModeIconTypeListMainMode];
}

- (BOOL)canFlipImage
{
	return YES;
}

- (BOOL)isTerminal
{
	return NO;
}

- (BOOL)isDraggable
{
	return NO;
}

#pragma mark - UIActivityItemSource

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController
              subjectForActivityType:(NSString *)activityType
{
#pragma unused(activityViewController, activityType)
  return [self.service modeTitle];
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
#pragma unused(activityViewController)
  return @"";
}

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType
{
#pragma unused(activityViewController, activityType)
  return [NSMutableString stringWithFormat:NSLocalizedStringFromTableInBundle(@"I'll take a %@ at %@ from %@.", @"TripKit", [TKTripKit bundle], "Indication of an activity. (old key: ActivityIndication)"), [self.service shortIdentifier], [SGStyleManager timeString:self.time forTimeZone:self.timeZone], [self.stop name]];
}

#pragma mark - Helpers

//- (void)setFlag:(SGVisitFlag)flag to:(BOOL)value
//{
//	NSInteger flags = self.flags.integerValue;
//	if (value) {
//		self.flags = @(flags | flag);
//	} else {
//		self.flags = @(flags & ~flag);
//	}
//}

@end
