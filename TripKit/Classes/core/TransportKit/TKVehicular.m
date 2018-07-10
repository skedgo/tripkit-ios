//
//  TKVehicular.m
//  TripKit
//
//  Created by Adrian Schoenig on 19/03/2014.
//
//

#import "TKVehicular.h"

#import <TripKit/TripKit-Swift.h>

#import "TKTransportKit.h"

@interface TKGettingLiftVehicle ()

@property (nonatomic, assign) TKVehicleType vehicleType;

@end

@implementation TKGettingLiftVehicle

+ (TKGettingLiftVehicle *)gettingLiftVehicleOfType:(TKVehicleType)vehicleType
{
  TKGettingLiftVehicle *liftVehicle = [[TKGettingLiftVehicle alloc] init];
  liftVehicle.vehicleType = vehicleType;
  return liftVehicle;
}

#pragma mark - TKVehicular

- (NSString *)name
{
  return nil;
}

@end


@implementation TKVehicularHelper

+ (NSArray *)allVehicleTypeStrings
{
  return @[
           [self stringForVehicleType:TKVehicleType_Bicycle],
           [self stringForVehicleType:TKVehicleType_Car],
           [self stringForVehicleType:TKVehicleType_Motorbike],
           [self stringForVehicleType:TKVehicleType_SUV],
         ];
}

+ (TKVehicleType)vehicleTypeForString:(NSString *)string
{
  if ([string isEqualToString:[self stringForVehicleType:TKVehicleType_Bicycle]])
    return TKVehicleType_Bicycle;
  if ([string isEqualToString:[self stringForVehicleType:TKVehicleType_Car]])
    return TKVehicleType_Car;
  if ([string isEqualToString:[self stringForVehicleType:TKVehicleType_Motorbike]])
    return TKVehicleType_Motorbike;
  if ([string isEqualToString:[self stringForVehicleType:TKVehicleType_SUV]])
    return TKVehicleType_SUV;
  return TKVehicleType_None;
}

+ (NSString *)stringForVehicleType:(TKVehicleType)vehicleType
{
  switch (vehicleType) {
    case TKVehicleType_Bicycle:
      return NSLocalizedStringFromTableInBundle(@"Bicycle", @"Shared", [TKStyleManager bundle], "Type of vehicle : bicycle");
      
    case TKVehicleType_Car:
      return NSLocalizedStringFromTableInBundle(@"Car", @"Shared", [TKStyleManager bundle], "Type of vehicle : car");
      
    case TKVehicleType_Motorbike:
      return NSLocalizedStringFromTableInBundle(@"Motorbike", @"Shared", [TKStyleManager bundle], "Type of vehicle : motorbike");
      
    case TKVehicleType_SUV:
      return NSLocalizedStringFromTableInBundle(@"SUV", @"Shared", [TKStyleManager bundle], @"Sports utility vehicle abbreviation");

    case TKVehicleType_None:
      return nil;
  }
}

+ (TKImage *)iconForVehicle:(id<TKVehicular>)vehicle
{
  if (! [vehicle respondsToSelector:@selector(garage)]
      || ! [vehicle garage]) {
    return [TKStyleManager imageNamed:@"icon-mode-car-pool"];
  }
  
  TKVehicleType vehicleType = [vehicle vehicleType];
  switch (vehicleType) {
    case TKVehicleType_Bicycle:
      return [TKStyleManager imageNamed:@"icon-mode-bicycle"];
      
    case TKVehicleType_Car:
    case TKVehicleType_SUV:
      return [TKStyleManager imageNamed:@"icon-mode-car"];
      
    case TKVehicleType_Motorbike:
      return [TKStyleManager imageNamed:@"icon-mode-motorbike"];
      
    case TKVehicleType_None:
      return nil;
  }
}

+ (NSString *)titleForVehicle:(id<TKVehicular>)vehicle
{
  if (! [vehicle respondsToSelector:@selector(garage)]
      || ! [vehicle garage]) {
    return NSLocalizedStringFromTableInBundle(@"Getting a lift", @"Shared", [TKStyleManager bundle], nil);
  }
  
  NSString *name = [vehicle name];
  if (name.length > 0) {
    return name;
  } else {
    return [self stringForVehicleType:vehicle.vehicleType];
  }
}

+ (NSDictionary *)skedGoFullDictionaryForVehicle:(id<TKVehicular>)vehicle
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:4];
  dict[@"type"] = [self skedGoTypeStringForType:vehicle.vehicleType];
  if ([vehicle respondsToSelector:@selector(vehicleUUID)] && vehicle.vehicleUUID) {
    dict[@"UUID"] = vehicle.vehicleUUID;
  }
  if (vehicle.name) {
    dict[@"name"] = vehicle.name;
  }
  if ([vehicle respondsToSelector:@selector(garage)] && vehicle.garage) {
    dict[@"garage"] = [TKParserHelper dictionaryForAnnotation:vehicle.garage];
  }
  return dict;
}

+ (NSDictionary *)skedGoReferenceDictionaryForVehicle:(id<TKVehicular>)vehicle
{
  if ([vehicle respondsToSelector:@selector(vehicleUUID)] && vehicle.vehicleUUID) {
    return @{@"UUID": vehicle.vehicleUUID};
  } else {
    return @{@"type": [self skedGoTypeStringForType:vehicle.vehicleType]};
  }
}
  
+ (NSString *)skedGoTypeStringForType:(TKVehicleType)vehicleType
{
  switch (vehicleType) {
    case TKVehicleType_Bicycle:    return @"bicycle";
    case TKVehicleType_Motorbike:  return @"motorbike";
    case TKVehicleType_SUV:        return @"4wd";
    default:                      return @"car";
  }
}

@end
