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

@interface TKShareHelper : NSObject

#pragma mark - Meet URL

+ (BOOL)isMeetURL:(NSURL *)url;

+ (NSURL *)meetURLForCoordinate:(CLLocationCoordinate2D)coordinate
                         atTime:(NSDate *)time;

+ (void)meetingDetailsForURL:(NSURL *)url
               usingGeocoder:(id<SGGeocoder>)geocoder
                     details:(void (^)(CLLocationCoordinate2D coordinate, NSString *name, NSDate *time))detailBlock;


#pragma mark - Query URL

+ (BOOL)isQueryURL:(NSURL *)url;

+ (NSURL *)queryURLForStart:(CLLocationCoordinate2D)start
                        end:(CLLocationCoordinate2D)end
                   timeType:(SGTimeType)timeType
                       time:(NSDate *)time;

+ (BOOL)queryDetailsForURL:(NSURL *)url
             usingGeocoder:(id<SGGeocoder>)geocoder
                   success:(void (^)(CLLocationCoordinate2D start, CLLocationCoordinate2D end, NSString *name, SGTimeType timeType, NSDate *time))success
                   failure:(void (^)())failure;


#pragma mark - Stops

+ (BOOL)isStopURL:(NSURL *)url;

+ (NSURL *)stopURLForStopCode:(NSString *)stopCode
                inRegionNamed:(NSString *)regionName
                       filter:(NSString *)filter;

+ (BOOL)stopDetailsForURL:(NSURL *)url
                  details:(void (^)(NSString *stopCode, NSString *regionName, NSString *filter))detailBlock;

#pragma mark - Services

+ (BOOL)isServicesURL:(NSURL *)url;

+ (NSURL *)serviceURLForServiceID:(NSString *)serviceID
                       atStopCode:(NSString *)stopCode
                    inRegionNamed:(NSString *)regionName;

+ (void)serviceDetailsForURL:(NSURL *)url
                     details:(void (^)(NSString *stopCode, NSString *regionName, NSString *serviceID))detailBlock;

@end
