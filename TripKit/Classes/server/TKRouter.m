//
//  TKRouter.m
//  TripKit
//
//  Created by Adrian Schönig on 2/03/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import "TKRouter.h"

#import <TripKit/TripKit-Swift.h>

#import "TKTransportModes.h"
#import "TripRequest.h"
#import "TripRequest+Classify.h"

#define kBHRoutingTimeOutSecond           30

@interface TKRouter ()

@property (nonatomic, assign) BOOL isActive;

@property (nonatomic, strong) NSError *lastWorkerError;
@property (nonatomic, strong) NSMutableDictionary *workerRouters;
@property (nonatomic, assign) NSUInteger finishedWorkers;

@end

@implementation TKRouter

#pragma mark - Public interface

- (void)fetchTripsForRequest:(TripRequest *)request
                     success:(TKRouterSuccess)success
                     failure:(TKRouterError)failure
{
  ZAssert(success, @"Success block is required");
  
  if ([request isDeleted]) {
    NSError *error = [NSError errorWithCode:kTKErrorTypeInternal
                                    message:@"Trip request deleted."];
    if (failure) {
      failure(error, self.modeIdentifiers);
    }
    return;
  }

  _currentRequest = request;
  return [self fetchTripsForCurrentRequestSuccess:success
                                          failure:failure];
}

- (void)cancelRequests
{
  for (TKRouter *worker in self.workerRouters) {
      if ([worker respondsToSelector:@selector(cancelRequests)]) {
          [worker cancelRequests];
      }
  }
  self.workerRouters = nil;
  self.lastWorkerError = nil;
  
  self.isActive = NO;
}

- (NSUInteger)multiFetchTripsForRequest:(TripRequest *)request
                                  modes:(nullable NSArray<NSString *>*)modes
                             classifier:(nullable id<TKTripClassifier>)classifier
                               progress:(nullable void (^)(NSUInteger))progress
                             completion:(void (^)(TripRequest * __nullable, NSError * __nullable))completion
{
  [self cancelRequests];
  self.isActive = YES;
  
  NSArray *enabledModes = modes;
  if (enabledModes == nil || modes.count == 0) {
    NSArray *applicableModes = [request applicableModeIdentifiers];
    NSMutableArray *mutableModes = [NSMutableArray arrayWithArray:applicableModes];
    [mutableModes removeObjectsInArray:[[TKUserProfileHelper hiddenModeIdentifiers] allObjects]];
    enabledModes = mutableModes;
  }
  
  NSSet *groupedIdentifiers;
  BOOL includesAllModes = NO;
  for (NSURLQueryItem *item in self.additionalParameters) {
    if ([item.name isEqualToString:@"allModes"]) {
      includesAllModes = YES;
      break;
    }
  }
  
  if (includesAllModes) {
    groupedIdentifiers = [NSSet setWithObject:[NSSet setWithArray:enabledModes]];
  } else {
    groupedIdentifiers = [TKTransportModes groupedModeIdentifiers:enabledModes includeGroupForAll:YES];
  }
  
  NSUInteger requestCount = [groupedIdentifiers count];
  self.finishedWorkers = 0;
  
  if (!self.workerRouters) {
    self.workerRouters = [NSMutableDictionary dictionaryWithCapacity:requestCount];
  }
  
  // we'll adjust the visibility in the completion block
  request.defaultVisibility = TKTripGroupVisibilityHidden;

  for (NSSet *modeIdentifiers in groupedIdentifiers) {
    TKRouter *worker = self.workerRouters[modeIdentifiers];
    if (worker) {
      continue;
    }
    
    worker = [[TKRouter alloc] init];
    self.workerRouters[modeIdentifiers] = worker;
    worker.modeIdentifiers = modeIdentifiers;
    worker.additionalParameters = self.additionalParameters;
    
    __weak typeof(self) weakSelf = self;
    [worker fetchTripsForRequest:request
                         success:
     ^(TripRequest *completedRequest, NSSet *completedIdentifiers) {
       typeof(weakSelf) strongSelf = weakSelf;
       if (strongSelf) {
         
         if (modes == nil) {
           // We get thet minimized and hidden modes here in the completion block
           // since they might have changed while waiting for results
           NSSet *minimized = [TKUserProfileHelper minimizedModeIdentifiers];
           NSSet *hidden = [TKUserProfileHelper hiddenModeIdentifiers];
           [completedRequest adjustVisibilityForMinimizedModeIdentifiers:minimized
                                                   hiddenModeIdentifiers:hidden];
         } else {
           [completedRequest adjustVisibilityForMinimizedModeIdentifiers:[NSSet set] hiddenModeIdentifiers:[NSSet set]];
         }
         
         // Updating classifications before making results visible
         if (classifier) {
            [completedRequest updateTripGroupClassificationsUsingClassifier:classifier];
         }
           
         strongSelf.finishedWorkers++;
         if (progress) {
           progress(strongSelf.finishedWorkers);
         }
         
         [strongSelf handleMultiFetchResult:completedRequest
                             completedModes:completedIdentifiers
                                      error:nil
                                 completion:completion];
       }
     }
                         failure:
     ^(NSError *error, NSSet *erroredIdentifiers) {
       typeof(weakSelf) strongSelf = weakSelf;
       if (strongSelf) {
         [strongSelf handleMultiFetchResult:request
                             completedModes:erroredIdentifiers
                                      error:error
                                 completion:completion];
       }
     }];
  }
  
  return requestCount;
}

