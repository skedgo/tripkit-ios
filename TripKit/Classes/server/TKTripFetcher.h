//
//  TKTripFetcher.h
//  TripKit
//
//  Created by Adrian Schönig on 2/03/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

@import CoreData;

@class Trip, TripRequest;

NS_ASSUME_NONNULL_BEGIN

@interface TKTripFetcher : NSObject

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

@end

NS_ASSUME_NONNULL_END
