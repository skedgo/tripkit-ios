//
//  BaseSegment.m
//  TripKit
//
//  Created by Adrian Schönig on 9/05/12.
//  Copyright (c) 2012 SkedGo. All rights reserved.
//

#import "SegmentTemplate.h"

#import "TripKit/TripKit-Swift.h"

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
@dynamic metres, metresFriendly, metresUnfriendly, metresDismount;
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
  Shape *shape = [Shape
                  fetchTravelledShapeForTemplate:self
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

- (BOOL)isWheelchair {
  return [SVKTransportModes modeIdentifierIsWheelchair:self.modeIdentifier];
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
  return self.segmentType.integerValue == TKSegmentTypeScheduled;
}

- (BOOL)isStationary {
  return self.segmentType.integerValue == TKSegmentTypeStationary;
}

- (BOOL)isSelfNavigating {
  return ![self isStationary] && [SVKTransportModes modeIdentifierIsSelfNavigating:self.modeIdentifier];
}

- (BOOL)isAffectedByTraffic {
  return ![self isStationary] && [SVKTransportModes modeIdentifierIsAffectedByTraffic:self.modeIdentifier];
}

- (BOOL)isFlight {
  return [SVKTransportModes modeIdentifierIsFlight:self.modeIdentifier];
}

- (NSArray *)dashPattern
{
  if (self.modeInfo.color) {
    return @[@1]; // no dashes if we have a dedicated color
  }
  
  SVKParserHelperMode group;
  if ([self isWalking]) {
    group = SVKParserHelperModeWalking;
  } else if (NO == [self isPublicTransport] && NO == [self isStationary]) {
    group = SVKParserHelperModeTransit;
  } else {
    group = SVKParserHelperModeVehicle;
  }
  return [SVKParserHelper dashPatternForModeGroup:group];
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
