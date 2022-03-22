//
//  TKServer.m
//  TripKit
//
//  Created by Kuan Lun Huang on 17/02/2015.
//
//

#import "TKMacro.h"

#if SWIFT_PACKAGE
#import <TripKitObjc/NSUserDefaults+SharedDefaults.h>
#import <TripKitObjc/TKServer.h>
#import <TripKitObjc/TKStyleManager.h>
#else
#import "NSUserDefaults+SharedDefaults.h"
#import "TKServer.h"
#import "TKStyleManager.h"
#endif

NSString *const TKDefaultsKeyUserToken               = @"userToken";

@interface TKServer ()

@property (nonatomic, strong) NSOperationQueue* skedGoQueryQueue;
@property (nonatomic, copy)   NSArray<NSBundle *>* fileBundles;

@end

@implementation TKServer

#pragma mark - Public methods

+ (TKServer *)sharedInstance
{
  static TKServer *_server = nil;
  
  static dispatch_once_t onceToken;
  
  dispatch_once(&onceToken, ^{
    _server = [[self alloc] init];
  });
  
  return _server;
}

+ (nullable NSString *)userToken
{
  NSString *userToken = [[NSUserDefaults sharedDefaults] objectForKey:TKDefaultsKeyUserToken];
  if (userToken.length > 0) {
    return userToken;
  } else {
    return nil;
  }
}

+ (void)updateUserToken:(NSString *)userToken
{
  if (userToken.length > 0) {
    [[NSUserDefaults sharedDefaults] setObject:userToken forKey:TKDefaultsKeyUserToken];
  } else {
    [[NSUserDefaults sharedDefaults] setObject:@"" forKey:TKDefaultsKeyUserToken];
  }
}

#pragma mark - Network requests

- (void)_hitURL:(NSURL *)url
         method:(NSString *)method
     parameters:(nullable NSDictionary<NSString *, id> *)parameters
           info:(TKServerInfoBlock)info
     completion:(TKServerGenericBlock)completion
{
  NSURLRequest *request;
  if ([method isEqual:@"GET"]) {
    request = [self GETRequestWithSkedGoHTTPHeadersForURL:url paras:parameters];
  } else {
    request = [self POSTLikeRequestWithSkedGoHTTPHeadersForURL:url method:method paras:parameters headers:nil];
  }
  [TKServer hitRequest:request info:info completion:completion];
}

- (void)_hitSkedGoWithMethod:(NSString *)method
                        path:(NSString *)path
                  parameters:(nullable NSDictionary *)parameters
                     headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                    baseURLs:(NSMutableArray<NSURL *> *)baseURLs
              callbackOnMain:(BOOL)callbackOnMain
                        info:(TKServerInfoBlock)info
                     success:(TKServerFullSuccessBlock)success
                     failure:(TKServerFailureBlock)failure
{
  [self.skedGoQueryQueue addOperationWithBlock:^{
    [self initiateDataTaskWithMethod:method
                                path:path
                          parameters:parameters
                             headers:headers
                            baseURLs:baseURLs
                      callbackOnMain:callbackOnMain
                                info:info
                             success:success
                             failure:failure
                      previousStatus:0
                     previousHeaders:@{}
                        previousData:nil
                       previousError:nil];
  }];
}

#pragma mark - Private methods

- (instancetype)init
{
  self = [super init];
  
  if (self) {
    self.skedGoQueryQueue = [[NSOperationQueue alloc] init];
    self.skedGoQueryQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    self.skedGoQueryQueue.name = @"com.skedgo.tripkit.server-queue";
  }
  
  return self;
}

