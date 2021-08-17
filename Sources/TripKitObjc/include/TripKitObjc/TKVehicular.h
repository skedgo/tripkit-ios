//
//  TKVehicular.h
//  TripKit
//
//  Created by Adrian Schoenig on 19/03/2014.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "TKVehicleType.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TKVehicular <NSObject>

/**
 Optional name to use in the UI to refer to this vehicle.
 */
- (nullable NSString *)name;

/**
 What kind of vehicle it is. Required field.
 */
- (TKVehicleType)vehicleType;

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

NS_ASSUME_NONNULL_END
