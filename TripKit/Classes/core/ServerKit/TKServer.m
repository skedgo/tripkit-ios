//
//  TKServer.m
//  TripKit
//
//  Created by Kuan Lun Huang on 17/02/2015.
//
//

#import "TKServer.h"

#import "TripKit/TripKit-Swift.h"

#import "TKServerKit.h"

NSString *const TKDefaultsKeyDevelopmentServer       = @"developmentServer";
NSString *const TKDefaultsKeyUserToken               = @"userToken";


@interface TKServer ()

@property (nonatomic, strong) NSOperationQueue* skedGoQueryQueue;
@property (nonatomic, copy)   NSArray<NSBundle *>* fileBundles;

@end

@implementation TKServer

- (void)dealloc
{
  [[NSNotificationCenter  defaultCenter] removeObserver:self];
}

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

+ (NSString *)developmentServer {
  return [[NSUserDefaults sharedDefaults] stringForKey:TKDefaultsKeyDevelopmentServer];
}

+ (void)updateDevelopmentServer:(NSString *)server {
  NSString *previously = [self developmentServer];

  NSString *newValue = server;
  if (newValue.length == 0) {
    newValue = nil;
    [[NSUserDefaults sharedDefaults] removeObjectForKey:TKDefaultsKeyDevelopmentServer];
  } else {
    if (![newValue hasSuffix:@"/"]) {
      newValue = [newValue stringByAppendingString:@"/"];
    }
    [[NSUserDefaults sharedDefaults] setObject:newValue forKey:TKDefaultsKeyDevelopmentServer];
  }
  
  if ((newValue == nil && previously != nil)
      || (newValue != nil && previously == nil)
      || ![newValue isEqualToString:previously]) {
    
    // User tokens are bound to servers, so clear those, too.
    [TKServer updateUserToken:nil];
    
    // trigger updates
    [TKServer.sharedInstance updateRegionsForced:NO];
  }
}

#pragma mark - Network requests

+ (id)syncURL:(NSURL *)url timeout:(NSTimeInterval)seconds
{
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  [TKLog debug:@"TKServer" block:^NSString * _Nonnull{
    return [NSString stringWithFormat:@"Hitting URL: %@", url];
  }];
  
  __block id object;
  [self GET:url paras:nil completion:
   ^(NSInteger status, NSDictionary<NSString *,id> *headers, id _Nullable responseObject, NSData *data, NSError * _Nullable error) {
#pragma unused(status, headers, data)
     if (! error) {
       // success
       if (semaphore != NULL) {
         object = responseObject;
         dispatch_semaphore_signal(semaphore);
       }
     } else {
       // failure
       if (semaphore != NULL) {
         object = error;
         dispatch_semaphore_signal(semaphore);
       }
     }

   }];
  
  dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t) seconds * NSEC_PER_SEC);
  dispatch_semaphore_wait(semaphore, timeout);
  semaphore = NULL;
  
  return object;
}

+ (void)GET:(NSURL *)URL paras:(nullable NSDictionary *)paras completion:(TKServerGenericBlock)completion
{
  NSURLRequest *request = [self GETRequestWithSkedGoHTTPHeadersForURL:URL paras:paras];
  [self hitRequest:request completion:completion];
}

+ (void)POST:(NSURL *)URL paras:(nullable NSDictionary *)paras completion:(TKServerGenericBlock)completion
{
  NSURLRequest *request = [self POSTLikeRequestWithSkedGoHTTPHeadersForURL:URL method:@"POST" paras:paras headers:nil];
  [self hitRequest:request completion:completion];
}

