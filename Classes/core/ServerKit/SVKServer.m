//
//  SGKServer.m
//  TripKit
//
//  Created by Kuan Lun Huang on 17/02/2015.
//
//

#import "SVKServer.h"

#import "TripKit/TripKit-Swift.h"

#import "SVKServerKit.h"

// User profile
NSString *const SVKDefaultsKeyServerType              = @"internalServerType";
NSString *const SVKDefaultsKeyDevelopmentServer       = @"developmentServer";
NSString *const SVKDefaultsKeyProfileTrackUsage       = @"track_usage";
NSString *const SVKDefaultsKeyUUID										= @"UUID";
NSString *const SVKDefaultsKeyUserToken               = @"userToken";
NSString *const SVKDefaultsKeyProfileEnableFlights    = @"profileEnableFlights";
NSString *const SVKDefaultsKeyProfileDistanceUnit     = @"displayDistanceUnit";


@interface SVKServer ()

@property (nonatomic, strong) SVKRegion* region;
@property (nonatomic, copy)   NSArray<NSURL *>* regionServers;
@property (nonatomic, copy)   NSArray<NSBundle *>* fileBundles;
@property (nonatomic, assign) NSUInteger serverIndex;

@property (nonatomic, assign) SVKServerType lastServerType;
@property (nonatomic, strong) NSString* lastDevelopmentServer;

@end

@implementation SVKServer

- (void)dealloc
{
  [[NSNotificationCenter  defaultCenter] removeObserver:self];
}

#pragma mark - Public methods

+ (SVKServer *)sharedInstance
{
  static SVKServer *_server = nil;
  
  static dispatch_once_t onceToken;
  
  dispatch_once(&onceToken, ^{
    _server = [[self alloc] init];
  });
  
  return _server;
}

+ (NSURL *)imageURLForIconFileNamePart:(NSString *)fileNamePart
                            ofIconType:(SGStyleModeIconType)type
{
  NSString *regionsURLString;
  switch ([self serverType]) {
    case SVKServerTypeProduction:
      regionsURLString = @"https://tripgo.skedgo.com/satapp";
      break;
      
    case SVKServerTypeBeta:
      regionsURLString = @"https://bigbang.buzzhives.com/satapp-beta";
      break;

    case SVKServerTypeLocal:
      regionsURLString = [SVKServer developmentServer];
      break;
  }
  
  BOOL isPNG;
  NSString *iconPrefix;
  switch (type) {
    case SGStyleModeIconTypeMapIcon:
      iconPrefix = @"icon-map-info";
      isPNG = YES;
      break;

    case SGStyleModeIconTypeListMainMode:
    case SGStyleModeIconTypeListMainModeOnDark:
      iconPrefix = @"icon-mode";
      isPNG = YES;
      break;
      
    case SGStyleModeIconTypeResolutionIndependent:
    case SGStyleModeIconTypeResolutionIndependentOnDark:
      iconPrefix = @"icon-mode";
      isPNG = NO;
      break;
      
    case SGStyleModeIconTypeVehicle:
      iconPrefix = @"icon-vehicle";
      isPNG = YES;
      break;

    case SGStyleModeIconTypeAlert:
      iconPrefix = @"icon-alert";
      isPNG = YES;
      break;
  }
  
  NSString *iconFileNamePart = fileNamePart;
  NSString *iconExtension = isPNG ? @"png" : @"svg";
  if (isPNG) {
    CGFloat scale;
#if TARGET_OS_IPHONE
    scale = [UIScreen mainScreen].scale;
#else
    scale = [NSScreen mainScreen].backingScaleFactor;
#endif
    if (scale >= 2.9) {
      iconFileNamePart = [iconFileNamePart stringByAppendingString:@"@3x"];
    } else if (scale >= 1.9) {
      iconFileNamePart = [iconFileNamePart stringByAppendingString:@"@2x"];
    }
  }
  
  return [NSURL URLWithString:[NSString stringWithFormat:@"%@/modeicons/%@-%@.%@", regionsURLString, iconPrefix, iconFileNamePart, iconExtension]];
}

