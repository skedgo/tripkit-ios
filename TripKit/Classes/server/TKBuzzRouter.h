//
//  BHBuzzRouter.h
//  TripKit
//
//  Created by Adrian Schönig on 2/03/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

@import CoreData;

#import "TKRouter.h"

@class Trip;
@protocol TKTripClassifier;

NS_ASSUME_NONNULL_BEGIN

/**
 The main class that talks to SkedGo's `routing.json` API.
 */
@interface TKBuzzRouter : TKRouter

/**
 Kicks off the required server requests asynchronously to the servers. As they
 return `progress` is called and the trips get added to TripKit's database. Also
 calls `completion` when all are done.
 
 @note Calling this method will lock-in the departure time for "Leave now" queries.
 
 As trips get added, they get flagged with full, minimised or hidden visibility.
 Which depends on the standard defaults. Check `TKUserProfileHelper` for setting
 those.
 
 @param request The request specifying the query
 @param modes The modes to enable. If set to `nil` then it'll use the modes as set in the
                  user defaults (see `TKUserProfileHelper` for more)
 @param classifier Optional classifier to assign `TripGroup`'s `classification`
 @param progress Optional progress callback executed when each request finished,
        with the number of completed requests passed to the block.
 @param completion Callback executed when all requests have finished with the
        original request and, optionally, an error if all failed.
 @return The number of requests sent. This will match the number of times 
 `progress` is called.
 */
- (NSUInteger)multiFetchTripsForRequest:(TripRequest *)request
                                  modes:(nullable NSArray<NSString *>*)modes
                             classifier:(nullable id<TKTripClassifier>)classifier
                               progress:(nullable void (^)(NSUInteger))progress
                             completion:(void (^)(TripRequest * __nonnull, NSError * __nullable))completion;

/**
 Kicks off the server request to fetch the best trip matching the request and the enabled
 modes according to `TKUserProfileHelper`.
 
 On success, the request's `.trips` and `.tripGroup` properties will be set. Note, that these
 might include multiple trips (despite the naming of this method), which are variants of the
 same trip leaving earlier or later.
 */
- (void)fetchBestTripForRequest:(TripRequest *)request
                        success:(TKRouterSuccess)success
                        failure:(TKRouterError)failure;

- (void)downloadTrip:(NSURL *)url
  intoTripKitContext:(NSManagedObjectContext *)tripKitContext
          completion:(void(^)(Trip * __nullable trip))completion;

- (void)downloadTrip:(NSURL *)url
          identifier:(nullable NSString *)identifier
  intoTripKitContext:(NSManagedObjectContext *)tripKitContext
          completion:(void(^)(Trip * __nullable trip))completion;

- (void)updateTrip:(Trip *)trip
        completion:(void(^)(Trip *trip))completion;

- (void)updateTrip:(Trip *)trip
completionWithFlag:(void(^)(Trip *trip, BOOL tripUpdated))completion;

- (void)updateTrip:(Trip *)trip
           fromURL:(NSURL *)URL
           aborter:(nullable BOOL(^)(NSURL *URL))aborter
        completion:(void(^)(NSURL *URL, Trip * __nullable trip, NSError * __nullable error))completion;

+ (nullable NSString *)urlForRoutingRequest:(TripRequest *)tripRequest
                        withModeIdentifiers:(nullable NSSet *)modeIdentifiers;

@end

NS_ASSUME_NONNULL_END
