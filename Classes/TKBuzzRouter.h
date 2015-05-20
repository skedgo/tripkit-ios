//
//  BHBuzzRouter.h
//  TripGo
//
//  Created by Adrian Schönig on 2/03/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import "TKRouter.h"

@class Trip;

NS_ASSUME_NONNULL_BEGIN

typedef void (^TKTripDownloadBlock)(Trip * __nullable trip);

@interface TKBuzzRouter : TKRouter

- (void)multiFetchTripsForRequest:(TripRequest *)request
                       completion:(void (^)(TripRequest * __nullable, NSError * __nullable))completion;

- (NSDictionary *)createRequestParametersForRequest:(TripRequest *)request
                                 andModeIdentifiers:(NSSet *)modeIdentifiers
                                           bestOnly:(BOOL)bestOnly;

- (void)fetchBestTripForRequest:(TripRequest *)request
                        success:(TKRouterSuccess)success
                        failure:(TKRouterError)failure;

- (void)downloadTrip:(NSURL *)url
  intoTripKitContext:(NSManagedObjectContext *)tripKitContext
          completion:(TKTripDownloadBlock)completion;

- (void)updateTrip:(Trip *)trip
        completion:(TKTripDownloadBlock)completion;


@end

NS_ASSUME_NONNULL_END
