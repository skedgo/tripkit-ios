//
//  CalendarManager.m
//  TripKit
//
//  Created by Adrian Schönig on 28/10/11.
//  Copyright (c) 2011 SkedGo. All rights reserved.
//

#import "SGCalendarManager.h"

#import "TKTripKit.h"
#import "TripKit/TripKit-Swift.h"

#import "SGAutocompletionResult.h"

typedef void (^SGCalendarResultsBlock)(NSString *string, NSArray *results);

@implementation SGCalendarManager

+ (SGCalendarManager *)sharedInstance
{
  static dispatch_once_t pred = 0;
  __strong static id _sharedObject = nil;
  dispatch_once(&pred, ^{
    _sharedObject = [[self alloc] init];
  });
  return _sharedObject;
}


- (id)init {
  self = [super init];
  if (self) {
    self.eventStore = [[EKEventStore alloc] init];
  }
  return self;
}

#pragma mark - Public methods

/* title is: <event title> (<weekday>, <month> <day> from/till <time>)
 */
+ (NSString *)titleStringForEvent:(EKEvent *)event
{
  NSString *title = event.title ?: @"Event";
  NSMutableString *string = [NSMutableString stringWithString:title];
  
  [string appendString:@" ("];
  
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"EEE, dd MMM, h a"];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setDoesRelativeDateFormatting:YES];
  dateFormatter.locale = [SGStyleManager applicationLocale];
	
	if(event.timeZone)
		[dateFormatter setTimeZone:event.timeZone];
	
  [string appendString: [dateFormatter stringFromDate:event.startDate]];
  
	
  [string appendString:@")"];
  return string;
}

- (NSArray *)fetchEventsBetweenDate:(NSDate *)startDate
                         andEndDate:(NSDate *)endDate
                      fromCalendars:(nullable NSArray *)calendarsOrNil
{
  // Create the predicate.
  NSPredicate *predicate = [self.eventStore predicateForEventsWithStartDate:startDate
																																		endDate:endDate
																																	calendars:calendarsOrNil];
  
  // Fetch all events that match the predicate.
  return [self.eventStore eventsMatchingPredicate:predicate];
}


/* Fetches and returns all the users events between (roughly) yesterday and 1 week from now.
 */
- (NSArray *)fetchUpcomingEvents
{
  NSDate *previousMidnight = [[NSDate date] dateAtMidnightInTimeZone:[NSTimeZone defaultTimeZone]];
  NSDate *startDate = [previousMidnight dateByAddingTimeInterval:-24 * 60 * 60];
  NSDate *endDate = [previousMidnight dateByAddingTimeInterval:7 * 24 * 60 * 60];
	return [self fetchEventsBetweenDate:startDate andEndDate:endDate fromCalendars:nil];
}

- (NSArray *)fetchEventsMatchingString:(NSString *)string
{
  if (! [self isAuthorized]) {
    return @[];
  }
  
  NSArray *allEvents = [self fetchUpcomingEvents];
  NSMutableArray *matches = [NSMutableArray arrayWithCapacity:5];
  NSString *search = string.lowercaseString;
  for (EKEvent *event in allEvents) {
    if ([event.location.lowercaseString rangeOfString:search].location != NSNotFound
        || [event.title.lowercaseString rangeOfString:search].location != NSNotFound)
      [matches addObject:event];
  }
  return matches;
}


- (void)fetchEventsMatchingString:(NSString *)string
                       completion:(SGCalendarResultsBlock)block
{
  if (! [self isAuthorized]) {
    block(string, @[]);
    return;
  }
	
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    NSArray *allEvents = [self fetchUpcomingEvents];
    NSMutableArray *matches = [NSMutableArray arrayWithCapacity:5];
    for (EKEvent *event in allEvents) {
      if ([event.location.lowercaseString hasPrefix:string.lowercaseString] || [event.title.lowercaseString hasPrefix:string.lowercaseString])
        [matches addObject:event];
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
      block(string, matches);
    });
  });
}


- (EKEvent *)eventForIdentifier:(NSString *)identifier
{
  if (! [self isAuthorized]) {
    return nil;
  }
  
  return [self.eventStore eventWithIdentifier:identifier];
}


#pragma mark - SGPermissionManager implementations

- (BOOL)featureIsAvailable
{
  return YES;
}

- (BOOL)authorizationRestrictionsApply
{
  return [self.eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)];
}

- (SGAuthorizationStatus)authorizationStatus
{
  if ([self authorizationRestrictionsApply]) {
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
    switch (status) {
      case EKAuthorizationStatusAuthorized:
        return SGAuthorizationStatusAuthorized;
      case EKAuthorizationStatusDenied:
        return SGAuthorizationStatusDenied;
      case EKAuthorizationStatusRestricted:
        return SGAuthorizationStatusRestricted;
      case EKAuthorizationStatusNotDetermined:
        return SGAuthorizationStatusNotDetermined;
    }
  }
  
  // authorized by default otherwise
  return SGAuthorizationStatusAuthorized;
}

- (void)askForPermission:(void (^)(BOOL enabled))completion
{
  ZAssert(! [self isAuthorized], @"Authorized already!");
  if (! [self authorizationRestrictionsApply])
    return;
  
  dispatch_queue_t originalQueue = dispatch_get_main_queue();

  EKEventStore *oldStore = self.eventStore;
  self.eventStore = nil;
  [oldStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
#pragma unused(error)
    self.eventStore = [[EKEventStore alloc] init];
    dispatch_sync(originalQueue, ^{
      completion(granted);
    });
  }];
}

- (NSString *)authorizationAlertText
{
  return NSLocalizedStringFromTableInBundle(@"You previously denied this app access to your calendar. Please go to the Settings app > Privacy > Calendar and authorise this app to use this feature.", @"Shared", [SGStyleManager bundle], @"Calendar authorisation needed text");
}

#pragma mark - SGAutocompletionDataProvider

- (SGAutocompletionDataProviderResultType)resultType
{
  return SGAutocompletionDataProviderResultTypeLocation;
}

- (NSArray *)autocompleteFast:(NSString *)string forMapRect:(MKMapRect)mapRect
{
#pragma unused(mapRect) // no filtering based on map rect for events
  
  NSArray<EKEvent *> *events;
  if (string.length == 0) {
    events = [self fetchDefaultEvents];
  } else {
    events = [self fetchEventsMatchingString:string];
  }
  
  return [SGCalendarManager autocompletionResultsForEvents:events searchTerm:string];
}

- (id<MKAnnotation>)annotationForAutocompletionResult:(SGAutocompletionResult *)result
{
  if ([result.object isKindOfClass:[EKEvent class]]) {
    EKEvent *event = result.object;
    return [[SGKNamedCoordinate alloc] initWithName:[SGCalendarManager titleStringForEvent:event]
                                           address:event.location];
  } else {
    ZAssert(false, @"Unexpected object: %@", result.object);
    return nil;
  }
}

- (NSString *)additionalActionString
{
#if TARGET_OS_IPHONE
  if ([self isAuthorized]) {
    return nil;
  } else {
    return NSLocalizedStringFromTableInBundle(@"Include events", @"Shared", [SGStyleManager bundle], @"Include events.");
  }
#else
  return nil;
#endif
}

- (void)additionalAction:(SGAutocompletionDataActionBlock)actionBlock
{
#if TARGET_OS_IPHONE
  [self tryAuthorizationForSender:nil
                 inViewController:nil
                       completion:^(BOOL enabled) {
    actionBlock(enabled);
  }];
#endif
}

@end
