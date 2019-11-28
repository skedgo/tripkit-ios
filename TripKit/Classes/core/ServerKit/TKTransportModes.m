//
//  TransportModes.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 26/09/12.
//
//

#import "TKTransportModes.h"

#import "TKRootKit.h"

#import <TripKit/TripKit-Swift.h>

// all of these need to be unique
static NSString* const kSGTransportModeTypeIdentifierFlight         = @"air";
static NSString* const kSGTransportModeTypeIdentifierRegularPublic  = @"pub";
static NSString* const kSGTransportModeTypeIdentifierLimitedTransit = @"ltd";
static NSString* const kSGTransportModeTypeIdentifierOnDemand       = @"dem";
static NSString* const kSGTransportModeTypeIdentifierTaxi           = @"tax";
static NSString* const kSGTransportModeTypeIdentifierTNC            = @"tnc";
static NSString* const kSGTransportModeTypeIdentifierAutoRickshaw   = @"ars";
static NSString* const kSGTransportModeTypeIdentifierShuttles       = @"shu";
static NSString* const kSGTransportModeTypeIdentifierCar            = @"car";
static NSString* const kSGTransportModeTypeIdentifierCarShare       = @"car-s";
static NSString* const kSGTransportModeTypeIdentifierCarRental      = @"car-r";
static NSString* const kSGTransportModeTypeIdentifierCarPool        = @"car-p";
static NSString* const kSGTransportModeTypeIdentifierMotorbike      = @"mot";
static NSString* const kSGTransportModeTypeIdentifierBicycle        = @"bic";
static NSString* const kSGTransportModeTypeIdentifierBicycleShare   = @"bic-s";
static NSString* const kSGTransportModeTypeIdentifierWalking        = @"wal";
static NSString* const kSGTransportModeTypeIdentifierWheelchair     = @"whe";

NSString *const TKTransportModeIdentifierFlight                    = @"in_air";
NSString *const TKTransportModeIdentifierRegularPublicTransport    = @"pt_pub";
NSString *const TKTransportModeIdentifierSchoolBuses               = @"pt_ltd_SCHOOLBUS";
NSString *const TKTransportModeIdentifierOnDemandTransit           = @"pt_dem";
NSString *const TKTransportModeIdentifierTaxi                      = @"ps_tax";
NSString *const TKTransportModeIdentifierAutoRickshaw              = @"ps_ars";
NSString *const TKTransportModeIdentifierCar                       = @"me_car";
NSString *const TKTransportModeIdentifierMotorbike                 = @"me_mot";
NSString *const TKTransportModeIdentifierBicycle                   = @"cy_bic";
NSString *const TKTransportModeIdentifierBikeShare                 = @"cy_bic-s";
NSString *const TKTransportModeIdentifierWalking                   = @"wa_wal";
NSString *const TKTransportModeIdentifierWheelchair                = @"wa_whe";

@implementation TKTransportModes

#pragma mark - Transport mode identifiers

+ (NSArray *)defaultModeIdentifiers
{
  return @[
           TKTransportModeIdentifierRegularPublicTransport,
           TKTransportModeIdentifierTaxi,
           TKTransportModeIdentifierCar,
           TKTransportModeIdentifierMotorbike,
           TKTransportModeIdentifierBicycle,
           TKTransportModeIdentifierWalking,
           ];
}

