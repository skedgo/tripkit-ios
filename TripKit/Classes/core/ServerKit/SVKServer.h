//
//  SGKServer.h
//  TripKit
//
//  Created by Kuan Lun Huang on 17/02/2015.
//
//

#import <Foundation/Foundation.h>

#import "SGRootKit.h"

#define kSVKServerErrorTypeUser      30051
#define kSVKErrorTypeInternal  30052

NS_ASSUME_NONNULL_BEGIN

typedef void (^SGServerSuccessBlock)(NSInteger status, id _Nullable responseObject, NSData * _Nullable data);
typedef void (^SGServerFullSuccessBlock)(NSInteger status, NSDictionary<NSString *, id> *headers, id _Nullable responseObject, NSData * _Nullable data);
typedef void (^SGServerFailureBlock)(NSError *error);
typedef void (^SGServerGenericBlock)(NSInteger status, NSDictionary<NSString *, id> *headers, id _Nullable responseObject, NSData * _Nullable data, NSError * _Nullable error);

typedef NS_ENUM(NSInteger, SVKServerType) {
  SVKServerTypeProduction = 0,
  SVKServerTypeBeta,
  SVKServerTypeLocal
};

FOUNDATION_EXPORT NSString *const SVKDefaultsKeyProfileTrackUsage;
FOUNDATION_EXPORT NSString *const SVKDefaultsKeyUUID;
FOUNDATION_EXPORT NSString *const SVKDefaultsKeyUserToken;
FOUNDATION_EXPORT NSString *const SVKDefaultsKeyServerType;
FOUNDATION_EXPORT NSString *const SVKDefaultsKeyDevelopmentServer;
FOUNDATION_EXPORT NSString *const SVKDefaultsKeyProfileEnableFlights;

@class SVKRegion;

@interface SVKServer : NSObject

+ (SVKServer *)sharedInstance NS_REFINED_FOR_SWIFT;

+ (nullable id)syncURL:(NSURL *)url timeout:(NSTimeInterval)seconds;

+ (void)GET:(NSURL *)url paras:(nullable NSDictionary<NSString *, id>  *)paras completion:(SGServerGenericBlock)completion;

+ (void)POST:(NSURL *)url paras:(nullable NSDictionary<NSString *, id>  *)paras completion:(SGServerGenericBlock)completion;

+ (NSURLRequest *)GETRequestWithSkedGoHTTPHeadersForURL:(NSURL *)URL paras:(nullable NSDictionary *)paras;

+ (nullable NSURL *)imageURLForIconFileNamePart:(NSString *)fileNamePart
                                     ofIconType:(SGStyleModeIconType)type;

+ (NSString *)developmentServer;

+ (void)updateDevelopmentServer:(NSString *)server;

+ (NSMutableDictionary *)SkedGoHTTPHeaders;

+ (nullable NSString *)userToken;

+ (void)updateUserToken:(nullable NSString *)userToken;

@property (nonatomic, assign) SVKServerType _serverType;

@property (nonatomic, copy) NSString *APIKey;

- (void)registerFileBundle:(NSBundle *)bundle;

- (nullable NSURL *)currentBaseURL;

/**
 Fetched the list of regions and updates `SVKRegionManager`'s cache
 
 Recommended to call from the application delegate.

 @param forceUpdate Set true to force overwriting the internal cache
 */
- (void)updateRegionsForced:(BOOL)forceUpdate NS_SWIFT_NAME(updateRegions(forced:));

- (void)requireRegions:(void(^)(NSError * _Nullable error))completion;

- (void)hitSkedGoWithMethod:(NSString *)method
                       path:(NSString *)path
                 parameters:(nullable NSDictionary<NSString *, id> *)parameters
                     region:(nullable SVKRegion *)region
                    success:(SGServerSuccessBlock)success
                    failure:(SGServerFailureBlock)failure;

- (void)hitSkedGoWithMethod:(NSString *)method
                       path:(NSString *)path
                 parameters:(nullable NSDictionary<NSString *, id> *)parameters
                     region:(nullable SVKRegion *)region
             callbackOnMain:(BOOL)callbackOnMain
                    success:(SGServerSuccessBlock)success
                    failure:(SGServerFailureBlock)failure;

- (void)hitSkedGoWithMethod:(NSString *)method
                       path:(NSString *)path
                 parameters:(nullable NSDictionary<NSString *, id> *)parameters
                    headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                     region:(nullable SVKRegion *)region
             callbackOnMain:(BOOL)callbackOnMain
                    success:(SGServerFullSuccessBlock)success
                    failure:(SGServerFailureBlock)failure;

- (void)hitSkedGoWithMethod:(NSString *)method
                       path:(NSString *)path
                 parameters:(nullable NSDictionary<NSString *, id> *)parameters
                    headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                 customData:(nullable NSData*)customData
                     region:(nullable SVKRegion *)region
             callbackOnMain:(BOOL)callbackOnMain
                    success:(SGServerFullSuccessBlock)success
                    failure:(SGServerFailureBlock)failure;

- (nullable id)initiateSyncRequestWithMethod:(NSString *)method
                                        path:(NSString *)path
                                  parameters:(nullable NSDictionary<NSString *, id>  *)parameters
                                      region:(nullable SVKRegion *)region;

@end

NS_ASSUME_NONNULL_END
