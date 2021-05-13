//
//  TKServer.h
//  TripKit
//
//  Created by Kuan Lun Huang on 17/02/2015.
//
//

#import <Foundation/Foundation.h>

#import "TKRootKit.h"

#define kTKServerErrorTypeUser      30051
#define kTKErrorTypeInternal  30052

NS_ASSUME_NONNULL_BEGIN

typedef void (^TKServerSuccessBlock)(NSInteger status, id _Nullable responseObject, NSData * _Nullable data);
typedef void (^TKServerFullSuccessBlock)(NSInteger status, NSDictionary<NSString *, id> *headers, id _Nullable responseObject, NSData * _Nullable data);
typedef void (^TKServerFailureBlock)(NSError *error);
typedef void (^TKServerGenericBlock)(NSInteger status, NSDictionary<NSString *, id> *headers, id _Nullable responseObject, NSData * _Nullable data, NSError * _Nullable error);

/// :nodoc:
FOUNDATION_EXPORT NSString *const TKDefaultsKeyUserToken;
/// :nodoc:
FOUNDATION_EXPORT NSString *const TKDefaultsKeyDevelopmentServer;

@class TKRegion;

/// Encapsulates the logic for talking to SkedGo's servers
@interface TKServer : NSObject

+ (TKServer *)sharedInstance NS_REFINED_FOR_SWIFT;

+ (nullable id)syncURL:(NSURL *)url timeout:(NSTimeInterval)seconds;

+ (void)GET:(NSURL *)url paras:(nullable NSDictionary<NSString *, id>  *)paras completion:(TKServerGenericBlock)completion;

+ (void)POST:(NSURL *)url paras:(nullable NSDictionary<NSString *, id>  *)paras completion:(TKServerGenericBlock)completion;

+ (NSURLRequest *)GETRequestWithSkedGoHTTPHeadersForURL:(NSURL *)URL paras:(nullable NSDictionary *)paras;

+ (nullable NSString *)developmentServer;

+ (void)updateDevelopmentServer:(nullable NSString *)server;

+ (nullable NSString *)xTripGoVersion;

+ (NSMutableDictionary *)SkedGoHTTPHeaders;

+ (nullable NSString *)userToken;

+ (void)updateUserToken:(nullable NSString *)userToken;

@property (nonatomic, copy) NSString *APIKey;

- (void)registerFileBundle:(NSBundle *)bundle;

- (NSURL *)fallbackBaseURL;

/// :nodoc:
- (nullable NSURL *)baseURLForRegion:(nullable TKRegion *)region index:(NSUInteger)index;

/**
 Fetched the list of regions and updates `TKRegionManager`'s cache
 
 Recommended to call from the application delegate.

 @param forceUpdate Set true to force overwriting the internal cache
 */
- (void)updateRegionsForced:(BOOL)forceUpdate NS_SWIFT_NAME(updateRegions(forced:));

- (void)requireRegions:(void(^)(NSError * _Nullable error))completion;

- (void)hitSkedGoWithMethod:(NSString *)method
                       path:(NSString *)path
                 parameters:(nullable NSDictionary<NSString *, id> *)parameters
                     region:(nullable TKRegion *)region
                    success:(TKServerSuccessBlock)success
                    failure:(TKServerFailureBlock)failure;

- (void)hitSkedGoWithMethod:(NSString *)method
                       path:(NSString *)path
                 parameters:(nullable NSDictionary<NSString *, id> *)parameters
                     region:(nullable TKRegion *)region
             callbackOnMain:(BOOL)callbackOnMain
                    success:(TKServerSuccessBlock)success
                    failure:(TKServerFailureBlock)failure;

- (void)hitSkedGoWithMethod:(NSString *)method
                       path:(NSString *)path
                 parameters:(nullable NSDictionary<NSString *, id> *)parameters
                    headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                     region:(nullable TKRegion *)region
             callbackOnMain:(BOOL)callbackOnMain
                    success:(TKServerFullSuccessBlock)success
                    failure:(TKServerFailureBlock)failure;

- (NSURLRequest *)buildSkedGoRequestWithMethod:(NSString *)method
                                          path:(NSString *)path
                                    parameters:(nullable NSDictionary<NSString *, id> *)parameters
                                        region:(nullable TKRegion *)region;
@end

NS_ASSUME_NONNULL_END