/**
 @return A UUID as a string identifying this installation. Returns `nil` if the user defaults have a key `SVKDefaultsKeyProfileTrackUsage` which is set to `true`.
 */
+ (nullable NSString *)persistentUUID
{
  // generate UUID if we dont' have it yet
  NSUserDefaults *defaults = [NSUserDefaults sharedDefaults];
  NSString *UUIDString = [defaults stringForKey:SVKDefaultsKeyUUID];
  if (! UUIDString) {
    UUIDString = [[NSUUID UUID] UUIDString];
    [defaults setObject:UUIDString forKey:SVKDefaultsKeyUUID];
  }
  
  // return the UUID unless no tracking of usage allowed
  NSNumber *allowTracking = [[NSUserDefaults standardUserDefaults] objectForKey:SVKDefaultsKeyProfileTrackUsage];
  if (allowTracking == nil || allowTracking.boolValue) {
    return UUIDString;
  } else {
    return nil;
  }
}

+ (nullable NSString *)userToken
{
  NSString *userToken = [[NSUserDefaults sharedDefaults] objectForKey:SVKDefaultsKeyUserToken];
  if (userToken.length > 0) {
    return userToken;
  } else {
    return nil;
  }
}

+ (void)updateUserToken:(NSString *)userToken
{
  if (userToken.length > 0) {
    [[NSUserDefaults sharedDefaults] setObject:userToken forKey:SVKDefaultsKeyUserToken];
  } else {
    [[NSUserDefaults sharedDefaults] setObject:@"" forKey:SVKDefaultsKeyUserToken];
  }
}

+ (NSString *)developmentServer {
  NSString *customised = [[NSUserDefaults sharedDefaults] stringForKey:SVKDefaultsKeyDevelopmentServer];
  return customised ?: @"http://localhost:8080/satapp-debug/";
}

+ (void)updateDevelopmentServer:(NSString *)server {
  if (server.length == 0) {
    [[NSUserDefaults sharedDefaults] removeObjectForKey:SVKDefaultsKeyDevelopmentServer];
    return;
  }
  
  if (![server hasSuffix:@"/"]) {
    server = [server stringByAppendingString:@"/"];
  }
  [[NSUserDefaults sharedDefaults] setObject:server forKey:SVKDefaultsKeyDevelopmentServer];
}

#pragma mark - Network requests