- (void)initiateDataTaskWithMethod:(NSString *)method
                              path:(NSString *)path
                        parameters:(nullable NSDictionary *)parameters
                           headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                          baseURLs:(NSMutableArray<NSURL *> *)baseURLs
                    callbackOnMain:(BOOL)callbackOnMain
                              info:(TKServerInfoBlock)info
                           success:(TKServerFullSuccessBlock)success
                           failure:(TKServerFailureBlock)failure
                    previousStatus:(NSInteger)previousStatus
                   previousHeaders:(NSDictionary *)previousHeaders
                      previousData:(nullable NSData *)previousData
                     previousError:(nullable NSError *)previousError
{
#ifdef DEBUG
  ZAssert([[NSOperationQueue currentQueue] isEqual:self.skedGoQueryQueue], @"Should start async data tasks on dedicated queue as we're modifying local variables.");
#endif
  
  NSURL *baseURL = [baseURLs firstObject];
  
  if (! baseURL) {
    // don't have that many servers
    if (! previousError) {
      if (callbackOnMain) {
        dispatch_async(dispatch_get_main_queue(), ^{
          success(previousStatus, previousHeaders, previousData);
        });
      } else {
        success(previousStatus, previousHeaders, previousData);
      }
    } else {
      if (callbackOnMain) {
        dispatch_async(dispatch_get_main_queue(), ^{
          failure(previousError);
        });
      } else {
        failure(previousError);
      }
    }
    return;
  }

  if (baseURLs.count > 0) {
    [baseURLs removeObjectAtIndex: 0];
  }
  NSURLRequest *request = [self buildSkedGoRequestWithMethod:method baseURL:baseURL path:path parameters:parameters headers:headers];
  
  // Backup handler
  void (^failOverBlock)(NSInteger, NSDictionary<NSString *, id> *, NSData *, NSError *) = ^(NSInteger status, NSDictionary<NSString *, id> *headers, NSData *data, NSError *error) {
    [self.skedGoQueryQueue addOperationWithBlock:^{
      [self initiateDataTaskWithMethod:method
                                  path:path
                            parameters:parameters
                               headers:headers
                              baseURLs:baseURLs
                        callbackOnMain:callbackOnMain
                                  info:info
                               success:success
                               failure:failure
                        previousStatus:status
                       previousHeaders:headers
                          previousData:data
                         previousError:error];
    }];
  };
  
  // hit the main client
  [TKServer hitRequest:request
                  info:info
             completion:
   ^(NSInteger status, NSDictionary<NSString *,id> *headers, NSData *data, NSError * _Nullable error) {
     NSError *serverError = error;
     if (serverError || status >= 500) {
       BOOL isUserError = NO;
       // LATER: Re-instate no failover on user error
       if (isUserError && serverError != nil) {
         if (callbackOnMain) {
           dispatch_async(dispatch_get_main_queue(), ^{
             failure(serverError);
           });
         } else {
           failure(serverError);
         }
       }
       
       if (! isUserError) {
         failOverBlock(status, headers, data, error);
       }
       
     } else {
       if (callbackOnMain) {
         dispatch_async(dispatch_get_main_queue(), ^{
           success(status, headers, data);
         });
       } else {
         success(status, headers, data);
       }
     }
   }];
}

+ (void)hitRequest:(NSURLRequest *)request
              info:(TKServerInfoBlock)info
        completion:(TKServerGenericBlock)completion
{
  NSUUID *requestUUID = [NSUUID UUID];
  info(requestUUID, NO, request, nil, nil, nil);
  
  NSURLSession *defaultSession = [NSURLSession sharedSession];
  NSURLSessionDataTask *task = [defaultSession dataTaskWithRequest:request
                                                 completionHandler:
                                ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                  info(requestUUID, YES, request, response, data, error);
    
                                  NSInteger status = 0;
                                  NSDictionary *headers = nil;
                                  if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                    status = httpResponse.statusCode;
                                    headers = httpResponse.allHeaderFields;
                                  } else {
                                    headers = @{};
                                  }
                                  
                                  if (error) {
                                    completion(status, headers, nil, error);
                                    
                                  } else if (data.length == 0) {
                                    // empty response is not an error
                                    completion(status, headers, nil, nil);
                                    
                                  } else {
                                    completion(status, headers, data, nil);
                                  }
                                }];
  [task resume];
}

