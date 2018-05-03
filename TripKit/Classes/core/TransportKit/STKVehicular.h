//
//  STKVehicular.h
//  TripKit
//
//  Created by Adrian Schoenig on 19/03/2014.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "SGKCrossPlatform.h"

#import "STKVehicleType.h"

NS_ASSUME_NONNULL_BEGIN

@protocol STKVehicular <NSObject>

/**
 Optional name to use in the UI to refer to this vehicle.
 */
- (nullable NSString *)name;

/**
 What kind of vehicle it is. Required field.
 */
- (STKVehicleType)vehicleType;

@optional

/**
 Where this vehicle is garaged. Can be `nil` but the algorithms won't try to
 take it back to the garage then.
 
 @note `nil` is the same as getting a lift
 */
- (nullable id<MKAnnotation>)garage;

/**
 The unique identifier that identifies this vehicle.
 
 @note Getting a lift instances don't have a UUID
 */
- (nullable NSString *)vehicleUUID;

@end


@interface STKGettingLiftVehicle : NSObject <STKVehicular>

+ (STKGettingLiftVehicle *)gettingLiftVehicleOfType:(STKVehicleType)vehicleType;

@end


@interface STKVehicularHelper : NSObject

/**
 @return All valid vehicle type strings in one array, sorted alphabetically.
 */
+ (NSArray<NSString *> *)allVehicleTypeStrings;

/**
 @return Converts the vehicle type string back to a vehicle type
 */
+ (STKVehicleType)vehicleTypeForString:(NSString *)vehicleTypeString;

/**
 @return The vehicle type as a human-readable string.
 */
+ (nullable NSString *)stringForVehicleType:(STKVehicleType)vehicleType;

/**
 @return The vehicle type as an icon.
 */
+ (nullable SGKImage *)iconForVehicle:(id<STKVehicular>)vehicle;

/**
 @return Vehicles name if there's one, otherwise it's type to a string
 */
+ (nullable NSString *)titleForVehicle:(id<STKVehicular>)vehicle;

@end

NS_ASSUME_NONNULL_END