- (void)handleMultiFetchResult:(TripRequest *)request
                completedModes:(NSSet *)modeIdentifiers
                         error:(NSError *)error
                    completion:(void (^)(TripRequest *, NSError *))completion
{
  [self.workerRouters removeObjectForKey:modeIdentifiers];
  
  if (self.workerRouters.count == 0) {

    NSError *errorToShow = nil;
    if (request.trips.count == 0) {
      errorToShow = error ?: self.lastWorkerError;
    }
    completion(request, errorToShow);
    
  } else {
    self.lastWorkerError = error;
  }
}

- (void)downloadTrip:(NSURL *)url
  intoTripKitContext:(NSManagedObjectContext *)tripKitContext
          completion:(void(^)(Trip * __nullable trip))completion
{
  [self downloadTrip:url identifier:nil intoTripKitContext:tripKitContext completion:completion];
}

- (void)downloadTrip:(NSURL *)url
          identifier:(nullable NSString *)identifier
  intoTripKitContext:(NSManagedObjectContext *)tripKitContext
          completion:(void(^)(Trip * __nullable trip))completion
{
  if (!identifier) {
    NSUInteger hash = [[url absoluteString] hash];
    identifier = [NSString stringWithFormat:@"%lu", (unsigned long) hash];
  }
  
  TKFileCacheDirectory directory = TKFileCacheDirectoryDocuments;

  void (^withJSON)(id, NSURL * _Nullable) = ^void(id JSON, NSURL * _Nullable shareURL) {
    [self parseJSON:JSON forTripKitContext:tripKitContext completion:
     ^(Trip *trip) {
       if (shareURL) {
         trip.shareURL = shareURL;
       }
       trip.request.expandForFavorite = YES;
       if (completion) {
         completion(trip);
       }
     }];
  };
  
  [self hitURLForTripDownload:url completion:
   ^(NSURL *shareURL, id JSON, NSError *error) {
     if (JSON) {
       [TKJSONCache save:identifier dictionary:JSON directory:directory subdirectory:nil];
       withJSON(JSON, shareURL);
       
     } else {
       NSDictionary *JSON = [TKJSONCache read:identifier directory:directory];
       if (JSON) {
         withJSON(JSON, nil);
       } else {
         
         // failure
         [TKLog info:NSStringFromClass([self class]) text:[NSString stringWithFormat:@"Failed to download trip, and no copy in cache. Error: %@", error]];
         if (completion) {
           completion(nil);
         }
       }
     }
    }];
}

