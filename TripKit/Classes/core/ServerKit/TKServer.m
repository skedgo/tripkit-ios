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

NSString *const TKDefaultsKeyServerType              = @"internalServerType";
NSString *const TKDefaultsKeyDevelopmentServer       = @"developmentServer";
NSString *const TKDefaultsKeyUserToken               = @"userToken";
NSString *const TKDefaultsKeyProfileEnableFlights    = @"profileEnableFlights";


@interface TKServer ()

@property (nonatomic, strong) NSOperationQueue* skedGoQueryQueue;
@property (nonatomic, copy)   NSArray<NSBundle *>* fileBundles;

@property (nonatomic, assign) TKServerType lastServerType;
@property (nonatomic, strong) NSString* lastDevelopmentServer;

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
  NSString *customised = [[NSUserDefaults sharedDefaults] stringForKey:TKDefaultsKeyDevelopmentServer];
  return customised ?: @"http://localhost:8080/satapp-debug/";
}

+ (void)updateDevelopmentServer:(NSString *)server {
  if (server.length == 0) {
    [[NSUserDefaults sharedDefaults] removeObjectForKey:TKDefaultsKeyDevelopmentServer];
    return;
  }
  
  if (![server hasSuffix:@"/"]) {
    server = [server stringByAppendingString:@"/"];
  }
  [[NSUserDefaults sharedDefaults] setObject:server forKey:TKDefaultsKeyDevelopmentServer];
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
  NSURLRequest *request = [self POSTLikeRequestWithSkedGoHTTPHeadersForURL:URL method:@"POST" paras:paras headers:nil customData:nil];
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
                 customData:nil
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
  [self hitSkedGoWithMethod:method
                       path:path
                 parameters:parameters
                    headers:headers
                 customData:nil
                     region:region
             callbackOnMain:callbackOnMain
                    success:success
                    failure:failure];
}

- (void)hitSkedGoWithMethod:(NSString *)method
                       path:(NSString *)path
                 parameters:(nullable NSDictionary *)parameters
                    headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                 customData:(nullable NSData*)customData
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
                          customData:customData
                     waitForResponse:NO
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

- (nullable id)initiateSyncRequestWithMethod:(NSString *)method
                                        path:(NSString *)path
                                  parameters:(NSDictionary *)parameters
                                      region:(TKRegion *)region
{
  return [self initiateDataTaskWithMethod:method
                                     path:path
                               parameters:parameters
                                  headers:nil
                               customData:nil
                          waitForResponse:YES
                                forRegion:region
                              backupIndex:0
                           callbackOnMain:NO // irrelevant
                                  success:nil
                                  failure:nil
                           previousStatus:0
                          previousHeaders:@{}
                         previousResponse:nil
                             previousData:nil
                            previousError:nil];
}

#pragma mark - Settings

/**
 * This method is only used is non-production mode when the user
 * is switching servers.
 */
- (void)updateFromSettings
{
  TKServerType currentType = [[NSUserDefaults sharedDefaults] integerForKey:TKDefaultsKeyServerType];
  NSString *developmentServer = [TKServer developmentServer];

  // This method gets called tons of times, but we only want to clear existing
  // regions if and only if user has changed server type in the Beta build.
  if (currentType != self.lastServerType
      || (currentType == TKServerTypeLocal && ![developmentServer isEqualToString:self.lastDevelopmentServer])) {
    
    // Clearing regions below will trigger a user defaults update, so we make sure we ignore it
    self.lastServerType = currentType;
    self.lastDevelopmentServer = developmentServer;
    
    // We're caching the server, so override the cache
    TKServer.serverType = currentType;
    
    // User tokens are bound to servers, so clear those, too.
    [TKServer updateUserToken:nil];
    
    // trigger updates
    [self updateRegionsForced:NO];
  }
}

- (void)updateRegionsForced:(BOOL)forceUpdate
{
  // load all the regions
  [self fetchRegionsForced:forceUpdate completion:nil];
}

