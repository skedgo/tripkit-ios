//
//  TKServer.h
//  TripKit
//
//  Created by Kuan Lun Huang on 17/02/2015.
//
//

#import <Foundation/Foundation.h>

#define kTKServerErrorTypeUser      30051
#define kTKErrorTypeInternal  30052

NS_ASSUME_NONNULL_BEGIN

typedef void (^TKServerSuccessBlock)(NSInteger status, NSData * _Nullable data);
typedef void (^TKServerFullSuccessBlock)(NSInteger status, NSDictionary<NSString *, id> *headers, NSData * _Nullable data);
typedef void (^TKServerFailureBlock)(NSError *error);
typedef void (^TKServerGenericBlock)(NSInteger status, NSDictionary<NSString *, id> *headers, NSData * _Nullable data, NSError * _Nullable error);
typedef void (^TKServerInfoBlock)(NSUUID *uuid, NSURLRequest *, NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable error);

/// :nodoc:
FOUNDATION_EXPORT NSString *const TKDefaultsKeyUserToken;
/// :nodoc:
FOUNDATION_EXPORT NSString *const TKDefaultsKeyDevelopmentServer;

@class TKRegion;

/// Encapsulates the logic for talking to SkedGo's servers
@interface TKServer : NSObject

+ (TKServer *)sharedInstance NS_REFINED_FOR_SWIFT;

+ (NSURLRequest *)GETRequestWithSkedGoHTTPHeadersForURL:(NSURL *)URL paras:(nullable NSDictionary *)paras;

+ (nullable NSString *)xTripGoVersion;

+ (nullable NSString *)userToken;

+ (void)updateUserToken:(nullable NSString *)userToken;

@property (nonatomic, copy) NSString *APIKey;

- (void)registerFileBundle:(NSBundle *)bundle;

/// :nodoc:
- (void)_hitSkedGoWithMethod:(NSString *)method
                        path:(NSString *)path
                  parameters:(nullable NSDictionary<NSString *, id> *)parameters
                     headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                    baseURLs:(NSMutableArray<NSURL *> *)baseURLs
              callbackOnMain:(BOOL)callbackOnMain
                        info:(TKServerInfoBlock)info
                     success:(TKServerFullSuccessBlock)success
                     failure:(TKServerFailureBlock)failure NS_REFINED_FOR_SWIFT;

/// :nodoc:
+ (void)_hitURL:(NSURL *)url
         method:(NSString *)method
     parameters:(nullable NSDictionary<NSString *, id> *)parameters
           info:(TKServerInfoBlock)info
     completion:(TKServerGenericBlock)completion NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
