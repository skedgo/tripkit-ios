//
//  RouteSection.m
//  TripKit
//
//  Created by Adrian Schönig on 3/03/11.
//  Copyright (c) 2011 SkedGo. All rights reserved.
//

#import "TKSegment.h"

#import <TripKit/TripKit-Swift.h>

NSString *const UninitializedString =  @"UninitializedString";

@interface TKSegment ()

@property (nonatomic, strong) NSString *notes;

@property (nonatomic, copy) NSString *primaryLocationString;
@property (nonatomic, copy) NSString *singleLineInstruction;
@property (nonatomic, copy) NSString *singleLineInstructionWithoutTime;
@property (nonatomic, strong) StopLocation *scheduledStartStop;
@property (nonatomic, assign) TKSegmentOrdering order;
@property (nonatomic, strong) NSDictionary *segmentVisits;
@property (nonatomic, strong) NSArray<TKRegion *> *localRegions;

@property (nonatomic, strong) NSArray *alerts;

@end

@implementation TKSegment

@synthesize trip = _trip;

- (id)init
{
	self = [super init];
	if (self) {
		_primaryLocationString = UninitializedString;
		_singleLineInstruction = UninitializedString;
    _singleLineInstructionWithoutTime = UninitializedString;
    _order = TKSegmentOrderingRegular;
    _alerts = nil;
	}
	return self;
}

- (id)initAsTerminal:(TKSegmentOrdering)order
             atLocation:(id<MKAnnotation>)location
             forTrip:(Trip *)aTrip
{
  NSParameterAssert(aTrip);
  
  if (order == TKSegmentOrderingRegular) {
    ZAssert(false, @"Terminal can't be of regular order");
    return nil;
  }
  
	self = [self init];
	if (self) {
    self.order = order;
    self.trip = aTrip;
    self.start = location;
    self.end = location;
	}
	return self;
}

- (id)initWithReference:(SegmentReference *)aReference
                forTrip:(Trip *)aTrip
{
  NSParameterAssert(aTrip);
  NSParameterAssert(aReference);
  
  self = [self init];
  if (self) {
    self.reference = aReference;
    self.trip = aTrip;
  }
  return self;
}

#pragma mark -

- (void)setTrip:(Trip *)trip {
  _trip = trip;
}

- (TKSegment *)finalSegmentIncludingContinuation
{
	TKSegment *segment = self;
	for (TKSegment *next = [self next];
       next != nil && [next isKindOfClass:[TKSegment class]] && [next isContinuation]; // not sure how next can ever be not a segment (crashlytics #990)
       next = [next next]) {
		segment = next;
	}
	return segment;
}

- (TKSegment *)originalSegmentIncludingContinuation
{
	TKSegment *segment = self;
	for (TKSegment *s = self; s != nil && [s isContinuation]; s = [s previous]) {
		segment = [s previous];
	}
	return segment;
}

- (TKRegion *)startRegion
{
  if (! _localRegions) {
    _localRegions = [self determineRegions];
  }
  return [_localRegions firstObject];
}

- (TKRegion *)endRegion
{
  if (! _localRegions) {
    _localRegions = [self determineRegions];
  }
  return [_localRegions lastObject];
}

- (NSInteger)templateHashCode {
  return self.template.hashCode.integerValue;
}

- (NSString *)titleWithoutTime {
  return [self singleLineInstructionWithoutTime];
}

- (NSString *)departureLocation
{
  return [self.start title];
}

- (NSString *)arrivalLocation:(BOOL)includingContinuation
{
	TKSegment *segment = includingContinuation ? [self finalSegmentIncludingContinuation] : self;
  return [segment.end title];
}

- (NSDate *)departureTime {
  switch (self.order) {
    case TKSegmentOrderingStart:
      return self.trip.departureTime;
    case TKSegmentOrderingRegular:
      return self.reference.startTime;
    case TKSegmentOrderingEnd:
      return self.trip.arrivalTime;
  }
}

