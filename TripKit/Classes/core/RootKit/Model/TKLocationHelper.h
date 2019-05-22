//
//  TKLocationHelper.h
//  TripKit
//
//  Created by Adrian Schoenig on 21/10/2013.
//
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TKLocationHelper : NSObject

+ (nullable NSString *)nameFromPlacemark:(CLPlacemark *)placemark;
+ (nullable NSString *)addressForPlacemark:(CLPlacemark *)placemark DEPRECATED_ATTRIBUTE;
+ (nullable NSString *)suburbForPlacemark:(CLPlacemark *)placemark;
+ (nullable NSString *)regionNameForPlacemark:(CLPlacemark *)placemark;

+ (NSString *)expandAbbreviationInAddressString:(NSString *)address;

+ (BOOL)coordinate:(CLLocationCoordinate2D)first isNear:(CLLocationCoordinate2D)second;

@end

NS_ASSUME_NONNULL_END
