//
//  BHBuzzRouter.h
//  TripGo
//
//  Created by Adrian Schönig on 2/03/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import "TKRouter.h"

@class Trip;

typedef void (^TKTripDownloadBlock)(Trip *trip);

@interface TKBuzzRouter : TKRouter

- (void)multiFetchTripsForRequest:(TripRequest *)request
                       completion:(void (^)(TripRequest *, NSError *))completion;

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
