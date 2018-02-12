//
//  SGLocationHelper.h
//  TripKit
//
//  Created by Adrian Schoenig on 21/10/2013.
//
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

@interface SGLocationHelper : NSObject

+ (NSString *)nameFromPlacemark:(CLPlacemark *)placemark;
+ (NSString *)addressForPlacemark:(CLPlacemark *)placemark;
+ (NSString *)suburbForPlacemark:(CLPlacemark *)placemark;
+ (NSString *)regionNameForPlacemark:(CLPlacemark *)placemark;

+ (NSDictionary *)makeAddrDictFromAppleAddrDict:(NSDictionary *)addressDictionary;

/**
 Modifies the address dictionary and abbreviates any state named.
 @note Currently only works for Australia.
 */
+ (void)abbreviateStateInAddrDict:(NSMutableDictionary *)addrDict;

+ (NSString *)abbreviateState:(NSString *)state;
+ (NSString *)expandAbbreviationInAddressString:(NSString *)address;

+ (BOOL)coordinate:(CLLocationCoordinate2D)first isNear:(CLLocationCoordinate2D)second;

@end