- (NSURLRequest *)buildSkedGoRequestWithMethod:(NSString *)method
                                       baseURL:(NSURL *)baseURL
                                          path:(NSString *)path
                                    parameters:(nullable NSDictionary<NSString *, id> *)parameters
                                       headers:(nullable NSDictionary<NSString *, NSString *> *)headers
{

  NSURLRequest *request = nil;
  if ([method isEqualToString:@"GET"]) {
    NSURL *fullURL = [baseURL URLByAppendingPathComponent:path];
    request = [self GETRequestWithSkedGoHTTPHeadersForURL:fullURL paras:parameters headers:headers];

  } else if ([method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"] || [method isEqualToString:@"DELETE"]) {
    
    NSURL *fullURL;
    if ([path containsString:@"?"]) {
      // Using the diversion over string rather than just calling
      // `URLByAppendingPathComponent` to handle `POST`-paths that
      // include a query-string components
      NSString *urlString = [[baseURL absoluteString] stringByAppendingPathComponent:path];
      fullURL = [NSURL URLWithString: urlString];
    } else {
      fullURL = [baseURL URLByAppendingPathComponent:path];
    }
    
    // all of these work like post in terms of body and headers
    request = [self POSTLikeRequestWithSkedGoHTTPHeadersForURL:fullURL method:method paras:parameters headers:headers];
  } else {
    ZAssert(false, @"Method is not supported: %@", request);
  }
  return request;
}

+ (nullable NSString *)xTripGoVersion
{
  NSNumber *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
  if (version) {
    return [NSString stringWithFormat:@"i%@", version];
  } else {
    return nil;
  }
}

- (void)registerFileBundle:(NSBundle *)bundle {
  
  if (_fileBundles == nil) {
    _fileBundles = @[bundle];
  } else {
    _fileBundles = [_fileBundles arrayByAddingObject:bundle];
  }
}

#pragma mark - Configure session manager

- (NSMutableDictionary *)SkedGoHTTPHeaders
{
  NSMutableDictionary *headers = [NSMutableDictionary dictionary];
  
  NSString *APIKey = [self APIKey];
  if (APIKey.length > 0) {
    headers[@"X-TripGo-Key"] = APIKey;
  } else {
    ZAssert(false, @"API key not specified!");
  }
  
  // Optional
  [headers setValue:[TKServer xTripGoVersion] forKey:@"X-TripGo-Version"];
  [headers setValue:[TKServer userToken] forKey:@"userToken"];
  
  // Force JSON as server otherwise might return XML
  headers[@"Accept"] = @"application/json";
  
  return headers;
}

+ (void)addQueryItemsForKey:(NSString *)key rawValue:(id)value toArray:(NSMutableArray<NSURLQueryItem *> *)queryItems
{
  if ([value isKindOfClass:[NSArray class]]) {
    for (id subValue in value) {
      [self addQueryItemsForKey:key rawValue:subValue toArray:queryItems];
    }
    
  } else if ([value isKindOfClass:[NSString class]]) {
    [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:value]];

  } else if ([value respondsToSelector:@selector(description)]) {
    [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:[value description]]];
  
  } else {
    ZAssert(false, @"Ignoring value for key '%@' as it has unknown type.", key);
  }
}

+ (NSURL *)URLForGetRequestToBaseURL:(nonnull NSURL *)baseURL paras:(NSDictionary *)paras
{
  NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray arrayWithCapacity:paras.count];
  for (NSString *key in paras) {
    [self addQueryItemsForKey:key rawValue:paras[key] toArray:queryItems];
  }
  
  NSURLComponents *components = [NSURLComponents componentsWithURL:baseURL resolvingAgainstBaseURL:NO];
  components.queryItems = queryItems;
  return [components URL];
}

