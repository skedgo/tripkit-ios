//
//  ShareHelper.h
//  TripGo
//
//  Created by Adrian Schoenig on 15/11/2013.
//
//

@import Foundation;
@import CoreLocation;
@import SGCoreKit;

@protocol SGGeocoder;

NS_ASSUME_NONNULL_BEGIN

@interface TKShareHelper : NSObject

#pragma mark - Meet URL

+ (BOOL)isMeetURL:(NSURL *)url;

+ (NSURL *)meetURLForCoordinate:(CLLocationCoordinate2D)coordinate
                         atTime:(NSDate *)time;

+ (NSURL *)meetURLForCoordinate:(CLLocationCoordinate2D)coordinate
                         atTime:(NSDate *)time
                        baseURL:(NSString *)baseURL;


#pragma mark - Query URL

+ (BOOL)isQueryURL:(NSURL *)url;

+ (NSURL *)queryURLForStart:(CLLocationCoordinate2D)start
                        end:(CLLocationCoordinate2D)end
                   timeType:(SGTimeType)timeType
                       time:(nullable NSDate *)time;

+ (NSURL *)queryURLForStart:(CLLocationCoordinate2D)start
                        end:(CLLocationCoordinate2D)end
                   timeType:(SGTimeType)timeType
                       time:(nullable NSDate *)time
                    baseURL:(NSString *)baseURL;

#pragma mark - Stops

+ (BOOL)isStopURL:(NSURL *)url;

+ (NSURL *)stopURLForStopCode:(NSString *)stopCode
                inRegionNamed:(NSString *)regionName
                       filter:(nullable NSString *)filter;

+ (NSURL *)stopURLForStopCode:(NSString *)stopCode
                inRegionNamed:(NSString *)regionName
                       filter:(NSString *)filter
                      baseURL:(NSString *)baseURL;

#pragma mark - Services

+ (BOOL)isServicesURL:(NSURL *)url;

+ (NSURL *)serviceURLForServiceID:(NSString *)serviceID
                       atStopCode:(NSString *)stopCode
                    inRegionNamed:(NSString *)regionName;

+ (NSURL *)serviceURLForServiceID:(NSString *)serviceID
                       atStopCode:(NSString *)stopCode
                    inRegionNamed:(NSString *)regionName
                          baseURL:(NSString *)baseURL;

+ (void)serviceDetailsForURL:(NSURL *)url
                     details:(void (^)(NSString *stopCode, NSString *regionName, NSString *serviceID))detailBlock;

@end

NS_ASSUME_NONNULL_END