+ (void)hitRequest:(NSURLRequest *)request completion:(TKServerGenericBlock)completion
{
  NSUUID *requestUUID = [NSUUID UUID];
  [TKLog log:@"TKServer" request:request UUID:requestUUID];
  
  NSURLSession *defaultSession = [NSURLSession sharedSession];
  NSURLSessionDataTask *task = [defaultSession dataTaskWithRequest:request
                                                 completionHandler:
                                ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                  [TKLog log:@"TKServer"
                                    response:response
                                        data:data
                                     orError:error
                                  forRequest:request
                                        UUID:requestUUID];
    
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
                                    completion(status, headers, nil, nil, error);
                                    
                                  } else if (data.length == 0) {
                                    // empty response is not an error
                                    completion(status, headers, nil, nil, nil);
                                    
                                  } else {
                                    NSError *parserError = nil;
                                    id responseObject = [NSJSONSerialization JSONObjectWithData:data
                                                                                        options:0
                                                                                          error:&parserError];
                                    if (responseObject) {
                                      TKError *serverError = [TKError errorFromJSON:responseObject statusCode:status];
                                      if (serverError != nil) {
                                        completion(status, headers, nil, nil,  serverError);
                                      } else {
                                        completion(status, headers, responseObject, data, nil);
                                      }
                                    } else {
                                      [TKLog warn:@"TKServer" text:[NSString stringWithFormat:@"Could not parse: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]]];
                                      completion(status, headers, nil, nil, parserError);
                                    }
                                  }
                                }];
  [task resume];
}

- (void)hitSkedGoWithMethod:(NSString *)method
                       path:(NSString *)path
                 parameters:(nullable NSDictionary *)parameters
                     region:(nullable TKRegion *)region
                    success:(TKServerSuccessBlock)success
                    failure:(TKServerFailureBlock)failure
{
  [self hitSkedGoWithMethod:method
                       path:path
                 parameters:parameters
                     region:region
             callbackOnMain:YES
                    success:success
                    failure:failure];
}

- (void)hitSkedGoWithMethod:(NSString *)method
                       path:(NSString *)path
                 parameters:(nullable NSDictionary<NSString *, id> *)parameters
                     region:(nullable TKRegion *)region
             callbackOnMain:(BOOL)callbackOnMain
                    success:(TKServerSuccessBlock)success
                    failure:(TKServerFailureBlock)failure
{
  [self hitSkedGoWithMethod:method
                       path:path
                 parameters:parameters
                    headers:nil
                     region:region
             callbackOnMain:callbackOnMain
                    success:^(NSInteger status, NSDictionary<NSString *,id> * _Nonnull headers, id  _Nullable responseObject, NSData * _Nullable data) {
                      success(status, responseObject, data);
                    }
                    failure:failure];
}

- (void)hitSkedGoWithMethod:(NSString *)method
                       path:(NSString *)path
                 parameters:(nullable NSDictionary *)parameters
                    headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                     region:(nullable TKRegion *)region
             callbackOnMain:(BOOL)callbackOnMain
                    success:(TKServerFullSuccessBlock)success
                    failure:(TKServerFailureBlock)failure
{
  [self.skedGoQueryQueue addOperationWithBlock:^{
    [self initiateDataTaskWithMethod:method
                                path:path
                          parameters:parameters
                             headers:headers
                           forRegion:region
                         backupIndex:0
                      callbackOnMain:callbackOnMain
                             success:success
                             failure:failure
                      previousStatus:0
                     previousHeaders:@{}
                    previousResponse:nil
                        previousData:nil
                       previousError:nil];
  }];
}


#pragma mark - Settings

- (void)updateRegionsForced:(BOOL)forceUpdate
{
  // load all the regions
  [self fetchRegionsForced:forceUpdate completion:nil];
}