- (void)setDepartureTime:(NSDate *)date {
  switch (self.order) {
    case TKSegmentOrderingStart:
      self.trip.departureTime = date;
      return;
    case TKSegmentOrderingRegular:
      self.reference.startTime = date;
      return;
    case TKSegmentOrderingEnd:
      self.trip.arrivalTime = date;
      return;
  }
}

- (void)setArrivalTime:(NSDate *)date {
  switch (self.order) {
    case TKSegmentOrderingStart:
      self.trip.departureTime = date;
      return;
    case TKSegmentOrderingRegular:
      self.reference.endTime = date;
      return;
    case TKSegmentOrderingEnd:
      self.trip.arrivalTime = date;
      return;
  }
}

- (NSDate *)arrivalTime {
  switch (self.order) {
    case TKSegmentOrderingStart:
      return self.trip.departureTime;
    case TKSegmentOrderingRegular:
      return self.reference.endTime;
    case TKSegmentOrderingEnd:
      return self.trip.arrivalTime;
  }
}

- (BOOL)timesAreRealTime
{
  return self.reference.timesAreRealTime;
}

- (Vehicle *)realTimeVehicle
{
  if (self.service) {
    return self.service.vehicle;
  } else {
    return self.reference.realTimeVehicle;
  }
}

- (NSArray <Vehicle *> *)realTimeAlternativeVehicles
{
  if (self.reference.realTimeVehicleAlternatives) {
    return [self.reference.realTimeVehicleAlternatives allObjects];
  } else {
    return @[]; // Not showing alternatives for public transport
  }
}

- (id)payloadForKey:(NSString *)key
{
  return [self.reference payloadForKey:key];
}

- (NSString *)scheduledStartStopCode {
  return self.template.scheduledStartStopCode;
}

- (NSString *)scheduledStartPlatform {
  return self.reference.departurePlatform;
}

- (NSString *)scheduledEndPlatform {
  return self.reference.arrivalPlatform;
}

- (NSDate *)scheduledTimetableStartTime {
  return self.reference.timetableStartTime;
}

- (NSDate *)scheduledTimetableEndTime {
  return self.reference.timetableEndTime;
}


- (StopLocation *)scheduledStartStop
{
	if (_scheduledStartStop != nil)
		return _scheduledStartStop;
	
	// else calculate it
	NSString *code = [self scheduledStartStopCode];
	if (nil == code)
		return nil;
  NSManagedObjectContext *context = [self.template managedObjectContext];
	_scheduledStartStop = [StopLocation fetchStopForStopCode:code
                                             inRegionNamed:self.startRegion.name
                                         requireCoordinate:YES
                                          inTripKitContext:context];
  
  if (! _scheduledStartStop) {
    // create it!
    id<MKAnnotation> start = [self start];
    TKNamedCoordinate *location = [TKNamedCoordinate namedCoordinateForAnnotation:start];
    StopLocation *newStop = [StopLocation fetchOrInsertStopForStopCode:code
                                                              modeInfo:self.modeInfo
                                                            atLocation:location
                                                    intoTripKitContext:context];
    _scheduledStartStop = newStop;
  }
  
	return _scheduledStartStop;
}

- (NSString *)scheduledEndStopCode {
  return self.template.scheduledEndStopCode;
}

- (Service *)service {
	return self.reference.service;
}

- (NSString *)scheduledServiceNumber {
	return self.service.number;
}

- (NSString *)scheduledServiceCode {
	return self.service.code;
}

- (nullable NSString *)ticketWebsiteURLString
{
  return self.reference.ticketWebsiteURLString;
}

- (NSTimeInterval)duration:(BOOL)includingContinuation
{
	TKSegment *segment = includingContinuation ? [self finalSegmentIncludingContinuation] : self;
	return [segment.arrivalTime timeIntervalSinceDate:self.departureTime];
}

- (NSString *)stringForDurationWithoutTraffic {
  NSNumber *rawWithoutTraffic = self.template.durationWithoutTraffic;
  if (! rawWithoutTraffic) {
    return nil;
  }
  
  NSTimeInterval withoutTraffic = rawWithoutTraffic.doubleValue;
  NSTimeInterval withTraffic = [self duration:NO];
  if (withTraffic > withoutTraffic + 60) {
    NSString *durationString = [TKObjcDateHelper durationStringForMinutes:(NSInteger) (withoutTraffic / 60)];
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ w/o traffic", @"TripKit", [TKTripKit bundle], @"Duration without traffic"), durationString];
  } else {
    return nil;
  }
}

