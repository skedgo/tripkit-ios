//
//  BHBuzzRouter.m
//  TripGo
//
//  Created by Adrian Schönig on 2/03/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import "TKBuzzRouter.h"

#import <TripKit/TKTripKit.h>
#import <TripKit/TripKit-Swift.h>

#import "TripRequest+Classify.h"

#define kBHRoutingTimeOutSecond           30

@interface TKBuzzRouter ()

@property (nonatomic, assign) BOOL isActive;

@property (nonatomic, strong) NSError *lastWorkerError;
@property (nonatomic, strong) NSMutableDictionary *workerRouters;
@property (nonatomic, assign) NSUInteger finishedWorkers;

@end

@implementation TKBuzzRouter

#pragma mark - Public interface

- (void)cancelRequests
{
  for (TKBuzzRouter *worker in self.workerRouters) {
      if ([worker respondsToSelector:@selector(cancelRequests)]) {
          [worker cancelRequests];
      }
  }
  self.workerRouters = nil;
  self.lastWorkerError = nil;
  
  self.isActive = NO;
}

- (NSUInteger)multiFetchTripsForRequest:(TripRequest *)request
                             classifier:(nullable id<TKTripClassifier>)classifier
                               progress:(nullable void (^)(NSUInteger))progress
                             completion:(void (^)(TripRequest * __nullable, NSError * __nullable))completion
{
  [self cancelRequests];
  self.isActive = YES;
  
  NSArray *applicableModes = [request applicableModeIdentifiers];
  NSMutableArray *enabledModes = [NSMutableArray arrayWithArray:applicableModes];
  [enabledModes removeObjectsInArray:[[TKUserProfileHelper hiddenModeIdentifiers] allObjects]];
  
  NSSet *groupedIdentifiers   = [SVKTransportModes groupedModeIdentifiers:enabledModes includeGroupForAll:YES];
  NSUInteger requestCount = [groupedIdentifiers count];
  self.finishedWorkers = 0;
  
  if (!self.workerRouters) {
    self.workerRouters = [NSMutableDictionary dictionaryWithCapacity:requestCount];
  }
  
  // we'll adjust the visibility in the completion block
  request.defaultVisibility = TripGroupVisibilityHidden;

  for (NSSet *modeIdentifiers in groupedIdentifiers) {
    TKBuzzRouter *worker = self.workerRouters[modeIdentifiers];
    if (worker) {
      continue;
    }
    
    worker = [[TKBuzzRouter alloc] init];
    self.workerRouters[modeIdentifiers] = worker;
    worker.modeIdentifiers = modeIdentifiers;
    
    __weak typeof(self) weakSelf = self;
    [worker fetchTripsForRequest:request
                         success:
     ^(TripRequest *completedRequest, NSSet *completedIdentifiers) {
       typeof(weakSelf) strongSelf = weakSelf;
       if (strongSelf) {
         
         // We get thet minimized and hidden modes here in the completion block
         // since they might have changed while waiting for results
         NSSet *minimized = [TKUserProfileHelper minimizedModeIdentifiers];
         NSSet *hidden = [TKUserProfileHelper hiddenModeIdentifiers];
         [completedRequest adjustVisibilityForMinimizedModeIdentifiers:minimized
                                                 hiddenModeIdentifiers:hidden];
         
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
    identifier = [NSString stringWithFormat:@"%lu", hash];
  }
  
  TKJSONCacheDirectory directory = TKJSONCacheDirectoryDocuments;

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
       [TKJSONCache save:identifier dictionary:JSON directory:directory];
       withJSON(JSON, shareURL);
       
     } else {
       NSDictionary *JSON = [TKJSONCache read:identifier directory:directory];
       if (JSON) {
         withJSON(JSON, nil);
       } else {
         
         // failure
         [SGKLog warn:NSStringFromClass([self class]) format:@"Failed to download trip, and no copy in cache. Error: %@", error];
         if (completion) {
           completion(nil);
         }
       }
     }
    }];
}

- (void)updateTrip:(Trip *)trip completionWithFlag:(void(^)(Trip * __nullable trip, BOOL tripUpdated))completion
{
    NSURL *updateURL = [NSURL URLWithString:trip.updateURLString];
    [self hitURLForTripDownload:updateURL completion:^(NSURL *shareURL, id JSON, NSError *error) {
#pragma unused(shareURL)
        if (JSON) {
          [self parseJSON:JSON updatingTrip:trip completion:^(Trip *updatedTrip) {
            [SGKLog debug:NSStringFromClass([self class]) block:^NSString * _Nonnull{
              __block NSString *result = nil;
              [updatedTrip.managedObjectContext performBlockAndWait:^{
                result = [NSString stringWithFormat:@"Updated trip (%d): %@", updatedTrip.tripGroup.visibility, [updatedTrip debugString]];
              }];
              return result;
            }];
            if (completion) {
                completion(updatedTrip, YES);
            }
          }];
        } else if (! error) {
            // No new data (but also no error
          [SGKLog debug:NSStringFromClass([self class]) block:^NSString * _Nonnull{
            __block NSString *result = nil;
            [trip.managedObjectContext performBlockAndWait:^{
              result = [NSString stringWithFormat:@"No update for trip (%d): %@", trip.tripGroup.visibility, [trip debugString]];
            }];
            return result;
          }];
          if (completion) {
              completion(trip, NO);
          }
        }
    }];
}

