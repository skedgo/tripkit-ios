//
//  ShareHelper.h
//  TripGo
//
//  Created by Adrian Schoenig on 15/11/2013.
//
//

@import Foundation;
@import CoreLocation;
@import SkedGoKit;

@protocol SGGeocoder;

NS_ASSUME_NONNULL_BEGIN

@interface TKShareHelper : NSObject

#pragma mark - Meet URL

+ (BOOL)isMeetURL:(NSURL *)url;

+ (NSURL *)meetURLForCoordinate:(CLLocationCoordinate2D)coordinate
                         atTime:(NSDate *)time;

+ (void)meetingDetailsForURL:(NSURL *)url
               usingGeocoder:(id<SGGeocoder>)geocoder
                     details:(void (^)(CLLocationCoordinate2D coordinate, NSString * _Nullable name, NSDate *time))detailBlock;


#pragma mark - Query URL

+ (BOOL)isQueryURL:(NSURL *)url;

+ (NSURL *)queryURLForStart:(CLLocationCoordinate2D)start
                        end:(CLLocationCoordinate2D)end
                   timeType:(SGTimeType)timeType
                       time:(nullable NSDate *)time;

+ (BOOL)queryDetailsForURL:(NSURL *)url
             usingGeocoder:(id<SGGeocoder>)geocoder
                   success:(void (^)(CLLocationCoordinate2D start, CLLocationCoordinate2D end, NSString * _Nullable name, SGTimeType timeType, NSDate * _Nullable time))success
                   failure:(void (^)())failure;


#pragma mark - Stops

+ (BOOL)isStopURL:(NSURL *)url;

+ (NSURL *)stopURLForStopCode:(NSString *)stopCode
                inRegionNamed:(NSString *)regionName
                       filter:(nullable NSString *)filter;

+ (BOOL)stopDetailsForURL:(NSURL *)url
                  details:(void (^)(NSString *stopCode, NSString *regionName, NSString * _Nullable filter))detailBlock;

#pragma mark - Services

+ (BOOL)isServicesURL:(NSURL *)url;

+ (NSURL *)serviceURLForServiceID:(NSString *)serviceID
                       atStopCode:(NSString *)stopCode
                    inRegionNamed:(NSString *)regionName;

+ (void)serviceDetailsForURL:(NSURL *)url
                     details:(void (^)(NSString *stopCode, NSString *regionName, NSString *serviceID))detailBlock;

@end

NS_ASSUME_NONNULL_END