- (void)fetchRegionsForced:(BOOL)forced
                completion:(nullable void (^)(BOOL success, NSError *error))completion
{
  NSString *regionsURLString;
  switch ([TKServer serverType]) {
    case TKServerTypeProduction:
      regionsURLString = @"https://api.tripgo.com/v1/regions.json";
      break;
      
    case TKServerTypeBeta:
    {
      NSString *baseString = [[TKConfig sharedInstance] betaServerBaseURL];
      regionsURLString = [baseString stringByAppendingString:@"regions.json"];
      break;
    }

    case TKServerTypeLocal:
      regionsURLString = [[TKServer developmentServer] stringByAppendingString:@"regions.json"];
      break;
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
    if ([TKBetaHelper isBeta]) {
      // this only applies in DEBUG mode when the UI has elements to switching the backend server
      // listen to future changes
      NSUserDefaults *sharedDefaults = [NSUserDefaults sharedDefaults];
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(updateFromSettings)
                                                   name:NSUserDefaultsDidChangeNotification
                                                 object:sharedDefaults];
    }
    
    self.lastServerType = [[NSUserDefaults sharedDefaults] integerForKey:TKDefaultsKeyServerType];;
    self.lastDevelopmentServer = [TKServer developmentServer];
    
    self.skedGoQueryQueue = [[NSOperationQueue alloc] init];
    self.skedGoQueryQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    self.skedGoQueryQueue.name = @"com.skedgo.tripkit.server-queue";
  }
  
  return self;
}

