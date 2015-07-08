//
//  BHBuzzRouter.h
//  TripGo
//
//  Created by Adrian Schönig on 2/03/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import "TKRouter.h"

@class Trip;
@protocol TKTripClassifier;

NS_ASSUME_NONNULL_BEGIN

@interface TKBuzzRouter : TKRouter

- (void)multiFetchTripsForRequest:(TripRequest *)request
                       classifier:(nullable id<TKTripClassifier>)classifier
                       completion:(void (^)(TripRequest * __nullable, NSError * __nullable))completion;

- (NSDictionary *)createRequestParametersForRequest:(TripRequest *)request
                                 andModeIdentifiers:(NSSet *)modeIdentifiers
                                           bestOnly:(BOOL)bestOnly;

- (void)fetchBestTripForRequest:(TripRequest *)request
                        success:(TKRouterSuccess)success
                        failure:(TKRouterError)failure;

- (void)downloadTrip:(NSURL *)url
  intoTripKitContext:(NSManagedObjectContext *)tripKitContext
          completion:(void(^)(Trip * __nullable trip))completion;

- (void)updateTrip:(Trip *)trip
        completion:(void(^)(Trip * __nullable trip))completion;


@end

NS_ASSUME_NONNULL_END
