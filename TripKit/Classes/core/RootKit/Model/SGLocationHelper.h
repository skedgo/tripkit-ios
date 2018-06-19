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

+ (NSString *)expandAbbreviationInAddressString:(NSString *)address;

+ (BOOL)coordinate:(CLLocationCoordinate2D)first isNear:(CLLocationCoordinate2D)second;

@end