- (void)updateTrip:(Trip *)trip completionWithFlag:(void(^)(Trip *trip, BOOL tripUpdated))completion
{
  NSURL *updateURL = [NSURL URLWithString:trip.updateURLString];
  if (updateURL == nil) {
    [TKLog info:@"TKRouter" text:[NSString stringWithFormat:@"Tried to update a trip that doesn't have a (valid) update URL: %@", trip]];
    completion(trip, NO);
    return;
  }
  
  [self hitURLForTripDownload:updateURL completion:^(NSURL *shareURL, id JSON, NSError *error) {
#pragma unused(shareURL)
    if (JSON) {
      [self parseJSON:JSON updatingTrip:trip completion:^(Trip * _Nullable updatedTrip) {
        [TKLog debug:NSStringFromClass([self class]) block:^NSString * _Nonnull{
          __block NSString *result = nil;
          [updatedTrip.managedObjectContext performBlockAndWait:^{
            result = [NSString stringWithFormat:@"Updated trip (%ld): %@", (long)updatedTrip.tripGroup.visibility, [updatedTrip debugString]];
          }];
          return result;
        }];
        if (completion) {
          if (updatedTrip != nil) {
            completion(updatedTrip, YES);
          } else {
            completion(trip, NO);
          }
        }
      }];
    } else if (! error) {
        // No new data (but also no error
      [TKLog debug:NSStringFromClass([self class]) block:^NSString * _Nonnull{
        __block NSString *result = nil;
        [trip.managedObjectContext performBlockAndWait:^{
          result = [NSString stringWithFormat:@"No update for trip (%ld): %@", (long)trip.tripGroup.visibility, [trip debugString]];
        }];
        return result;
      }];
      if (completion) {
        completion(trip, NO);
      }
    }
  }];
}

- (void)updateTrip:(Trip *)trip completion:(void(^)(Trip *trip))completion
{
    [self updateTrip:trip completionWithFlag:^(Trip *updatedTrip, BOOL tripGotUpdated) {
#pragma unused(tripGotUpdated)
        completion(updatedTrip);
    }];
}

- (void)updateTrip:(Trip *)trip
           fromURL:(NSURL *)URL
           aborter:(nullable BOOL(^)(NSURL *URL))aborter
        completion:(void(^)(NSURL *URL, Trip * __nullable trip, NSError * __nullable error))completion
{
  [self hitURLForTripDownload:URL
                   completion:
   ^(NSURL *shareURL, id JSON, NSError *error) {
#pragma unused(shareURL)
    if (JSON) {
      if (aborter && aborter(URL)) {
        return;
      }
      
      [self parseJSON:JSON
         updatingTrip:trip
           completion:
       ^(Trip *updatedTrip) {
         completion(URL, updatedTrip, nil);
      }];
    } else {
      completion(URL, nil, error);
    }
  }];
}


- (void)fetchBestTripForRequest:(TripRequest *)request
                        success:(TKRouterSuccess)success
                        failure:(TKRouterError)failure
{
  request.expandForFavorite = YES;
  self.currentRequest = request;
  return [self fetchTripsForCurrentRequestBestOnly:YES
                                           success:success
                                           failure:failure];
}

- (void)fetchTripsForCurrentRequestSuccess:(TKRouterSuccess)success
                                   failure:(TKRouterError)failure
{
  [self fetchTripsForCurrentRequestBestOnly:NO success:success failure:failure];
}