- (void)fetchRegionsForced:(BOOL)forced
                completion:(nullable void (^)(BOOL success, NSError *error))completion
{
  NSString *regionsURLString;
  if ([TKServer developmentServer]) {
    regionsURLString = [[TKServer developmentServer] stringByAppendingString:@"regions.json"];
  } else {
    regionsURLString = @"https://api.tripgo.com/v1/regions.json";
  }
  
  NSMutableDictionary *paras = [NSMutableDictionary dictionaryWithCapacity:2];
  paras[@"v"] = @2;
  if (!forced) {
    [paras setValue:[TKRegionManager.shared regionsHash] forKey:@"hashCode"];
  }
  
  [TKServer POST:[NSURL URLWithString:regionsURLString]
            paras:paras
       completion:
   ^(NSInteger status, NSDictionary<NSString *, id> *headers, id _Nullable responseObject, NSData *data, NSError * _Nullable error) {
#pragma unused(status, headers, responseObject)
     if (data) {
       [TKRegionManager.shared updateRegionsFromData:data];
       
       if ([TKRegionManager.shared hasRegions]) {
         if (completion) {
           completion(YES, nil);
         }
       } else {
         NSString *message = NSLocalizedStringFromTableInBundle(@"Could not download supported regions from TripGo's server. Please try again later.", @"Shared", [TKStyleManager bundle], "Could not download supported regions warning. (old key: CouldNotDownloadSupportedRegions)");
         NSError *userError = [NSError errorWithCode:kTKServerErrorTypeUser  message:message];
         if (completion) {
           completion(NO, userError);
         }
       }
       
     } else if (error) {
       [TKLog warn:@"TKServer" text:[NSString stringWithFormat:@"Couldn't fetch regions. Error: %@", error]];
       if (completion) {
         completion(NO, error);
       }
     }
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
                         forRegion:(nullable TKRegion *)region
                       backupIndex:(NSInteger)backupIndex
                    callbackOnMain:(BOOL)callbackOnMain
                           success:(TKServerFullSuccessBlock)success
                           failure:(TKServerFailureBlock)failure
                    previousStatus:(NSInteger)previousStatus
                   previousHeaders:(NSDictionary *)previousHeaders
                  previousResponse:(nullable id)previousResponse
                      previousData:(nullable NSData *)previousData
                     previousError:(nullable NSError *)previousError
{
#ifdef DEBUG
  ZAssert([[NSOperationQueue currentQueue] isEqual:self.skedGoQueryQueue], @"Should start async data tasks on dedicated queue as we're modifying local variables.");
#endif
  
  NSURL *baseURL = [self baseURLForRegion:region index:backupIndex];
  if (! baseURL) {
    // don't have that many servers
    if (! previousError) {
      if (callbackOnMain) {
        dispatch_async(dispatch_get_main_queue(), ^{
          success(previousStatus, previousHeaders, previousResponse, previousData);
        });
      } else {
        success(previousStatus, previousHeaders, previousResponse, previousData);
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
  
  NSURLRequest *request = [TKServer buildSkedGoRequestWithMethod:method baseURL:baseURL path:path parameters:parameters headers:headers region:region];
  
  // Backup handler
  void (^failOverBlock)(NSInteger, NSDictionary<NSString *, id> *,  id, NSData *, NSError *) = ^(NSInteger status, NSDictionary<NSString *, id> *headers, id responseObject, NSData *data, NSError *error) {
    [self.skedGoQueryQueue addOperationWithBlock:^{
      [self initiateDataTaskWithMethod:method
                                  path:path
                            parameters:parameters
                               headers:headers
                             forRegion:region
                           backupIndex:backupIndex + 1
                        callbackOnMain:callbackOnMain
                               success:success
                               failure:failure
                        previousStatus:status
                       previousHeaders:headers
                      previousResponse:responseObject
                          previousData:data
                         previousError:error];
    }];
  };
  
  // hit the main client
  [TKServer hitRequest:request
             completion:
   ^(NSInteger status, NSDictionary<NSString *,id> *headers, id _Nullable responseObject, NSData *data, NSError * _Nullable error) {
     NSError *serverError = error ?: [TKError errorFromJSON:responseObject statusCode:status];
     if (serverError) {
       BOOL isUserError = NO;
       if ([serverError isKindOfClass:[TKError class]]) {
         isUserError = [(TKError *)serverError isUserError];
       }
       if (isUserError) {
         if (callbackOnMain) {
           dispatch_async(dispatch_get_main_queue(), ^{
             failure(serverError);
           });
         } else {
           failure(serverError);
         }
       }
       
       if (! isUserError) {
         failOverBlock(status, headers, responseObject, data, error);
       }
       
     } else {
       if (callbackOnMain) {
         dispatch_async(dispatch_get_main_queue(), ^{
           success(status, headers, responseObject, data);
         });
       } else {
         success(status, headers, responseObject, data);
       }
     }
   }];
}

- (NSURLRequest *)buildSkedGoRequestWithMethod:(NSString *)method
      path:(NSString *)path
parameters:(nullable NSDictionary<NSString *, id> *)parameters
    region:(nullable TKRegion *)region
{
  return [TKServer buildSkedGoRequestWithMethod:method
                                        baseURL:[self baseURLForRegion:region index:0]
                                           path:path
                                     parameters:parameters
                                        headers:nil
                                         region:region];
}

+ (NSURLRequest *)buildSkedGoRequestWithMethod:(NSString *)method
   baseURL:(NSURL *)baseURL
      path:(NSString *)path
parameters:(nullable NSDictionary<NSString *, id> *)parameters
   headers:(nullable NSDictionary<NSString *, NSString *> *)headers
    region:(nullable TKRegion *)region
{

  NSURLRequest *request = nil;
  if ([method isEqualToString:@"GET"]) {
    NSURL *fullURL = [baseURL URLByAppendingPathComponent:path];
    request = [TKServer GETRequestWithSkedGoHTTPHeadersForURL:fullURL paras:parameters headers:headers];

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
    request = [TKServer POSTLikeRequestWithSkedGoHTTPHeadersForURL:fullURL method:method paras:parameters headers:headers];
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

#pragma mark - Regions

- (void)requireRegions:(void(^)(NSError *error))completion
{
  if (! completion) {
    ZAssert(false, @"Completion block required.");
    return;
  }
  
  if ([TKRegionManager.shared hasRegions]) {
    // we have regions
    completion(nil);
    
  } else {
    [self fetchRegionsForced:NO
                  completion:^(BOOL success, NSError *error) {
#pragma unused(success)
                    completion(error);
                  }];
  }
}

#pragma mark - Server & Base URL

- (nullable NSURL *)baseURLForRegion:(nullable TKRegion *)region index:(NSUInteger)index
{
  if ([TKServer developmentServer]) {
    return index == 0 ? [NSURL URLWithString:[TKServer developmentServer] ] : nil;
  }
    
  if (region == nil || region.urls.count == 0) {
    if (index == 0) {
      return [NSURL URLWithString:@"https://api.tripgo.com/v1/"];
    } else {
      return nil; // no fail-over
    }
  }
  
  NSArray<NSURL *> *servers = region.urls;
  if (servers.count <= index) {
    return nil;
  }
  
  NSURL *url = [servers objectAtIndex:index];
  NSString *urlString = url.absoluteString;
  
  if (urlString.length > 0 && [urlString characterAtIndex:urlString.length - 1] != '/') {
    urlString = [urlString stringByAppendingString:@"/"];
    url = [NSURL URLWithString:urlString];
  }
  
  return url;
}

- (NSURL *)fallbackBaseURL
{
  return [self baseURLForRegion:nil index:0];
}

- (void)registerFileBundle:(NSBundle *)bundle {
  
  if (_fileBundles == nil) {
    _fileBundles = @[bundle];
  } else {
    _fileBundles = [_fileBundles arrayByAddingObject:bundle];
  }
}

#pragma mark - Configure session manager

+ (NSMutableDictionary *)SkedGoHTTPHeaders
{
  NSMutableDictionary *headers = [NSMutableDictionary dictionary];
  
  NSString *APIKey = [[TKServer sharedInstance] APIKey];
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

+ (NSURLRequest *)GETRequestWithSkedGoHTTPHeadersForURL:(nonnull NSURL *)URL
                                                  paras:(nullable NSDictionary *)paras
{
  return [self GETRequestWithSkedGoHTTPHeadersForURL:URL paras:paras headers:nil];
}

+ (NSURLRequest *)GETRequestWithSkedGoHTTPHeadersForURL:(nonnull NSURL *)URL
                                                  paras:(nullable NSDictionary *)paras
                                                headers:(nullable NSDictionary<NSString *, NSString *> *)headers
{
  if (paras.count > 0) {
    URL = [self URLForGetRequestToBaseURL:URL paras:paras];
  }
  NSURL *adjusted = [self adjustedFileURLForURL:URL];
  if (adjusted) {
    URL = adjusted;
  }

  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
  
  NSDictionary *defaultHeaders = [TKServer SkedGoHTTPHeaders];
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

+ (NSURLRequest *)POSTLikeRequestWithSkedGoHTTPHeadersForURL:(NSURL *)URL
                                                      method:(NSString *)method
                                                       paras:(nullable NSDictionary *)paras
                                                     headers:(nullable NSDictionary<NSString *, NSString *> *)headers
{
  ZAssert([method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"] || [method isEqualToString:@"DELETE"], @"Bad method: %@", method);
  
  NSURL *adjusted = [self adjustedFileURLForURL:URL];
  if (adjusted) {
    // POST not supported. Switch to GET.
    return [self GETRequestWithSkedGoHTTPHeadersForURL:adjusted paras:paras];
  }

  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
  request.HTTPMethod = method;
  
  NSDictionary *defaultHeaders = [TKServer SkedGoHTTPHeaders];
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