- (nullable id)initiateDataTaskWithMethod:(NSString *)method
                                     path:(NSString *)path
                               parameters:(nullable NSDictionary *)parameters
                                  headers:(nullable NSDictionary<NSString *, NSString *> *)headers
                               customData:(nullable NSData*) customData
                          waitForResponse:(BOOL)wait
                                forRegion:(nullable TKRegion *)region
                              backupIndex:(NSInteger)backupIndex
                           callbackOnMain:(BOOL)callbackOnMain
                                  success:(nullable TKServerFullSuccessBlock)success
                                  failure:(nullable TKServerFailureBlock)failure
                           previousStatus:(NSInteger)previousStatus
                          previousHeaders:(NSDictionary *)previousHeaders
                         previousResponse:(nullable id)previousResponse
                             previousData:(nullable NSData *)previousData
                            previousError:(nullable NSError *)previousError
{
#ifdef DEBUG
  ZAssert(! wait || ! [NSThread isMainThread], @"Don't wait on the main thread!");
  ZAssert(wait || [[NSOperationQueue currentQueue] isEqual:self.skedGoQueryQueue], @"Should start async data tasks on dedicated queue as we're modifying local variables.");
#endif
  
  NSURL *baseURL = [self baseURLForRegion:region index:backupIndex];
  if (! baseURL) {
    // don't have that many servers
    if (! previousError) {
      if (success) {
        if (callbackOnMain) {
          dispatch_async(dispatch_get_main_queue(), ^{
            success(previousStatus, previousHeaders, previousResponse, previousData);
          });
        } else {
          success(previousStatus, previousHeaders, previousResponse, previousData);
        }
      }
    } else {
      if (failure) {
        if (callbackOnMain) {
          dispatch_async(dispatch_get_main_queue(), ^{
            failure(previousError);
          });
        } else {
          failure(previousError);
        }
      }
    }
    return nil;
  }
  
  NSURLRequest *request = [TKServer buildSkedGoRequestWithMethod:method baseURL:baseURL path:path parameters:parameters headers:headers customData:customData region:region];
  
  // Backup handler
  void (^failOverBlock)(NSInteger, NSDictionary<NSString *, id> *,  id, NSData *, NSError *) = ^(NSInteger status, NSDictionary<NSString *, id> *headers, id responseObject, NSData *data, NSError *error) {
    [self.skedGoQueryQueue addOperationWithBlock:^{
      [self initiateDataTaskWithMethod:method
                                  path:path
                            parameters:parameters
                               headers:headers
                            customData:customData
                       waitForResponse:wait
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
  __block id successResponse = nil;
  __block NSError *failureError = nil;
  dispatch_semaphore_t semaphore = wait ? dispatch_semaphore_create(0) : NULL;
  
  [TKServer hitRequest:request
             completion:
   ^(NSInteger status, NSDictionary<NSString *,id> *headers, id _Nullable responseObject, NSData *data, NSError * _Nullable error) {
     NSError *serverError = error ?: [TKError errorFromJSON:responseObject statusCode:status];
     if (serverError) {
       BOOL isUserError = NO;
       if ([serverError isKindOfClass:[TKError class]]) {
         isUserError = [(TKError *)serverError isUserError];
       }
       // Only failing over if `failure` is set as otherwise it would mess with semaphores!
       if (isUserError && failure) {
         if (callbackOnMain) {
           dispatch_async(dispatch_get_main_queue(), ^{
             failure(serverError);
           });
         } else {
           failure(serverError);
         }
       }
       
       if (wait && semaphore != NULL) {
         // not failing over as that messes with semaphores!
         dispatch_semaphore_signal(semaphore);
       } else if (! isUserError) {
         failOverBlock(status, headers, responseObject, data, error);
       }
       
     } else {
       successResponse = responseObject;
       if (success) {
         if (callbackOnMain) {
           dispatch_async(dispatch_get_main_queue(), ^{
             success(status, headers, successResponse, data);
           });
         } else {
           success(status, headers, successResponse, data);
         }
       }
       if (wait && semaphore != NULL) {
         dispatch_semaphore_signal(semaphore);
       }
     }
   }];
  
  if (wait) {
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC);
    dispatch_semaphore_wait(semaphore, timeout);
    semaphore = NULL;
    if (failureError) {
      return failureError;
    } else {
      return successResponse;
    }
  } else {
    return nil;
  }
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
                                     customData:nil
                                         region:region];
}

+ (NSURLRequest *)buildSkedGoRequestWithMethod:(NSString *)method
   baseURL:(NSURL *)baseURL
      path:(NSString *)path
parameters:(nullable NSDictionary<NSString *, id> *)parameters
   headers:(nullable NSDictionary<NSString *, NSString *> *)headers
    customData:(nullable NSData*)customData
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
    request = [TKServer POSTLikeRequestWithSkedGoHTTPHeadersForURL:fullURL method:method paras:parameters headers:headers customData:customData];
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
  switch ([TKServer serverType]) {
    case TKServerTypeLocal: {
      return index == 0 ? [NSURL URLWithString:[TKServer developmentServer] ] : nil;
    }

    case TKServerTypeBeta: {
      NSString *baseURL = [[TKConfig sharedInstance] betaServerBaseURL];
      return index == 0 ? [NSURL URLWithString:baseURL] : nil;
    }
      
    case TKServerTypeProduction: {
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
  }
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
                                                  customData:(NSData*) customData
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
    ZAssert(!customData, @"Send paras or customData or neither");
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSError *error;
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:paras
                                                       options:0
                                                         error:&error];
    ZAssert(!error, @"Bad POST data: %@", paras);

  } else if (customData) {
    NSString *boundary = [self generateBoundaryString];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    NSMutableData *httpBody = [NSMutableData data];
    
    //Define Content-Type
    NSString *mimetype  = [self mimeTypeByGuessingFromData:customData];
    [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimetype] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:customData];
    [httpBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    request.HTTPBody = httpBody;
    
    // set the content-length
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[httpBody length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
  }
  
  return request;
}

#pragma mark - Sending data

+ (NSString *)mimeTypeByGuessingFromData:(NSData *)data {
  
  char bytes[12] = {0};
  [data getBytes:&bytes length:12];
  
  const char bmp[2] = {'B', 'M'};
  const char gif[3] = {'G', 'I', 'F'};
//  const char swf[3] = {'F', 'W', 'S'};
//  const char swc[3] = {'C', 'W', 'S'};
  const char jpg[3] = {0xff, 0xd8, 0xff};
  const char psd[4] = {'8', 'B', 'P', 'S'};
  const char iff[4] = {'F', 'O', 'R', 'M'};
  const char webp[4] = {'R', 'I', 'F', 'F'};
  const char ico[4] = {0x00, 0x00, 0x01, 0x00};
  const char tif_ii[4] = {'I','I', 0x2A, 0x00};
  const char tif_mm[4] = {'M','M', 0x00, 0x2A};
  const char png[8] = {0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a};
  const char jp2[12] = {0x00, 0x00, 0x00, 0x0c, 0x6a, 0x50, 0x20, 0x20, 0x0d, 0x0a, 0x87, 0x0a};
  
  
  if (!memcmp(bytes, bmp, 2)) {
    return @"image/x-ms-bmp";
  } else if (!memcmp(bytes, gif, 3)) {
    return @"image/gif";
  } else if (!memcmp(bytes, jpg, 3)) {
    return @"image/jpeg";
  } else if (!memcmp(bytes, psd, 4)) {
    return @"image/psd";
  } else if (!memcmp(bytes, iff, 4)) {
    return @"image/iff";
  } else if (!memcmp(bytes, webp, 4)) {
    return @"image/webp";
  } else if (!memcmp(bytes, ico, 4)) {
    return @"image/vnd.microsoft.icon";
  } else if (!memcmp(bytes, tif_ii, 4) || !memcmp(bytes, tif_mm, 4)) {
    return @"image/tiff";
  } else if (!memcmp(bytes, png, 8)) {
    return @"image/png";
  } else if (!memcmp(bytes, jp2, 12)) {
    return @"image/jp2";
  }
  
  return @"application/octet-stream"; // default type
  
}

+ (NSString *)generateBoundaryString
{
  return [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
}

@end