- (NSString *)stringForDuration:(BOOL)includingContinuation {
	TKSegment *segment = includingContinuation ? [self finalSegmentIncludingContinuation] : self;
	return [TKObjcDateHelper durationStringForStart:self.departureTime end:segment.arrivalTime];
}

- (NSNumber *)frequency {
	return self.service.frequency;
}

- (NSString *)smsMessage {
	return self.template.smsMessage;
}

- (NSString *)smsNumber {
	return self.template.smsNumber;
}

- (NSArray *)alerts
{
  if (!_alerts) {
    NSArray *arrayHashCodes = self.reference.alertHashCodes;
    if (arrayHashCodes.count == 0) {
      _alerts = @[];
    } else {
      _alerts = [Alert fetchAlertsWithHashCodes:arrayHashCodes
                               inTripKitContext:self.reference.managedObjectContext
                           sortedByDistanceFrom:[self.start coordinate]];
    }
  }
  return _alerts;
}

- (NSArray *)alertsWithLocation
{
  if (self.alerts.count > 0) {
    return [[self alerts] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"location != nil"]];
  } else {
    return @[];
  }
}

- (NSArray *)alertsWithContent
{
  if (self.alerts.count > 0) {
    return [[self alerts] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"text != nil OR url != null"]];
  } else {
    return @[];
  }
}

- (NSArray *)alertsWithAction
{
  if (self.alerts.count > 0) {
    return [[self alerts] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"action != nil"]];
  } else {
    return @[];
  }
}

- (BOOL)usesVisit:(StopVisits *)visit
{
  if (self.segmentVisits) {
    // look up if we visit this stop
    ZAssert(nil != visit, @"No visit provided");
    NSNumber *visitIndicator = self.segmentVisits[visit.stop.stopCode];
    ZAssert(nil != visitIndicator, @"Inconsistency detected!");
    return visitIndicator.boolValue;
  } else {
    return YES;
  }
}

- (BOOL)shouldShowVisit:(StopVisits *)visit
{
  // commented out the following as it looks a bit
  // weird if when we have bus => walk => bus and
  // only the first bus => walk gets a dot
//  if ([TKLocationHelper coordinate:[visit coordinate]
//                            isNear:[self coordinate]]) {
//    return NO; // don't show the visit where we get on
//  }
  
  if (self.segmentVisits) {
    // look up if we visit this stop
    ZAssert(visit, @"No visit provided");
    NSNumber *visitIndicator = self.segmentVisits[visit.stop.stopCode];
    return nil != visitIndicator;
  } else {
    return YES;
  }
}

- (BOOL)matchesVisit:(StopVisits *)visit
{
  TKSegment *segment = self;
  NSString *serviceCodeToMatch = visit.service.code;
  while (segment) {
    if ([serviceCodeToMatch isEqualToString:segment.service.code]) {
      return YES;
    }
    
    // wrap-over
    segment = [segment next];
    if (! segment.isContinuation)
      break;
  }
  return NO;
}

- (TKSegmentWaypoint)guessWaypointTypeForVisit:(StopVisits *)visit
{
  NSTimeInterval duration = [self duration:YES];
  NSDate *gettingOnCutOff = [self.departureTime dateByAddingTimeInterval:duration * 0.3333];
  NSDate *gettingOffCutOff = [self.departureTime dateByAddingTimeInterval:duration * 0.6667];
  NSDate *time = visit.departure ?: visit.arrival;
  if ([time earlierDate:gettingOnCutOff] == time) {
    return TKSegmentWaypointGetOn;
  } else if ([time laterDate:gettingOffCutOff] == time) {
    return TKSegmentWaypointGetOff;
  } else {
    return TKSegmentWaypointUnknown;
  }
}

- (NSString *)modeIdentifier
{
  return [self.template modeIdentifier];
}

- (TKModeInfo *)modeInfo
{
  return [self.template modeInfo];
}