+ (NSString *)modeImageNameForModeIdentifier:(NSString *)modeIdentifier
{
  NSString *typeString = [self modeTypeIdentifier:modeIdentifier];
  if ([typeString isEqualToString:kSGTransportModeTypeIdentifierRegularPublic]) {
    return @"public-transport";
  } else if ([typeString isEqualToString:kSGTransportModeTypeIdentifierOnDemand]) {
    return @"shuttlebus";
  } else if ([typeString isEqualToString:kSGTransportModeTypeIdentifierBicycle]) {
    return @"bicycle";
  } else if ([typeString isEqualToString:kSGTransportModeTypeIdentifierBicycleShare]) {
    return @"bicycle-share";
  } else if ([typeString isEqualToString:kSGTransportModeTypeIdentifierCar]) {
    return @"car";
  } else if ([typeString isEqualToString:kSGTransportModeTypeIdentifierCarPool]) {
    return @"car-pool";
  } else if ([typeString isEqualToString:kSGTransportModeTypeIdentifierCarShare]
             || [typeString isEqualToString:kSGTransportModeTypeIdentifierCarRental]) {
    return @"car-share";
  } else if ([typeString isEqualToString:kSGTransportModeTypeIdentifierMotorbike]) {
    return @"motorbike";
  } else if ([typeString isEqualToString:kSGTransportModeTypeIdentifierTaxi]) {
    return @"taxi";
  } else if ([typeString isEqualToString:kSGTransportModeTypeIdentifierTNC]) {
    return @"car-ride-share";
  } else if ([typeString isEqualToString:kSGTransportModeTypeIdentifierAutoRickshaw]) {
    return @"auto-rickshaw";
  } else if ([typeString isEqualToString:kSGTransportModeTypeIdentifierShuttles]) {
    return @"shuttlebus";
  } else if ([typeString isEqualToString:kSGTransportModeTypeIdentifierWalking]) {
    return @"walk";
  } else if ([typeString isEqualToString:kSGTransportModeTypeIdentifierWheelchair]) {
    return @"wheelchair";
  } else if ([typeString isEqualToString:kSGTransportModeTypeIdentifierFlight]) {
    return @"aeroplane";
  } else if ([typeString isEqualToString:kSGTransportModeTypeIdentifierLimitedTransit]) {
    return @"bus";
  } else {
    DLog(@"Unexpected mode: %@", modeIdentifier);
    // fall back to generic type
    if ([modeIdentifier hasPrefix:@"pt_"]) {
      return @"bus";
    } else if ([modeIdentifier hasPrefix:@"ps_"]) {
      return @"taxi";
    } else if ([modeIdentifier hasPrefix:@"me_"]) {
      return @"car";
    } else if ([modeIdentifier hasPrefix:@"cy_"]) {
      return @"bicycle";
    } else if ([modeIdentifier hasPrefix:@"wa_"]) {
      return @"walk";
    } else if ([modeIdentifier hasPrefix:@"in_"]) {
      return @"aeroplane";
    } else {
      ZAssert(false, @"Don't even have fall back!");
      return @"car";
    }
  }
}

+ (TKImage *)imageForModeIdentifier:(NSString *)modeIdentifier
{
  NSString *part = [self modeImageNameForModeIdentifier:modeIdentifier];
  if (part) {
    return [TKStyleManager imageNamed:[NSString stringWithFormat:@"icon-mode-%@", part]];
  } else {
    return nil;
  }
}

+ (NSString *)modeTypeIdentifier:(NSString *)modeIdentifier
{
  NSArray *components = [modeIdentifier componentsSeparatedByString:@"_"];
  if (components.count > 1) {
    return components[1];
  } else {
    return nil;
  }
}

+ (NSString *)genericModeIdentifierForModeIdentifier:(NSString *)modeIdentifier
{
  NSArray *components = [modeIdentifier componentsSeparatedByString:@"_"];
  if (components.count > 1) {
    return [NSString stringWithFormat:@"%@_%@", components[0], components[1]];
  } else {
    return modeIdentifier;
  }
}

+ (NSSet *)groupedModeIdentifiers:(NSArray *)modeIdentifiers
               includeGroupForAll:(BOOL)addAllGroup
{
  // first we group the identifiers
  NSMutableSet *groupedModes = [NSMutableSet setWithCapacity:modeIdentifiers.count + 1];
  TKRegionManager *regionMan = TKRegionManager.shared;
  NSMutableSet *processedModes = [NSMutableSet setWithCapacity:modeIdentifiers.count];
  BOOL includesWalkOnly = false;
  for (NSString *identifier in modeIdentifiers) {
    if ([processedModes containsObject:identifier]) {
      continue; // added it already
    } if ([identifier isEqualToString:TKTransportModeIdentifierFlight] && modeIdentifiers.count > 1) {
      continue; // don't add flights by themselves
    } if ([identifier isEqualToString:TKTransportModeIdentifierWalking] || [identifier isEqualToString:TKTransportModeIdentifierWheelchair]) {
      includesWalkOnly = true;
    }
    
    NSMutableSet *group = [NSMutableSet setWithObject:identifier];
    NSSet *implied = [NSSet setWithArray:[regionMan impliedModeIdentifiers:identifier]];
    [group unionSet:implied];
    
    // see if we can merge this into an existing group
    if ([processedModes intersectsSet:group]) {
      for (NSMutableSet *existingGroup in groupedModes) {
        if ([existingGroup intersectsSet:group]) {
          [existingGroup unionSet:group];
          break;
        }
      }
    } else {
      [groupedModes addObject:group];
    }

    [processedModes unionSet:group];
  }
  
  if (addAllGroup && groupedModes.count > 1 + (includesWalkOnly ? 1 : 0)) {
    [groupedModes addObject:modeIdentifiers];
  }
  
  return groupedModes;
}