- (void)fetchTripsForCurrentRequestBestOnly:(BOOL)bestOnly
                                    success:(TKRouterSuccess)success
                                    failure:(TKRouterError)failure
{
  ZAssert(success && failure, @"Success and failure blocks are required");

	// some sanity checks
	if (nil == self.currentRequest
			|| nil == self.currentRequest.fromLocation
			|| nil == self.currentRequest.toLocation) {
		ZAssert(false, @"Tried routing for a bad request: %@", self.currentRequest);

		NSError *error = [NSError errorWithCode:81350
																		message:@"Bad request."];
		[self handleError:error
							failure:failure];
		return;
	}
	
	// check from/to coordinates
	if (! CLLocationCoordinate2DIsValid([self.currentRequest.fromLocation coordinate])) {
		ZAssert(false, @"Tried routing with bad from location: %@", self.currentRequest.fromLocation);
		
		NSError *error = [NSError errorWithCode:kTKServerErrorTypeUser
																		message:@"Start location could not be determined. Please try again or select manually."];
		
		[self handleError:error
							failure:failure];
		return;
	}

	if (! CLLocationCoordinate2DIsValid([self.currentRequest.toLocation coordinate])) {
		ZAssert(false, @"Tried routing with bad to location: %@", self.currentRequest.toLocation);
		
		NSError *error = [NSError errorWithCode:kTKServerErrorTypeUser
																		message:@"End location could not be determined. Please try again or select manually."];
		
		[self handleError:error
							failure:failure];
		return;
	}

	__weak typeof(self) weakSelf = self;
  TKServer *server = [TKServer sharedInstance];
	[server requireRegions:^(NSError *error) {
    typeof(weakSelf) strongSelf = weakSelf;
		if (! strongSelf) {
			return;
		}
		
    // Mark as active early, to make sure we pass on errors
    strongSelf.isActive = YES;

    if (error) {
			// could not get regions
			[strongSelf handleError:error
                      failure:failure];
			return;
		}
    
    // we are guaranteed to have regions
    TripRequest *request = strongSelf.currentRequest;
    TKRegion *region = [request startRegion];
    if (! region) {
      error = [NSError errorWithCode:1001 // matches server
                             message:Loc.RoutingBetweenTheseLocationsIsNotYetSupported];
      [strongSelf handleError:error
                      failure:failure];
      return;
    }
    
    // we are good to send requests. create them, then tell the caller.
    NSDate *ASAPTime = nil;
    if (request.type == TKTimeTypeLeaveASAP) {
      ASAPTime = [NSDate date];
      request.departureTime = ASAPTime;
      request.timeType = @(TKTimeTypeLeaveAfter);
    }
    
    NSDictionary *paras = [strongSelf createRequestParametersForRequest:request
                                                     andModeIdentifiers:strongSelf.modeIdentifiers
                                                               bestOnly:bestOnly
                                                           withASAPTime:ASAPTime];
    [server hitSkedGoWithMethod:@"GET"
                           path:@"routing.json"
                     parameters:paras
                         region:region
                 callbackOnMain:NO
                        success:
     ^(NSInteger status, id responseObject, NSData *data) {
#pragma unused(status, data)
       typeof(weakSelf) strongSelf2 = weakSelf;
       if (! strongSelf2) {
         return;
       }
       
       [strongSelf2 parseJSON:responseObject
            forTripKitContext:request.managedObjectContext
                      success:success
                      failure:failure];
     }
                        failure:
     ^(NSError *error2) {
       typeof(weakSelf) strongSelf2 = weakSelf;
       if (! strongSelf2) {
         return;
       }
       
       [strongSelf2 handleError:error2
                        failure:failure];
     }];
  }];
}

+ (NSString *)urlForRoutingRequest:(TripRequest *)tripRequest
               withModeIdentifiers:(NSSet *)modeIdentifiers
{
  TKRouter *router = [[TKRouter alloc] init];
  NSDictionary *paras = [router createRequestParametersForRequest:tripRequest andModeIdentifiers:modeIdentifiers bestOnly:NO withASAPTime:nil];
  NSURL *baseUrl = [[TKServer sharedInstance] currentBaseURL];
  if (!baseUrl) {
    return nil;
  }
  NSURL *fullUrl = [baseUrl URLByAppendingPathComponent:@"routing.json"];
  NSURLRequest *request = [TKServer GETRequestWithSkedGoHTTPHeadersForURL:fullUrl paras:paras];
  return [[request URL] absoluteString];
}


#pragma mark - Private methods