- (NSString *)notes
{
	if (_notes)
		return _notes;
	
  NSString *raw = self.template.notesRaw;
  if (raw.length == 0) {
    return raw;
  }
  
  NSMutableString *notes = [NSMutableString stringWithString:raw];
  BOOL isTimeDependent = [self fillInTemplates:notes inTitle:NO includingTime:YES];
  if (isTimeDependent) {
    return notes;
  } else {
    _notes = notes;
    return _notes;
  }
}

- (NSSet *)shapes {
  return self.template.shapes;
}

- (NSArray *)shortedShapes {
    NSSortDescriptor *indexSort = [[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES];
    return [[self.template.shapes allObjects] sortedArrayUsingDescriptors:@[indexSort]];
}

- (BOOL)isWalking {
  return [self.template isWalking];
}

- (BOOL)isWheelchair {
  return [self.template isWheelchair];
}

- (BOOL)isCycling {
  return [self.template isCycling];
}

- (BOOL)isDriving {
  return [self.template isDriving];
}

- (BOOL)isFlight {
  return [self.template isFlight];
}

- (BOOL)isContinuation {
  return [self.template isContinuation];
}

- (BOOL)hasCarParks {
  return [self.template hasCarParks];
}

- (BOOL)isPlane {
  return [TKTransportModes modeIdentifierIsFlight:self.modeIdentifier];
}

- (BOOL)isPublicTransport {
  return [self.template isPublicTransport];
}

- (BOOL)hasTimetable
{
  return [self isPublicTransport]
          && self.service.frequency == 0
          && ! [self isContinuation]
          && ! [self isPlane]
          && [[TKDLSTable alloc] initFor:self] != nil;
}

- (BOOL)isStationary {
  return self.order != TKSegmentOrderingRegular || [self.template isStationary];
}

- (BOOL)isSelfNavigating {
  return [self.template isSelfNavigating];
}

- (BOOL)isAffectedByTraffic {
  return [self.template isAffectedByTraffic];
}

- (BOOL)isSharedVehicle {
  return [self.template isSharedVehicle];
}

- (BOOL)isImpossible
{
  if (self.order != TKSegmentOrderingRegular) {
    return NO;
  }
  if ([self duration:NO] < 0) {
    return YES;
  }
  
  if (self.next) {
    NSTimeInterval margin = 60;
    NSDate *next = [self.next.departureTime dateByAddingTimeInterval:margin];
    return [self.arrivalTime laterDate:next] == self.arrivalTime;
  } else {
    return NO;
  }
}

- (BOOL)isCanceled
{
  return self.reference.service.isCancelled;
}

- (BOOL)canShowAlternativeLocation
{
  if ([self isSharedVehicle]) {
    return YES; // there are always alternatives for those
  }
  
  return [self.template hasCarParks];
}

#pragma mark - Booking

- (NSString *)bookingTitle
{
  NSDictionary *bookingData = self.reference.bookingData;
  return bookingData[@"title"];
}

- (NSURL *)bookingInternalURL
{
  NSDictionary *bookingData = self.reference.bookingData;
  NSString *URLString = bookingData[@"url"];
  if (URLString) {
    return [NSURL URLWithString:URLString];
  } else {
    return nil;
  }
}

- (NSURL *)bookingQuickInternalURL
{
  NSDictionary *bookingData = self.reference.bookingData;
  NSString *URLString = bookingData[@"quickBookingsUrl"];
  if (URLString) {
    return [NSURL URLWithString:URLString];
  } else {
    return nil;
  }
}

- (NSArray *)bookingExternalActions
{
  NSDictionary *bookingData = self.reference.bookingData;
  return bookingData[@"externalActions"];
}

- (nullable NSDictionary<NSString*, id> *)bookingConfirmationDictionary
{
  NSDictionary *bookingData = self.reference.bookingData;
  return bookingData[@"confirmation"];
}

- (void)resetCaches
{
  _singleLineInstruction = UninitializedString;
  _primaryLocationString = UninitializedString;
}

#pragma mark - Accessors

- (id<MKAnnotation>)start
{
  if (nil == _start) {
    ZAssert(self.order == TKSegmentOrderingRegular, @"Set start + end on terminal segments");
    _start = self.template.start;
  }

  ZAssert(_start != nil, @"Start missing for segment %@ in request %@", self, self.trip.request);
  return _start;
}

- (id<MKAnnotation>)end
{
  if (nil == _end) {
    ZAssert(self.order == TKSegmentOrderingRegular, @"Set start + end on terminal segments");
    _end = self.template.end;
  }

  ZAssert(_end != nil, @"End missing for segment %@ in request %@", self, self.trip.request);
  return _end;
}

- (TKColor *)color
{
  TKColor *serviceColor = self.service.color;
  if (serviceColor) {
    return serviceColor;
  }
  TKColor *modeColor = self.modeInfo.color;
  if (modeColor) {
		return modeColor;
  } else if ([self isPublicTransport]) {
		return [TKColor colorWithRed:143/255.f green:139/255.f blue:138/255.f alpha:1]; // Dark grey
  } else {
    return [TKColor colorWithRed:214/255.f green:214/255.f blue:214/255.f alpha:1]; // Light grey
  }
}

- (NSArray *)dashPattern
{
	NSArray *dashPattern = [self.template dashPattern];
	if (dashPattern)
		return dashPattern;
	else
		return @[@1];
}

#pragma mark - MKAnnotation protocol

- (NSString *)title {
  return [self singleLineInstruction];
}

- (void)setTitle:(NSString *)title
{
#pragma unused(title)
  // just for KVO
}

- (NSString *)subtitle {
	return [self primaryLocationString];
}

- (CLLocationCoordinate2D)coordinate {
  if (self.start) {
    return [self.start coordinate];
  } else {
    return kCLLocationCoordinate2DInvalid;
  }
}

#pragma mark - TKTripSegment

- (nullable NSString *)tripSegmentModeTitle
{
  if (self.reference.service) {
		return self.reference.service.number;
  
  } else if (self.modeInfo.descriptor.length > 0) {
    return self.modeInfo.descriptor;
  
  } else if (![self.trip isMixedModalIgnoringWalking:NO] && self.reference.template.metres) {
    MKDistanceFormatter *formatter = [[MKDistanceFormatter alloc] init];
    return [formatter stringFromDistance:self.reference.template.metres.doubleValue];
    
  } else {
    return nil;
  }
}

- (nullable NSString *)tripSegmentModeSubtitle
{
  if ([self timesAreRealTime]) {
    if ([self isPublicTransport]) {
      return NSLocalizedStringFromTableInBundle(@"Real-time", @"TripKit", [TKTripKit bundle], nil);
    } else {
      return NSLocalizedStringFromTableInBundle(@"Live traffic", @"TripKit", [TKTripKit bundle], nil);
    }
  
  } else if ([self.trip isMixedModalIgnoringWalking:NO] && ![self isPublicTransport]) {
    return [self stringForDuration:YES];
  
  } else if (self.reference.template.metresFriendly) {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterPercentStyle;
    double value = self.reference.template.metresFriendly.doubleValue / self.reference.template.metres.doubleValue;
    NSString *percentage = [formatter stringFromNumber:@(value)];

    if ([self isCycling]) {
      NSString *format = NSLocalizedStringFromTableInBundle(@"%@ cycle friendly", @"TripKit", [TKTripKit bundle], @"Indicator for how cycle-friendly a cycling route is. Placeholder will get replaced with '75%'.");
      return [NSString stringWithFormat:format, percentage];
    } else if ([self isWheelchair]) {
      NSString *format = NSLocalizedStringFromTableInBundle(@"%@ wheelchair friendly", @"TripKit", [TKTripKit bundle], @"Indicator for how wheelchair-friendly a wheeelchair route is. Placeholder will get replaced with '75%'.");
      return [NSString stringWithFormat:format, percentage];
    } else {
      return nil;
    }
  
  } else {
    return nil;
  }
}

- (nullable TKColor *)tripSegmentModeColor
{
  // These are only used in segment views. We only want to
  // colour public transport there.
  if (! [self isPublicTransport]) {
    return nil;
  }
  
  // Prefer service colour over that of the mode itself.
  TKColor *color = self.service.color;
  if (color) {
    return color;
  } else {
    return [self.template.modeInfo color];
  }
}

#pragma mark - Private methods

- (NSUInteger)numberOfStopsIncludingContinuation
{
  NSUInteger stops = 0;
  TKSegment *segment = self;
  while (segment) {
    stops += [segment.reference.serviceStops integerValue];
    
    // wrap-over
    segment = [segment next];
    if (! segment.isContinuation)
      break;
  }
  
  return stops;
}

- (SegmentTemplate *)template
{
  return [self.reference template];
}

- (NSString *)scheduledServiceNumberOrMode
{
	NSString *number = [self scheduledServiceNumber]; // number of this
  if (number.length > 0) {
    return number;
  } else {
    NSString *mode = [self tripSegmentModeTitle]; // mode of the original
    return mode;
  }
}

- (BOOL)fillInTemplates:(NSMutableString *)string
                inTitle:(BOOL)title
          includingTime:(BOOL)includeTime
{
  BOOL isDynamic = NO;
  NSRange range;
  range = [string rangeOfString:@"<NUMBER>"];
  if (range.location != NSNotFound) {
    NSString *replacement = [self scheduledServiceNumberOrMode]?: @"";
    [string replaceCharactersInRange:range withString:replacement];
  }

  range = [string rangeOfString:@"<LINE_NAME>"];
  if (range.location != NSNotFound) {
    NSString *replacement = self.service.lineName ?: @"";
    [string replaceCharactersInRange:range withString:replacement];
  }

	range = [string rangeOfString:@"<DIRECTION>"];
  if (range.location != NSNotFound) {
    NSString *replacement = @"";
    if (self.service.direction) {
      replacement = [NSString stringWithFormat:@"%@: %@", NSLocalizedStringFromTableInBundle(@"Direction", @"TripKit", [TKTripKit bundle], "Destination of the bus"), self.service.direction];
    }
    [string replaceCharactersInRange:range withString:replacement];
	}

  range = [string rangeOfString:@"<LOCATIONS>"];
  if (range.location != NSNotFound) {
    [string replaceCharactersInRange:range withString:@""];
  }

  range = [string rangeOfString:@"<PLATFORM>"];
  if (range.location != NSNotFound) {
    NSString *platform = [self scheduledStartPlatform];
    NSString *replacement;
    if (platform) {
      replacement = platform;
    } else {
      replacement = @"";
    }
    [string replaceCharactersInRange:range withString:replacement];
  }

  range = [string rangeOfString:@"<STOPS>"];
  if (range.location != NSNotFound) {
    NSInteger visited = [self numberOfStopsIncludingContinuation];
    NSString *replacement = [Loc Stops:visited];
    [string replaceCharactersInRange:range withString:replacement];
  }
  
  range = [string rangeOfString:@"<TIME>"];
  if (range.location != NSNotFound) {
    if (includeTime) {
      NSString *timeString = [TKStyleManager timeString:self.departureTime
                                            forTimeZone:self.timeZone];
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
    NSString *durationString = [self stringForDuration:YES];
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
    NSString *durationString = [self stringForDurationWithoutTraffic];
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

#pragma mark - Lazy accessors


- (NSString *)primaryLocationString
{
	if (_primaryLocationString == UninitializedString) {
		// build it
		if (self.order != TKSegmentOrderingRegular) {
			// do nothing
		} else if ([self isStationary] || [self isContinuation]) {
			NSString *departure = [self departureLocation];
			if (departure.length > 0) {
				_primaryLocationString = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"At %@", @"TripKit", [TKTripKit bundle], "'At %location' indicator for parts of a trip that happen at a single location, e.g., waiting at a platform, parking at a car park. (old key: PrimaryLocationStationary)"), departure];
			}
		} else if ([self isPublicTransport]) {
			NSString *departure = [self departureLocation];
			if (departure.length > 0) {
				_primaryLocationString = [Loc FromLocation:departure];
			}
		} else {
			NSString *destination = [self arrivalLocation:YES];
			if (destination.length > 0) {
        _primaryLocationString = [Loc ToLocation: destination];
			}
		}

		if (_primaryLocationString == UninitializedString) {
			_primaryLocationString = nil;
		}
  }
	return _primaryLocationString;
}

- (NSString *)singleLineInstruction
{
	if (_singleLineInstruction == UninitializedString) {
    BOOL isTimeDependent = NO;
    NSString *newString = [self buildSingleLineInstructionIncludingTime:YES isTimeDependent:&isTimeDependent];
    if (isTimeDependent)
      // in this place we can't cache the single line instruction as it's dynamic!
      return newString;
    else {
      // cache it and return it
      _singleLineInstruction = newString;
    }
  }
  return _singleLineInstruction;
}

- (NSString *)singleLineInstructionWithoutTime
{
  if (_singleLineInstructionWithoutTime == UninitializedString) {
    BOOL isTimeDependent = NO;
    NSString *newString = [self buildSingleLineInstructionIncludingTime:NO isTimeDependent:&isTimeDependent];
    if (isTimeDependent)
      // in this place we can't cache the single line instruction as it's dynamic!
      return newString;
    else {
      // cache it and return it
      _singleLineInstructionWithoutTime = newString;
    }
  }
  return _singleLineInstructionWithoutTime;
}

- (NSString *)buildSingleLineInstructionIncludingTime:(BOOL)includeTime isTimeDependent:(BOOL *)isTimeDependent {
  *isTimeDependent = NO;
  NSString *newString = nil;
  
  switch (self.order) {
    case TKSegmentOrderingStart: {
      *isTimeDependent = includeTime && self.trip.departureTimeIsFixed;
      NSString *name = [self.trip.request.fromLocation name];
      if (! name) {
        name = [self.trip.request.fromLocation address];
      }
      
      if ([self matchesQuery]) {
        NSString *time = nil;
        if (*isTimeDependent) {
          time = [TKStyleManager timeString:self.departureTime
                                forTimeZone:self.timeZone];
        }
        
        newString = [Loc LeaveFromLocationNamed:name atTime:time];
      } else {
        newString = [Loc LeaveNearLocationNamed:name];
      }
      
      break;
    }

    case TKSegmentOrderingRegular: {
      if (!self.template.action) {
        return @"";
      }
      NSMutableString *actionRaw = [NSMutableString stringWithString:self.template.action];
      *isTimeDependent = [self fillInTemplates:actionRaw inTitle:YES includingTime:includeTime];
      newString = actionRaw;
      break;
    }
      
    case TKSegmentOrderingEnd: {
      *isTimeDependent = includeTime && self.trip.departureTimeIsFixed;
      NSString *name = [self.trip.request.toLocation name];
      if (! name) {
        name = [self.trip.request.toLocation address];
      }

      if ([self matchesQuery]) {
        NSString *time = nil;
        if (*isTimeDependent) {
          time = [TKStyleManager timeString:self.arrivalTime
                                forTimeZone:self.timeZone];
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

- (NSDictionary *)segmentVisits
{
	if (nil == _segmentVisits) {
    if ([self.service hasServiceData]) { // if we didn't yet fetch multiple visits, we return nil
      NSArray *sortedVisits = self.service.sortedVisits;
      NSMutableDictionary *segmentVisits = [NSMutableDictionary dictionaryWithCapacity:sortedVisits.count];

      NSMutableArray *unvisited = [NSMutableArray arrayWithCapacity:sortedVisits.count];
      
      BOOL isTravelled = NO;
      BOOL isEnd = NO;
      NSString *target = self.scheduledStartStopCode;
      for (StopVisits *visit in sortedVisits) {
        NSString *current = visit.stop.stopCode;
        if (! current) {
          ZAssert(false, @"Visit had bad stop with no code: %@", visit);
          continue;
        }
        
        if ([target isEqualToString:current]) {
          if (NO == isTravelled) {
            // found start
            target = self.scheduledEndStopCode;
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
      
      _segmentVisits = segmentVisits;
    }
	}
	return _segmentVisits;
}

@end