- (void)updateTrip:(Trip *)trip completion:(void(^)(Trip * __nullable trip))completion
{
    [self updateTrip:trip completionWithFlag:^(Trip * __nullable updatedTrip, BOOL tripGotUpdated) {
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
		
		NSError *error = [NSError errorWithCode:kSVKServerErrorTypeUser
																		message:@"Start location could not be determined. Please try again or select manually."];
		
		[self handleError:error
							failure:failure];
		return;
	}

	if (! CLLocationCoordinate2DIsValid([self.currentRequest.toLocation coordinate])) {
		ZAssert(false, @"Tried routing with bad to location: %@", self.currentRequest.toLocation);
		
		NSError *error = [NSError errorWithCode:kSVKServerErrorTypeUser
																		message:@"End location could not be determined. Please try again or select manually."];
		
		[self handleError:error
							failure:failure];
		return;
	}

	__weak typeof(self) weakSelf = self;
  SVKServer *server = [SVKServer sharedInstance];
	[server requireRegions:^(NSError *error) {
    typeof(weakSelf) strongSelf = weakSelf;
		if (! strongSelf) {
			return;
		}
		
		if (error) {
			// could not get regions
			[strongSelf handleError:error
                      failure:failure];
			return;
		}
    
    // we are guaranteed to have regions
    TripRequest *request = strongSelf.currentRequest;
    SVKRegion *region = [request localRegion];
    if (! region) {
      error = [NSError errorWithCode:kSVKServerErrorTypeUser
                             message:@"Unsupported region."];
      [strongSelf handleError:error
                      failure:failure];
      return;
    }
    
    // we are good to send requests. create them, then tell the caller.
    strongSelf.isActive = YES;
    
    NSDate *ASAPTime = nil;
    if (request.type == SGTimeTypeLeaveASAP) {
      ASAPTime = [NSDate date];
      request.departureTime = ASAPTime;
      request.timeType = @(SGTimeTypeLeaveAfter);
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
     ^(NSInteger status, id responseObject) {
#pragma unused(status)
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
  TKBuzzRouter *router = [[TKBuzzRouter alloc] init];
  NSDictionary *paras = [router createRequestParametersForRequest:tripRequest andModeIdentifiers:modeIdentifiers bestOnly:NO withASAPTime:nil];
  NSURL *baseUrl = [[SVKServer sharedInstance] currentBaseURL];
  NSURL *fullUrl = [baseUrl URLByAppendingPathComponent:@"routing.json"];
  NSURLRequest *request = [SVKServer GETRequestWithSkedGoHTTPHeadersForURL:fullUrl paras:paras];
  return [[request URL] absoluteString];
}




#pragma mark - Private methods

- (void)hitURLForTripDownload:(NSURL *)url completion:(void (^)(NSURL *shareURL, id JSON, NSError *error))completion
{
  // de-construct the URL
  NSString *port = nil != url.port ? [NSString stringWithFormat:@":%@", url.port] : @"";
  NSString *scheme = [url.scheme hasPrefix:@"http"] ? url.scheme : @"https"; // keep http and https, but replace stuff like $appname://
  NSString *baseURLString = [NSString stringWithFormat:@"%@://%@%@%@", scheme, url.host, port, url.path];
  NSURL *baseURL = [NSURL URLWithString:baseURLString];
  
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
      [SGKLog warn:NSStringFromClass([self class]) format:@"Unknown option: %@", option];
    }
  }
  
  // Hit it
  [SVKServer GET:baseURL paras:paras completion:
   ^(NSInteger status, id  _Nullable responseObject, NSError * _Nullable error) {
#pragma unused(status)
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

  [SGKLog warn:NSStringFromClass([self class]) format:@"Request failed with error %@ (%@)", error, [error description]];
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
  NSString *fromString = [STKParserHelper requestStringForCoordinate:[request.fromLocation coordinate]];
  NSString *toString = [STKParserHelper requestStringForCoordinate:[request.toLocation coordinate]];
	[paras setValue:fromString forKey:@"from"];
	[paras setValue:toString forKey:@"to"];

  // times
	NSDate *departure, *arrival = nil;
  switch ((SGTimeType) request.timeType.integerValue) {
    case SGTimeTypeArriveBefore:
    case SGTimeTypeLeaveAfter:
      departure = request.departureTime;
      arrival   = request.arrivalTime;
      break;

    case SGTimeTypeNone:
      // do nothing and let the server do time-independent routing
      break;

    case SGTimeTypeLeaveASAP:
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
  NSError *serverError = [SVKError errorFromJSON:json];
  if (serverError) {
    [SGKLog warn:NSStringFromClass([self class]) format:@"Encountered server error: %@", serverError];
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