- (void)hitURLForTripDownload:(NSURL *)url completion:(void (^)(NSURL *shareURL, id JSON, NSError *error))completion
{
  NSURL *baseURL;
  if ([url.scheme isEqualToString:@"file"]) {
    baseURL = url;
    
  } else {
    // de-construct the URL
    NSString *port = nil != url.port ? [NSString stringWithFormat:@":%@", url.port] : @"";
    NSString *scheme = [url.scheme hasPrefix:@"http"] ? url.scheme : @"https"; // keep http and https, but replace stuff like $appname://
    NSString *baseURLString = [NSString stringWithFormat:@"%@://%@%@%@", scheme, url.host, port, url.path];
    baseURL = [NSURL URLWithString:baseURLString];
  }
  
  // use our default parameters and append those from the URL
  NSMutableDictionary *paras = [TKSettings defaultDictionary];
  NSString *query = url.query;
  for (NSString *option in [query componentsSeparatedByString:@"&"]) {
    NSArray *pair = [option componentsSeparatedByString:@"="];
    if (pair.count == 1) {
      [paras setValue:@(YES) forKey:pair[0]];
    } else if (pair.count == 2) {
      [paras setValue:pair[1] forKey:pair[0]];
    } else {
      [TKLog info:@"TKRouter" text:[NSString stringWithFormat:@"Unknown option: %@", option]];
    }
  }
  
  // Hit it
  [TKServer GET:baseURL paras:paras completion:
   ^(NSInteger status, NSDictionary<NSString *,id> *headers, id  _Nullable responseObject, NSData *data, NSError * _Nullable error) {
#pragma unused(status, headers, data)
     completion(baseURL, responseObject, error);
   }];
}

- (void)parseJSON:(id)json
forTripKitContext:(NSManagedObjectContext *)tripKitContext
					success:(TKRouterSuccess)success
					failure:(TKRouterError)failure
{
  ZAssert(success && failure, @"Success and failure blocks are required");
  
  if (! self.isActive) {
    // ignore responses from outdated requests
    return;
  }
	
	// make sure that the parent context is saved
  [tripKitContext performBlock:^{
    NSError *error = nil;
    BOOL saved = [tripKitContext save:&error];
    
    if (saved) {
      [self parseAndAddResult:json
           intoTripKitContext:tripKitContext
                      success:
       ^(NSArray *addedTrips) {
         self.isActive = NO;
         if (addedTrips) {
           success(self.currentRequest, self.modeIdentifiers);
         }
       }
                      failure:failure];
      
    } else {
      ZAssert(false, @"Error saving: %@", error);
      self.isActive = NO;
      if (failure) {
        failure(error, self.modeIdentifiers);
      }
    }
    self.isActive = NO;
  }];
}

- (void)handleError:(NSError *)error
						failure:(TKRouterError)failure
{
	if (! self.isActive) {
    // ignore responses from outdated requests
    return;
	}

  [TKLog debug:NSStringFromClass([self class]) block:^NSString * _Nonnull {
    return [NSString stringWithFormat:@"Request failed with error: %@", [error description]];
  }];
  self.isActive = NO;
  
  dispatch_async(dispatch_get_main_queue(), ^{
		if (failure) {
			failure(error, self.modeIdentifiers);
		}
  });
}

- (void)parseJSON:(id)json
     updatingTrip:(Trip *)trip
       completion:(void(^)(Trip * __nullable trip))completion
{
  NSString *error = [json objectForKey:@"error"];
  if (error) {
    if (completion) {
      completion(nil);
    }
    return;
  }
  
  NSManagedObjectContext *tripKitContext = trip.managedObjectContext;
  TKRoutingParser *parser = [[TKRoutingParser alloc] initWithTripKitContext:tripKitContext];
  [parser parseJSON:json
       updatingTrip:trip
         completion:
   ^(Trip *updatedTrip) {
     if (updatedTrip) {
       ZAssert(updatedTrip.managedObjectContext == tripKitContext, @"Context mismatch.");
       ZAssert(updatedTrip == trip, @"Trip object shouldn't have changed");
       NSError *publicError = nil;
       BOOL publicSuccess = [tripKitContext save:&publicError];
       ZAssert(publicSuccess, @"Error saving: %@", publicError);
       
       completion(updatedTrip);
     } else {
       // failure
       completion(nil);
     }
   }];
}