+ (BOOL)modeIdentifierIsPublicTransport:(NSString *)modeIdentifier
{
  return [modeIdentifier hasPrefix:@"pt_"];
}

+ (BOOL)modeIdentifierIsCycling:(NSString *)modeIdentifier
{
  if (! modeIdentifier)
    return NO;
  
  NSString *typeIdentifier = [self modeTypeIdentifier:modeIdentifier];
  return [typeIdentifier isEqualToString:kSGTransportModeTypeIdentifierBicycle]
      || [typeIdentifier isEqualToString:kSGTransportModeTypeIdentifierBicycleShare];
}

+ (BOOL)modeIdentifierIsDriving:(NSString *)modeIdentifier
{
  if (! modeIdentifier)
    return NO;
  
  NSString *typeIdentifier = [self modeTypeIdentifier:modeIdentifier];
  return [typeIdentifier isEqualToString:kSGTransportModeTypeIdentifierCar]
      || [typeIdentifier isEqualToString:kSGTransportModeTypeIdentifierCarShare]
      || [typeIdentifier isEqualToString:kSGTransportModeTypeIdentifierCarRental]
      || [typeIdentifier isEqualToString:kSGTransportModeTypeIdentifierMotorbike];
}


+ (BOOL)modeIdentifierIsWalking:(NSString *)modeIdentifier
{
  return [modeIdentifier hasPrefix:@"wa_"];
}

+ (BOOL)modeIdentifierIsWheelchair:(NSString *)modeIdentifier
{
  return [modeIdentifier isEqualToString:TKTransportModeIdentifierWheelchair];
}

+ (BOOL)modeIdentifierIsSharedVehicle:(NSString *)modeIdentifier
{
  NSString *typeIdentifier = [self modeTypeIdentifier:modeIdentifier];
  return [typeIdentifier isEqualToString:kSGTransportModeTypeIdentifierCarShare]
      || [typeIdentifier isEqualToString:kSGTransportModeTypeIdentifierCarRental]
      || [typeIdentifier isEqualToString:kSGTransportModeTypeIdentifierBicycleShare];
}

+ (BOOL)modeIdentifierIsAffectedByTraffic:(NSString *)modeIdentifier
{
  if (! modeIdentifier)
    return NO;
  
  return [modeIdentifier hasPrefix:@"me_"] || [modeIdentifier hasPrefix:@"ps_"];
}

+ (BOOL)modeIdentifierIsExpensive:(NSString *)modeIdentifier
{
  if (! modeIdentifier)
    return NO;
  
  NSString *typeIdentifier = [self modeTypeIdentifier:modeIdentifier];
  return [typeIdentifier isEqualToString:kSGTransportModeTypeIdentifierCarShare]
      || [typeIdentifier isEqualToString:kSGTransportModeTypeIdentifierCarRental]
      || [typeIdentifier isEqualToString:kSGTransportModeTypeIdentifierFlight]
      || [typeIdentifier isEqualToString:kSGTransportModeTypeIdentifierShuttles]
      || [typeIdentifier isEqualToString:kSGTransportModeTypeIdentifierTaxi]
      || [typeIdentifier isEqualToString:kSGTransportModeTypeIdentifierTNC];
}

+ (BOOL)modeIdentifierIsFlight:(NSString *)modeIdentifier
{
  NSString *typeIdentifier = [self modeTypeIdentifier:modeIdentifier];
  return [typeIdentifier isEqualToString:kSGTransportModeTypeIdentifierFlight];
}

@end
