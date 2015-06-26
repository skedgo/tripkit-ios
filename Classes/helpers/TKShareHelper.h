//
//  ShareHelper.h
//  TripGo
//
//  Created by Adrian Schoenig on 15/11/2013.
//
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

#import "SGKEnums.h"

@interface TKShareHelper : NSObject

#pragma mark - Meet URL

+ (BOOL)isMeetURL:(NSURL *)url;

+ (NSURL *)meetURLForCoordinate:(CLLocationCoordinate2D)coordinate
                         atTime:(NSDate *)time;

+ (void)meetingDetailsForURL:(NSURL *)url
                     details:(void (^)(CLLocationCoordinate2D coordinate, NSDate *time))detailBlock;


#pragma mark - Query URL

+ (BOOL)isQueryURL:(NSURL *)url;

+ (NSURL *)queryURLForStart:(CLLocationCoordinate2D)start
                        end:(CLLocationCoordinate2D)end
                   timeType:(SGTimeType)timeType
                       time:(NSDate *)time;

+ (void)queryDetailsForURL:(NSURL *)url
                   details:(void (^)(CLLocationCoordinate2D start, CLLocationCoordinate2D end, SGTimeType timeType, NSDate *time))detailBlock;


#pragma mark - Stops & Services

+ (NSURL *)stopURLForStopCode:(NSString *)stopCode
                inRegionNamed:(NSString *)regionName
                       filter:(NSString *)filter;

+ (NSURL *)serviceURLForServiceID:(NSString *)serviceID
                       atStopCode:(NSString *)stopCode
                    inRegionNamed:(NSString *)regionName;

@end