+ (nullable NSURL *)adjustedFileURLForURL:(NSURL *)originalURL {
  NSArray <NSBundle *>* bundles = [[TKServer sharedInstance] fileBundles];
  if (![originalURL isFileURL] || !bundles) {
    return nil;
  }
  
  NSString *filename = [originalURL lastPathComponent];
  NSString *extension = [originalURL pathExtension];
  if (!filename || !extension) {
    return nil;
  }
  
  NSString *name = [filename stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@", extension] withString:@""];
  
  for (NSBundle *bundle in bundles) {
    NSString *newPath = [bundle pathForResource:name ofType:extension];
    if (newPath) {
      NSURL *newURL = [NSURL URLWithString:[@"file://" stringByAppendingString:newPath]];
      if (newURL) {
        return newURL;
      }
    }
  }
  return nil;
}

- (NSURLRequest *)GETRequestWithSkedGoHTTPHeadersForURL:(nonnull NSURL *)URL
                                                  paras:(nullable NSDictionary *)paras
{
  return [self GETRequestWithSkedGoHTTPHeadersForURL:URL paras:paras headers:nil];
}

- (NSURLRequest *)GETRequestWithSkedGoHTTPHeadersForURL:(nonnull NSURL *)URL
                                                  paras:(nullable NSDictionary *)paras
                                                headers:(nullable NSDictionary<NSString *, NSString *> *)headers
{
  if (paras.count > 0) {
    URL = [TKServer URLForGetRequestToBaseURL:URL paras:paras];
  }
  NSURL *adjusted = [TKServer adjustedFileURLForURL:URL];
  if (adjusted) {
    URL = adjusted;
  }

  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
  
  NSDictionary *defaultHeaders = [self SkedGoHTTPHeaders];
  [defaultHeaders enumerateKeysAndObjectsUsingBlock:^(NSString * __nonnull key, NSString *  __nonnull obj, BOOL * __nonnull stop) {
#pragma unused(stop)
    [request setValue:obj forHTTPHeaderField:key];
  }];

  [headers enumerateKeysAndObjectsUsingBlock:^(NSString * __nonnull key, NSString *  __nonnull obj, BOOL * __nonnull stop) {
#pragma unused(stop)
    [request setValue:obj forHTTPHeaderField:key];
  }];

  
  return request;
}

- (NSURLRequest *)POSTLikeRequestWithSkedGoHTTPHeadersForURL:(NSURL *)URL
                                                      method:(NSString *)method
                                                       paras:(nullable NSDictionary *)paras
                                                     headers:(nullable NSDictionary<NSString *, NSString *> *)headers
{
  ZAssert([method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"] || [method isEqualToString:@"DELETE"], @"Bad method: %@", method);
  
  NSURL *adjusted = [TKServer adjustedFileURLForURL:URL];
  if (adjusted) {
    // POST not supported. Switch to GET.
    return [self GETRequestWithSkedGoHTTPHeadersForURL:adjusted paras:paras];
  }

  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
  request.HTTPMethod = method;
  
  NSDictionary *defaultHeaders = [self SkedGoHTTPHeaders];
  [defaultHeaders enumerateKeysAndObjectsUsingBlock:^(NSString * __nonnull key, NSString *  __nonnull obj, BOOL * __nonnull stop) {
#pragma unused(stop)
    [request setValue:obj forHTTPHeaderField:key];
  }];

  [headers enumerateKeysAndObjectsUsingBlock:^(NSString * __nonnull key, NSString *  __nonnull obj, BOOL * __nonnull stop) {
#pragma unused(stop)
    [request setValue:obj forHTTPHeaderField:key];
  }];

  if (paras) {
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSError *error;
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:paras
                                                       options:0
                                                         error:&error];
    ZAssert(!error, @"Bad POST data: %@", paras);

  }
  
  return request;
}

@end
