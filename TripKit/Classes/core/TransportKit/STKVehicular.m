//
//  SGPrivateVehicle.m
//  TripKit
//
//  Created by Adrian Schoenig on 19/03/2014.
//
//

#import "STKVehicular.h"

#import <TripKit/TripKit-Swift.h>

#import "STKTransportKit.h"

@interface STKGettingLiftVehicle ()

@property (nonatomic, assign) STKVehicleType vehicleType;

@end

@implementation STKGettingLiftVehicle

+ (STKGettingLiftVehicle *)gettingLiftVehicleOfType:(STKVehicleType)vehicleType
{
  STKGettingLiftVehicle *liftVehicle = [[STKGettingLiftVehicle alloc] init];
  liftVehicle.vehicleType = vehicleType;
  return liftVehicle;
}

#pragma mark - STKVehicular

- (NSString *)name
{
  return nil;
}

@end


@implementation STKVehicularHelper

+ (NSArray *)allVehicleTypeStrings
{
  return @[
           [self stringForVehicleType:STKVehicleType_Bicycle],
           [self stringForVehicleType:STKVehicleType_Car],
           [self stringForVehicleType:STKVehicleType_Motorbike],
           [self stringForVehicleType:STKVehicleType_SUV],
         ];
}

+ (STKVehicleType)vehicleTypeForString:(NSString *)string
{
  if ([string isEqualToString:[self stringForVehicleType:STKVehicleType_Bicycle]])
    return STKVehicleType_Bicycle;
  if ([string isEqualToString:[self stringForVehicleType:STKVehicleType_Car]])
    return STKVehicleType_Car;
  if ([string isEqualToString:[self stringForVehicleType:STKVehicleType_Motorbike]])
    return STKVehicleType_Motorbike;
  if ([string isEqualToString:[self stringForVehicleType:STKVehicleType_SUV]])
    return STKVehicleType_SUV;
  return STKVehicleType_None;
}

+ (NSString *)stringForVehicleType:(STKVehicleType)vehicleType
{
  switch (vehicleType) {
    case STKVehicleType_Bicycle:
      return NSLocalizedStringFromTableInBundle(@"Bicycle", @"Shared", [SGStyleManager bundle], "Type of vehicle : bicycle");
      
    case STKVehicleType_Car:
      return NSLocalizedStringFromTableInBundle(@"Car", @"Shared", [SGStyleManager bundle], "Type of vehicle : car");
      
    case STKVehicleType_Motorbike:
      return NSLocalizedStringFromTableInBundle(@"Motorbike", @"Shared", [SGStyleManager bundle], "Type of vehicle : motorbike");
      
    case STKVehicleType_SUV:
      return NSLocalizedStringFromTableInBundle(@"SUV", @"Shared", [SGStyleManager bundle], @"Sports utility vehicle abbreviation");

    case STKVehicleType_None:
      return nil;
  }
}

+ (SGKImage *)iconForVehicle:(id<STKVehicular>)vehicle
{
  if (! [vehicle respondsToSelector:@selector(garage)]
      || ! [vehicle garage]) {
    return [SGStyleManager imageNamed:@"icon-mode-car-pool"];
  }
  
  STKVehicleType vehicleType = [vehicle vehicleType];
  switch (vehicleType) {
    case STKVehicleType_Bicycle:
      return [SGStyleManager imageNamed:@"icon-mode-bicycle"];
      
    case STKVehicleType_Car:
    case STKVehicleType_SUV:
      return [SGStyleManager imageNamed:@"icon-mode-car"];
      
    case STKVehicleType_Motorbike:
      return [SGStyleManager imageNamed:@"icon-mode-motorbike"];
      
    case STKVehicleType_None:
      return nil;
  }
}

+ (NSString *)titleForVehicle:(id<STKVehicular>)vehicle
{
  if (! [vehicle respondsToSelector:@selector(garage)]
      || ! [vehicle garage]) {
    return NSLocalizedStringFromTableInBundle(@"Getting a lift", @"Shared", [SGStyleManager bundle], nil);
  }
  
  NSString *name = [vehicle name];
  if (name.length > 0) {
    return name;
  } else {
    return [self stringForVehicleType:vehicle.vehicleType];
  }
}

@end
