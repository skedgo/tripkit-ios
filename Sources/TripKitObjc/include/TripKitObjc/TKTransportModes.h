//
//  TKTransportModes.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 26/09/12.
//
//

#import "TKCrossPlatform.h"

NS_ASSUME_NONNULL_BEGIN

/// Discourage use of these, so remove from documentation.

/// :nodoc:
FOUNDATION_EXPORT NSString *const TKTransportModeIdentifierFlight;
/// :nodoc:
FOUNDATION_EXPORT NSString *const TKTransportModeIdentifierRegularPublicTransport;
/// :nodoc:
FOUNDATION_EXPORT NSString *const TKTransportModeIdentifierSchoolBuses;
/// :nodoc:
FOUNDATION_EXPORT NSString *const TKTransportModeIdentifierTaxi;
/// :nodoc:
FOUNDATION_EXPORT NSString *const TKTransportModeIdentifierAutoRickshaw;
/// :nodoc:
FOUNDATION_EXPORT NSString *const TKTransportModeIdentifierCar;
/// :nodoc:
FOUNDATION_EXPORT NSString *const TKTransportModeIdentifierMotorbike;
/// :nodoc:
FOUNDATION_EXPORT NSString *const TKTransportModeIdentifierBicycle;
/// :nodoc:
FOUNDATION_EXPORT NSString *const TKTransportModeIdentifierBikeShare;
/// :nodoc:
FOUNDATION_EXPORT NSString *const TKTransportModeIdentifierWalking;
/// :nodoc:
FOUNDATION_EXPORT NSString *const TKTransportModeIdentifierWheelchair;

@interface TKTransportModes : NSObject

///-----------------------------------------------------------------------------
/// @name Handling transport mode identifiers
///-----------------------------------------------------------------------------

/**
 @return The default set of mode identifiers
 */
+ (NSArray<NSString *> *)defaultModeIdentifiers;

/**
 @return mode-related part of the image name
 */
+ (nullable NSString *)modeImageNameForModeIdentifier:(NSString *)modeIdentifier;

/**
 @return image that stands for the specified transport mode identifier
 */
+ (TKImage *)imageForModeIdentifier:(NSString *)modeIdentifier;

/**
 @return The generic mode identifier part, e.g., `pt_pub` for `pt_pub_bus`,
    which can be used as routing input
 */
+ (NSString *)genericModeIdentifierForModeIdentifier:(NSString *)modeIdentifier;

+ (BOOL)modeIdentifierIsPublicTransport:(NSString *)modeIdentifier;
+ (BOOL)modeIdentifierIsWalking:(NSString *)modeIdentifier;
+ (BOOL)modeIdentifierIsWheelchair:(NSString *)modeIdentifier;
+ (BOOL)modeIdentifierIsCycling:(NSString *)modeIdentifier;
+ (BOOL)modeIdentifierIsDriving:(NSString *)modeIdentifier;
+ (BOOL)modeIdentifierIsSharedVehicle:(NSString *)modeIdentifier;
+ (BOOL)modeIdentifierIsAffectedByTraffic:(NSString *)modeIdentifier;
+ (BOOL)modeIdentifierIsFlight:(NSString *)modeIdentifier;
+ (BOOL)modeIdentifierIsExpensive:(NSString *)modeIdentifier;

@end

NS_ASSUME_NONNULL_END
