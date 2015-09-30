//
//  BaseSegment.m
//  TripGo
//
//  Created by Adrian Schönig on 9/05/12.
//  Copyright (c) 2012 SkedGo. All rights reserved.
//

#import "SegmentTemplate.h"

#import "TKTripKit.h"

enum {
  SGSegmentTemplateFlagIsContinuation = 1 << 0,
  SGSegmentTemplateFlagHasCarParks    = 1 << 1,
};
typedef NSUInteger SGSegmentTemplateFlag;


@interface SegmentTemplate ()

@end

@implementation SegmentTemplate

@dynamic action;
@dynamic bearing;
@dynamic data;
@dynamic flags;
@dynamic durationWithoutTraffic;
@dynamic hashCode;
@dynamic modeIdentifier;
@dynamic scheduledStartStopCode, scheduledEndStopCode;
@dynamic smsMessage, smsNumber;
@dynamic segmentType;
@dynamic notesRaw;
@dynamic visibility;
@dynamic startLocation, endLocation;
@dynamic toDelete;
@dynamic shapes;
@dynamic references;

#pragma mark - Public methods

+ (BOOL)segmentTemplateHashCode:(NSNumber *)hashCode
         existsInTripKitContext:(NSManagedObjectContext *)tripKitContext
{
  BOOL hashCodeExists = NO;
	NSPredicate *equalHashCode = [NSPredicate predicateWithFormat:@"hashCode == %@ AND toDelete = NO", hashCode];
	hashCodeExists = [tripKitContext containsObjectForEntityClass:[SegmentTemplate class] withPredicate:equalHashCode];
  return hashCodeExists;
}

+ (instancetype)fetchSegmentTemplateWithHashCode:(NSNumber *)hashCode
                                inTripKitContext:(NSManagedObjectContext *)tripKitContext
{
  NSSet *templates = [tripKitContext fetchObjectsForEntityClass:self withPredicate:[NSPredicate predicateWithFormat:@"hashCode == %@ AND toDelete = NO", hashCode]];
  return [templates anyObject];
}


- (id<MKAnnotation>)endWaypoint:(BOOL)atStart
{
	// get the first or last travelled shape
  Shape *shape = [Shape fetchTravelledShapeForTemplate:self
                                               atStart:atStart];
  if (shape) {
    if (atStart) {
      return shape.start;
    } else {
      return shape.end;
    }
  } else {
    return nil;
  }
}

- (BOOL)isWalking {
  return [SVKTransportModes modeIdentifierIsWalking:self.modeIdentifier];
}

- (BOOL)isCycling {
  return [SVKTransportModes modeIdentifierIsCycling:self.modeIdentifier];
}

- (BOOL)isDriving {
  return [SVKTransportModes modeIdentifierIsDriving:self.modeIdentifier];
}

- (BOOL)isSharedVehicle {
  return [SVKTransportModes modeIdentifierIsSharedVehicle:self.modeIdentifier];
}

- (BOOL)isPublicTransport {
  return self.segmentType.integerValue == BHSegmentTypeScheduled;
}

- (BOOL)isStationary {
  return self.segmentType.integerValue == BHSegmentTypeStationary;
}

- (BOOL)isSelfNavigating {
  return [SVKTransportModes modeIdentifierIsSelfNavigating:self.modeIdentifier];
}

- (BOOL)isFlight {
  return [SVKTransportModes modeIdentifierIsFlight:self.modeIdentifier];
}

- (NSArray *)dashPattern
{
  STKParserHelperModeGroup group;
  if ([self isWalking]) {
    group = STKParserHelperModeGroupWalking;
  } else if (NO == [self isPublicTransport] && NO == [self isStationary]) {
    group = STKParserHelperModeGroupTransit;
  } else {
    group = STKParserHelperModeGroupVehicle;
  }
  return [STKParserHelper dashPatternForModeGroup:group];
}

#pragma mark - Convenience accessors

- (void)setModeInfo:(ModeInfo *)modeInfo
{
  [self setData:modeInfo forKey:@"modeInfo"];
}

- (ModeInfo *)modeInfo
{
  return [self dataForKey:@"modeInfo"];
}

- (void)setMiniInstruction:(STKMiniInstruction *)miniInstruction
{
  [self setData:miniInstruction forKey:@"miniInstruction"];
}

- (STKMiniInstruction *)miniInstruction
{
  return [self dataForKey:@"miniInstruction"];
}

- (void)setDisclaimer:(NSString *)disclaimer
{
  [self setData:disclaimer forKey:@"disclaimer"];
}

- (NSString *)disclaimer
{
  return [self dataForKey:@"disclaimer"];
}

- (void)setContinuation:(BOOL)continuation
{
  [self setFlag:SGSegmentTemplateFlagIsContinuation to:continuation];
}

- (BOOL)isContinuation
{
  return [self hasFlag:SGSegmentTemplateFlagIsContinuation];
}

- (void)setHasCarParks:(BOOL)hasCarParks
{
  [self setFlag:SGSegmentTemplateFlagHasCarParks to:hasCarParks];
}

- (BOOL)hasCarParks
{
  return [self hasFlag:SGSegmentTemplateFlagHasCarParks];
}

#pragma mark - Data

- (id)dataForKey:(NSString *)key
{
  NSDictionary *dataDictionary = [self mutableDataDictionary];
  if (dataDictionary) {
    return dataDictionary[key];
  } else {
    return nil;
  }
}

- (void)setData:(id)data forKey:(NSString *)key
{
  if ([data conformsToProtocol:@protocol(NSCoding)]) {
    NSMutableDictionary *mutable = [self mutableDataDictionary];
    mutable[key] = data;
    [self setMutableDataDictionary:mutable];
    
  } else if (data == nil) {
    NSMutableDictionary *mutable = [self mutableDataDictionary];
    [mutable removeObjectForKey:key];
    [self setMutableDataDictionary:mutable];
  }
}

- (void)setMutableDataDictionary:(NSMutableDictionary *)mutable
{
  self.data = [NSKeyedArchiver archivedDataWithRootObject:mutable];
}

- (NSMutableDictionary *)mutableDataDictionary
{
  if ([self.data isKindOfClass:[NSMutableDictionary class]]) { // Deprecated
    return self.data;
    
  } else if ([self.data isKindOfClass:[NSDictionary class]]) { // Deprecated
    return [NSMutableDictionary dictionaryWithDictionary:self.data];
    
  } else if ([self.data isKindOfClass:[NSData class]]) {
    id object = [NSKeyedUnarchiver unarchiveObjectWithData:self.data];
    if ([object isKindOfClass:[NSMutableDictionary class]]) {
      return object;
    } else {
      ZAssert(false, @"Unexpected data: %@", self.data);
    }
  }
  return [NSMutableDictionary dictionaryWithCapacity:1];
}


#pragma mark - Flags

- (BOOL)hasFlag:(SGSegmentTemplateFlag)flag
{
  return 0 != (self.flags.integerValue & flag);
}

- (void)setFlag:(SGSegmentTemplateFlag)flag to:(BOOL)value
{
  SGSegmentTemplateFlag flags = (SGSegmentTemplateFlag) self.flags.integerValue;
  if (value) {
    self.flags = @(flags | flag);
  } else {
    self.flags = @(flags & ~flag);
  }
}


@end