- (void)parseJSON:(id)json
forTripKitContext:(NSManagedObjectContext *)tripKitContext
       completion:(void(^)(Trip * __nullable trip))completion
{
  NSString *error = [json objectForKey:@"error"];
  if (error) {
    if (completion) {
      completion(nil);
    }
    return;
  }
  
  // parse it
  TKRoutingParser *parser = [[TKRoutingParser alloc] initWithTripKitContext:tripKitContext];
  [parser parseAndAddResult:json
                 completion:
   ^(TripRequest *request) {
     if (!request) {
       completion(nil);
       return;
     }
     
     // make sure we save
     ZAssert(request.managedObjectContext == tripKitContext, @"Context mismatch.");
     NSError *publicError = nil;
     BOOL publicSuccess = [tripKitContext save:&publicError];
     ZAssert(publicSuccess, @"Error saving: %@", publicError);
     
     request.lastSelection = [request.tripGroups anyObject];
     [request.lastSelection adjustVisibleTrip];
     completion(request.preferredTrip);
   }];
}

#pragma mark - Single Requests

- (NSDictionary *)createRequestParametersForRequest:(TripRequest *)request
                                 andModeIdentifiers:(NSSet<NSString *> *)modeIdentifiers
                                           bestOnly:(BOOL)bestOnly
                                       withASAPTime:(NSDate *)ASAPTime
{
	NSMutableDictionary *paras = [TKSettings defaultDictionary];
	
  NSArray *sortedModes = [[modeIdentifiers allObjects] sortedArrayUsingComparator:^NSComparisonResult(NSString * _Nonnull mode1, NSString * _Nonnull mode2) {
    return [mode1 compare:mode2];
  }];
	[paras setValue:sortedModes forKey:@"modes"];
	
  // locations
  NSString *fromString = [TKParserHelper requestStringForAnnotation:request.fromLocation];
  NSString *toString = [TKParserHelper requestStringForAnnotation:request.toLocation];
	[paras setValue:fromString forKey:@"from"];
	[paras setValue:toString forKey:@"to"];

  // times
	NSDate *departure, *arrival = nil;
  switch ((TKTimeType) request.timeType.integerValue) {
    case TKTimeTypeArriveBefore:
    case TKTimeTypeLeaveAfter:
      departure = request.departureTime;
      arrival   = request.arrivalTime;
      break;

    case TKTimeTypeNone:
      // do nothing and let the server do time-independent routing
      break;

    case TKTimeTypeLeaveASAP:
      departure = ASAPTime;
      break;
  }
  
  if (arrival) { // arrival takes precedence over departure as it's more important
                 // to arrive at the next meeting on time, than stick to the end
                 // of the previous meeting
    NSNumber *arriveBefore = @((NSInteger) [arrival timeIntervalSince1970]);
    [paras setValue:arriveBefore forKey:@"arriveBefore"];
  } else if (departure) {
    NSNumber *departAfter =  @((NSInteger) [departure timeIntervalSince1970]);
    [paras setValue:departAfter forKey:@"departAfter"];
  }
  
  if (bestOnly) {
    paras[@"bestOnly"] = @(YES);
    paras[@"includeStops"] = @(YES);
  }
  
  if (request.excludedStops.count > 0) {
    paras[@"avoidStops"] = request.excludedStops;
  }
  
  for (NSURLQueryItem *item in self.additionalParameters) {
    paras[item.name] = item.value;
  }
  
  return paras;
}

#pragma mark - Results

- (void)parseAndAddResult:(id)json
       intoTripKitContext:(NSManagedObjectContext *)tripKitContext
                  success:(void (^)(NSArray *addedTrips))completion
									failure:(TKRouterError)failure
{
  ZAssert(completion && failure, @"Success and failure blocks are required");
  ZAssert(tripKitContext != nil, @"Managed object context required!");
  
  // analyse result
  NSError *serverError = [TKError errorFromJSON:json statusCode:200];
  if (serverError) {
		[self handleError:serverError
							failure:failure];
    return;
  }
	
  TKRoutingParser *parser = [[TKRoutingParser alloc] initWithTripKitContext:tripKitContext];
  [parser parseAndAddResult:json
                 forRequest:self.currentRequest
                    merging:YES
                 completion:completion];
}

@end
