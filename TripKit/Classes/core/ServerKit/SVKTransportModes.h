//
//  TransportModes.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 26/09/12.
//
//

#import "SGKCrossPlatform.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const SVKTransportModeIdentifierFlight;
FOUNDATION_EXPORT NSString *const SVKTransportModeIdentifierRegularPublicTransport;
FOUNDATION_EXPORT NSString *const SVKTransportModeIdentifierSchoolBuses;
FOUNDATION_EXPORT NSString *const SVKTransportModeIdentifierTaxi;
FOUNDATION_EXPORT NSString *const SVKTransportModeIdentifierAutoRickshaw;
FOUNDATION_EXPORT NSString *const SVKTransportModeIdentifierCar;
FOUNDATION_EXPORT NSString *const SVKTransportModeIdentifierMotorbike;
FOUNDATION_EXPORT NSString *const SVKTransportModeIdentifierBicycle;
FOUNDATION_EXPORT NSString *const SVKTransportModeIdentifierBikeShare;
FOUNDATION_EXPORT NSString *const SVKTransportModeIdentifierWalking;
FOUNDATION_EXPORT NSString *const SVKTransportModeIdentifierWheelchair;

@interface SVKTransportModes : NSObject

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
+ (NSString *)modeImageNameForModeIdentifier:(NSString *)modeIdentifier;

/**
 @return image that stands for the specified transport mode identifier
 */
+ (SGKImage *)imageForModeIdentifier:(NSString *)modeIdentifier;

/**
 Groups the mode identifiers
 
 @param modeIdentifiers A set of all the identifiers to be grouped
 @param addAllGroup     If an extra group which has all the identifiers should be added
 
 @return A set of a set of mode identifiers
 */
+ (NSSet<NSSet<NSString *> *> *)groupedModeIdentifiers:(NSArray<NSString *> *)modeIdentifiers
                                    includeGroupForAll:(BOOL)addAllGroup;

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
