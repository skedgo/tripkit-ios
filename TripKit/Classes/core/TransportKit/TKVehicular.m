//
//  TKVehicular.m
//  TripKit
//
//  Created by Adrian Schoenig on 19/03/2014.
//
//

#import "TKVehicular.h"

#import "TKTripKit.h"
#import "TKTransportKit.h"

@implementation TKVehicularHelper

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
      return NSLocalizedStringFromTableInBundle(@"Bicycle", @"Shared", [TKTripKit bundle], "Text for vehicle of type: Bicycle");
      
    case TKVehicleType_Car:
      return NSLocalizedStringFromTableInBundle(@"Car", @"Shared", [TKTripKit bundle], "Text for vehicle of type: Car");
      
    case TKVehicleType_Motorbike:
      return NSLocalizedStringFromTableInBundle(@"Motorbike", @"Shared", [TKTripKit bundle], "Text for vehicle of type: Motorbike");
      
    case TKVehicleType_SUV:
      return NSLocalizedStringFromTableInBundle(@"SUV", @"Shared", [TKTripKit bundle], "Text for vehicle of type: SUV");

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

@end