+ (id)syncURL:(NSURL *)url timeout:(NSTimeInterval)seconds
{
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  [SGKLog debug:@"SVKServer" block:^NSString * _Nonnull{
    return [NSString stringWithFormat:@"Hitting URL: %@", url];
  }];
  
  __block id object;
  [self GET:url paras:nil completion:
   ^(NSInteger status, id  _Nullable responseObject, NSData *data, NSError * _Nullable error) {
#pragma unused(status, data)
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

+ (void)GET:(NSURL *)URL paras:(nullable NSDictionary *)paras completion:(SGServerGenericBlock)completion
{
  NSURLRequest *request = [self GETRequestWithSkedGoHTTPHeadersForURL:URL paras:paras];
  [self hitRequest:request completion:completion];
}

+ (void)POST:(NSURL *)URL paras:(nullable NSDictionary *)paras completion:(SGServerGenericBlock)completion
{
  NSURLRequest *request = [self POSTLikeRequestWithSkedGoHTTPHeadersForURL:URL method:@"POST" paras:paras];
  [self hitRequest:request completion:completion];
}

+ (void)hitRequest:(NSURLRequest *)request completion:(SGServerGenericBlock)completion
{
#ifdef DEBUG
  [SGKLog info:@"SVKServer" block:^NSString * _Nonnull{
    return [NSString stringWithFormat:@"Sending request: %@", [request.URL absoluteString]];
  }];
  NSMutableString *output = [NSMutableString stringWithFormat:@"Headers: %@", request.allHTTPHeaderFields];
  if ([[request HTTPBody] length] > 0) {
    [output appendFormat:@"\nData: %@", [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding]];
  }
  [SGKLog verbose:@"SVKServer" block:^NSString * _Nonnull{
    return [NSString stringWithFormat:@"%@", output];
  }];
#endif
  
  NSURLSession *defaultSession = [NSURLSession sharedSession];
  NSURLSessionDataTask *task = [defaultSession dataTaskWithRequest:request
                                                 completionHandler:
                                ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                  NSInteger status = 0;
                                  if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                    status = httpResponse.statusCode;

                                    [SGKLog verbose:@"SVKServer" block:^NSString * _Nonnull{
                                      return [NSString stringWithFormat:@"Received %@ from %@.\nHeaders: %@", @(status), [httpResponse.URL absoluteString], httpResponse.allHeaderFields];
                                    }];
                                  }
                                  
                                  if (error) {
                                    completion(status, nil, nil, error);
                                    
                                  } else if (data.length == 0) {
                                    // empty response is not an error
                                    completion(status, nil, nil, nil);
                                    
                                  } else {
                                    [SGKLog verbose:@"SVKServer" block:^NSString * _Nonnull{
                                      return [NSString stringWithFormat:@"Data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
                                    }];
                                    
                                    NSError *parserError = nil;
                                    id responseObject = [NSJSONSerialization JSONObjectWithData:data
                                                                                        options:0
                                                                                          error:&parserError];
                                    if (responseObject) {
                                      SVKError *serverError = [SVKError errorFromJSON:responseObject];
                                      if (serverError != nil) {
                                        completion(status, nil, nil,  serverError);
                                      } else {
                                        completion(status, responseObject, data, nil);
                                      }
                                    } else {
                                      [SGKLog error:@"SVKError" format:@"Could not parse: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
                                      completion(status, nil, nil, parserError);
                                    }
                                  }
                                }];
  [task resume];
}

- (void)hitSkedGoWithMethod:(NSString *)method
                       path:(NSString *)path
                 parameters:(nullable NSDictionary *)parameters
                     region:(nullable SVKRegion *)region
                    success:(SGServerSuccessBlock)success
                    failure:(SGServerFailureBlock)failure
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
                 parameters:(nullable NSDictionary *)parameters
                     region:(nullable SVKRegion *)region
             callbackOnMain:(BOOL)callbackOnMain
                    success:(SGServerSuccessBlock)success
                    failure:(SGServerFailureBlock)failure
{
  [self hitSkedGoWithMethod:method
                       path:path
                 parameters:parameters
                 customData:nil
                     region:region
             callbackOnMain:callbackOnMain
                    success:success
                    failure:failure];
}

- (void)hitSkedGoWithMethod:(NSString *)method
                       path:(NSString *)path
                 parameters:(nullable NSDictionary *)parameters
                 customData:(nullable NSData*)customData
                     region:(nullable SVKRegion *)region
             callbackOnMain:(BOOL)callbackOnMain
                    success:(SGServerSuccessBlock)success
                    failure:(SGServerFailureBlock)failure
{
  [self initiateDataTaskWithMethod:method
                              path:path
                        parameters:parameters
                        customData:customData
                   waitForResponse:NO
                         forRegion:region
                       backupIndex:0
                    callbackOnMain:callbackOnMain
                           success:success
                           failure:failure
                    previousStatus:0
                  previousResponse:nil
                      previousData:nil
                     previousError:nil];
}

- (nullable id)initiateSyncRequestWithMethod:(NSString *)method
                                        path:(NSString *)path
                                  parameters:(NSDictionary *)parameters
                                      region:(SVKRegion *)region
{
  return [self initiateDataTaskWithMethod:method
                                     path:path
                               parameters:parameters
                               customData:nil
                          waitForResponse:YES
                                forRegion:region
                              backupIndex:0
                           callbackOnMain:NO // irrelevant
                                  success:nil
                                  failure:nil
                           previousStatus:0
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
  SVKServerType currentType = [[NSUserDefaults sharedDefaults] integerForKey:SVKDefaultsKeyServerType];
  NSString *developmentServer = [SVKServer developmentServer];

  // This method gets called tons of times, but we only want to clear existing
  // regions if and only if user has changed server type in the Beta build.
  if (currentType != self.lastServerType
      || (currentType == SVKServerTypeLocal && ![developmentServer isEqualToString:self.lastDevelopmentServer])) {
    
    // Clearing regions below will trigger a user defaults update, so we make sure we ignore it
    self.lastServerType = currentType;
    self.lastDevelopmentServer = developmentServer;
    self.region = nil;
    
    // User tokens are bound to servers, so clear those, too.
    [SVKServer updateUserToken:nil];
    
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
  switch ([SVKServer serverType]) {
    case SVKServerTypeProduction:
      regionsURLString = @"https://tripgo.skedgo.com/satapp/regions.json";
      break;
      
    case SVKServerTypeBeta:
      regionsURLString = @"https://bigbang.buzzhives.com/satapp-beta/regions.json";
      break;

    case SVKServerTypeLocal:
      regionsURLString = [[SVKServer developmentServer] stringByAppendingString:@"regions.json"];
      break;
  }
  
  NSMutableDictionary *paras = [NSMutableDictionary dictionaryWithCapacity:2];
  paras[@"v"] = @2;
  if (!forced) {
    [paras setValue:[[SVKRegionManager sharedInstance] regionsHash] forKey:@"hashCode"];
  }
  
  [SVKServer POST:[NSURL URLWithString:regionsURLString]
            paras:paras
       completion:
   ^(NSInteger status, id  _Nullable responseObject, NSData *data, NSError * _Nullable error) {
#pragma unused(status)
     if (responseObject) {
       [[SVKRegionManager sharedInstance] updateRegionsFromJSON:responseObject];
       
       if ([[SVKRegionManager sharedInstance] hasRegions]) {
         if (completion) {
           completion(YES, nil);
         }
       } else {
         NSString *message = NSLocalizedStringFromTableInBundle(@"Could not download supported regions from TripGo's server. Please try again later.", @"Shared", [SGStyleManager bundle], "Could not download supported regions warning. (old key: CouldNotDownloadSupportedRegions)");
         NSError *userError = [NSError errorWithCode:kSVKServerErrorTypeUser  message:message];
         if (completion) {
           completion(NO, userError);
         }
       }
       
     } else {
       [SGKLog warn:@"SVKServer" format:@"Couldn't fetch regions. Error: %@", error];
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
    if ([SGKBetaHelper isBeta]) {
      // this only applies in DEBUG mode when the UI has elements to switching the backend server
      // listen to future changes
      NSUserDefaults *sharedDefaults = [NSUserDefaults sharedDefaults];
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(updateFromSettings)
                                                   name:NSUserDefaultsDidChangeNotification
                                                 object:sharedDefaults];
    }
    
    self.lastServerType = [[NSUserDefaults sharedDefaults] integerForKey:SVKDefaultsKeyServerType];;
    self.lastDevelopmentServer = [SVKServer developmentServer];
  }
  
  return self;
}

- (nullable id)initiateDataTaskWithMethod:(NSString *)method
                                     path:(NSString *)path
                               parameters:(nullable NSDictionary *)parameters
                               customData:(nullable NSData*) customData
                          waitForResponse:(BOOL)wait
                                forRegion:(nullable SVKRegion *)region
                              backupIndex:(NSInteger)backupIndex
                           callbackOnMain:(BOOL)callbackOnMain
                                  success:(nullable SGServerSuccessBlock)success
                                  failure:(nullable SGServerFailureBlock)failure
                           previousStatus:(NSInteger)previousStatus
                         previousResponse:(nullable id)previousResponse
                             previousData:(nullable NSData *)previousData
                            previousError:(nullable NSError *)previousError
{
#ifdef DEBUG
  ZAssert(! wait || ! [NSThread isMainThread], @"Don't wait on the main thread!");
#endif
  
  // update region and index first as this might invalidate the client
  if (region != self.region) {
    self.region = region;
  }
  
  self.serverIndex = backupIndex;
  
  NSURL *baseURL = [self currentBaseURL];
  if (! baseURL) {
    // don't have that many servers
    if (! previousError) {
      if (success) {
        if (callbackOnMain) {
          dispatch_async(dispatch_get_main_queue(), ^{
            success(previousStatus, previousResponse, previousData);
          });
        } else {
          success(previousStatus, previousResponse, previousData);
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
    
    self.serverIndex = 0;
    return nil;
  }
  
  // Create the request
  NSURL *fullURL = [baseURL URLByAppendingPathComponent:path];
  NSURLRequest *request = nil;
  if ([method isEqualToString:@"GET"]) {
    request = [SVKServer GETRequestWithSkedGoHTTPHeadersForURL:fullURL paras:parameters];
  } else if ([method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"] || [method isEqualToString:@"DELETE"]) {
    // all of these work like post in terms of body and headers
    request = [SVKServer POSTLikeRequestWithSkedGoHTTPHeadersForURL:fullURL method:method paras:parameters customData:customData];
  } else {
    ZAssert(false, @"Method is not supported: %@", request);
  }
  
  // Backup handler
  void (^failOverBlock)(NSInteger, id, NSData *, NSError *) = ^(NSInteger status, id responseObject, NSData *data, NSError *error) {
    [self initiateDataTaskWithMethod:method
                                path:path
                          parameters:parameters
                          customData:customData
                     waitForResponse:wait
                           forRegion:region
                         backupIndex:backupIndex + 1
                      callbackOnMain:callbackOnMain
                             success:success
                             failure:failure
                      previousStatus:status
                    previousResponse:responseObject
                        previousData:data
                       previousError:error];
  };
  
  // hit the main client
  __block id successResponse = nil;
  __block NSError *failureError = nil;
  dispatch_semaphore_t semaphore = wait ? dispatch_semaphore_create(0) : NULL;
  
  [SVKServer hitRequest:request
             completion:
   ^(NSInteger status, id  _Nullable responseObject, NSData *data, NSError * _Nullable error) {
     NSError *serverError = error ?: [SVKError errorFromJSON:responseObject];
     if (serverError) {
       BOOL isUserError = NO;
       if ([serverError isKindOfClass:[SVKError class]]) {
         isUserError = [(SVKError *)serverError isUserError];
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
         failOverBlock(status, responseObject, data, error);
       }
       
     } else {
       successResponse = responseObject;
       if (success) {
         if (callbackOnMain) {
           dispatch_async(dispatch_get_main_queue(), ^{
             success(status, successResponse, data);
           });
         } else {
           success(status, successResponse, data);
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

+ (nullable NSString *)xTripGoVersion
{
  NSString *eligibility = [[SGKConfig sharedInstance] regionEligibility];
  if (eligibility == nil) {
    return nil;
  }
  
  NSString *app = eligibility.length > 0 ? [@"-" stringByAppendingString:eligibility] : eligibility;

  NSNumber *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
  return [NSString stringWithFormat:@"i%@%@", app, version];
}

#pragma mark - Regions

- (void)requireRegions:(void(^)(NSError *error))completion
{
  if (! completion) {
    ZAssert(false, @"Completion block required.");
    return;
  }
  
  if ([[SVKRegionManager sharedInstance] hasRegions]) {
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

- (NSURL *)currentBaseURL
{
  if (self.regionServers.count <= _serverIndex)
    return nil;
  
  NSURL *url = [self.regionServers objectAtIndex:_serverIndex];
  NSString *urlString = url.absoluteString;
  
  if (urlString.length > 0 && [urlString characterAtIndex:urlString.length - 1] != '/') {
    urlString = [urlString stringByAppendingString:@"/"];
    url = [NSURL URLWithString:urlString];
  }
  
  return url;
}

- (NSArray<NSURL *> *)productionServers
{
  // Check if we have a region specific url we want to use
  if (_region != nil) {
    if ([_region.urls count] > 0) {
      return _region.urls;
    } else {
      return @[ [NSURL URLWithString:@"https://tripgo.skedgo.com/satapp/"] ];
    }
  } else {
    return @[ [NSURL URLWithString:@"https://tripgo.skedgo.com/satapp/"] ];
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

+ (NSMutableDictionary *)SkedGoHTTPHeaders
{
  NSMutableDictionary *headers = [NSMutableDictionary dictionary];
  
  NSString *APIKey = [[SVKServer sharedInstance] APIKey];
  if (APIKey.length > 0) {
    headers[@"X-TripGo-Key"] = APIKey;
  } else {
    // Deprecated
    [SGKLog warn:@"SVKServer" text:@"API key not specified! Check your Config.plist for TripGoAPIKey."];
    headers[@"X-TripGo-RegionEligibility"] = [[SGKConfig sharedInstance] regionEligibility];
  }
  
  // Optional
  [headers setValue:[SVKServer xTripGoVersion] forKey:@"X-TripGo-Version"];
  [headers setValue:[SVKServer persistentUUID] forKey:@"X-TripGo-UUID"];
  [headers setValue:[SVKServer userToken] forKey:@"userToken"];
  
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
  NSArray <NSBundle *>* bundles = [[SVKServer sharedInstance] fileBundles];
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

+ (NSURLRequest *)GETRequestWithSkedGoHTTPHeadersForURL:(nonnull NSURL *)URL paras:(nullable NSDictionary *)paras
{
  if (paras.count > 0) {
    URL = [self URLForGetRequestToBaseURL:URL paras:paras];
  }
  NSURL *adjusted = [self adjustedFileURLForURL:URL];
  if (adjusted) {
    URL = adjusted;
  }

  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
  
  NSDictionary *headers = [SVKServer SkedGoHTTPHeaders];
  [headers enumerateKeysAndObjectsUsingBlock:^(NSString * __nonnull key, NSString *  __nonnull obj, BOOL * __nonnull stop) {
#pragma unused(stop)
    [request setValue:obj forHTTPHeaderField:key];
  }];
  
  return request;
}

+ (NSURLRequest *)POSTLikeRequestWithSkedGoHTTPHeadersForURL:(NSURL *)URL method:(NSString *)method paras:(nullable NSDictionary *)paras
{
  return [self POSTLikeRequestWithSkedGoHTTPHeadersForURL:URL method:method paras:paras customData:nil];
}

+ (NSURLRequest *)POSTLikeRequestWithSkedGoHTTPHeadersForURL:(NSURL *)URL method:(NSString *)method paras:(nullable NSDictionary *)paras customData:(NSData*) customData
{
  ZAssert([method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"] || [method isEqualToString:@"DELETE"], @"Bad method: %@", method);
  
  NSURL *adjusted = [self adjustedFileURLForURL:URL];
  if (adjusted) {
    // POST not supported. Switch to GET.
    return [self GETRequestWithSkedGoHTTPHeadersForURL:adjusted paras:paras];
  }

  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
  request.HTTPMethod = method;
  
  NSDictionary *headers = [SVKServer SkedGoHTTPHeaders];
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

#pragma mark - Custom accessors

- (void)setRegion:(SVKRegion *)region
{
  if (region != _region) {
    _region = region;
  }
  
  _regionServers = nil;
  self.serverIndex = 0;
}

- (void)setServerIndex:(NSUInteger)serverIndex
{
  if (_serverIndex != serverIndex) {
    _serverIndex = serverIndex;
  }
}

#pragma mark - Lazy accessors

- (NSArray<NSURL *> *)regionServers
{
  if (_regionServers != nil) {
    return _regionServers;
  }
  
  switch ([SVKServer serverType]) {
    case SVKServerTypeLocal: {
      _regionServers = @[ [NSURL URLWithString:[SVKServer developmentServer] ] ];
      break;
    }
      
    case SVKServerTypeBeta: {
      _regionServers = @[ [NSURL URLWithString:@"https://bigbang.buzzhives.com/satapp-beta/"] ];
      break;
    }

    case SVKServerTypeProduction: {
      _regionServers = [self productionServers];
      break;
    }
  }
  
  return _regionServers;
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
