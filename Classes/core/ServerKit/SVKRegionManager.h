//
//  RegionManager.h
//  TripGo
//
//  Created by Adrian Schönig on 24/05/12.
//  Copyright (c) 2012 SkedGo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "SVKServerKit.h"
#import "SGKCrossPlatform.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const RegionManagerRegionsUpdatedNotification;

@interface SVKRegionManager : NSObject

+ (SVKRegionManager *)sharedInstance;

- (BOOL)hasRegions;

- (void)updateRegions:(NSArray<SVKRegion *> *)regions
          modeDetails:(NSDictionary<NSString *, id>*)modeDetails
             hashCode:(NSInteger)hashCode;

/**
 @returns Array of `SVKRegion` instances if regions are fetched already, `nil` otherwise.
 */
- (nullable NSArray<SVKRegion *> *)regions;

- (nullable NSNumber *)regionsHash;

- (BOOL)coordinateIsPartOfAnyRegion:(CLLocationCoordinate2D)coordinate;

/**
 @return If set of matching regions for the coordinate region include the provided coordinate.
 */
- (BOOL)regionsForCoordinateRegion:(MKCoordinateRegion)coordinateRegion
                 includeCoordinate:(CLLocationCoordinate2D)coordinate;

/**
 @return A matching local region or the shared instance of `SVKInternationalRegion` if coordinate region falls outside local regions.
 */
- (SVKRegion *)regionForCoordinateRegion:(MKCoordinateRegion)coordinateRegion;

/**
 * Used to check if user can route in that area.
 */
- (BOOL)mapRectIsForAnyRegion:(MKMapRect)mapRect;

/**
 * Used to check if overlay should be shown to request that area.
 */
- (BOOL)mapRectIntersectsAnyRegion:(MKMapRect)mapRect;

/**
 @param modeIdentifier The mode identifier for which you want the title
 @return Yhe title as defined by the server
 */
- (NSString *)titleForModeIdentifier:(NSString *)modeIdentifier;

- (nullable NSURL *)imageURLForModeIdentifier:(nullable NSString *)modeIdentifier
                                   ofIconType:(SGStyleModeIconType)type;

/**
 @param modeIdentifier The mode identifier for which you want the official website URL
 @return The URL as defined by the server
 */
- (nullable NSURL *)websiteURLForModeIdentifier:(NSString *)modeIdentifier;

/**
 @param modeIdentifier The mode identifier for which you want the official color
 @return The color as defined by the server
 */
- (nullable SGKColor *)colorForModeIdentifier:(NSString *)modeIdentifier;

/**
 @return If specified mode identifier is required and can't get disabled.
 */
- (BOOL)modeIdentifierIsRequired:(NSString *)modeIdentifier;

/**
 @return List of modes that this mode implies, i.e., enabling the specified modes should also enable all the returned modes.
 */
- (nullable NSArray<NSString *> *)impliedModeIdentifiers:(NSString *)modeIdentifier;

/**
 @return List of modes that are dependent on this mode, i.e., disabling this mode should also disable all the returned modes.
 */
- (nullable NSArray<NSString *> *)dependentModeIdentifiers:(NSString *)modeIdentifiers;

// For updating the cache
+ (NSURL *)cacheURL;

@end

NS_ASSUME_NONNULL_END
