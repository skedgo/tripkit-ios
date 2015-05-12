//
//  BHBuzzRouter.h
//  TripGo
//
//  Created by Adrian Schönig on 2/03/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import "TKRouter.h"

@class Trip;

typedef void (^SGTripDownloadBlock)(Trip *trip);

@interface TKBuzzRouter : TKRouter

- (NSDictionary *)createRequestParametersForRequest:(TripRequest *)request
                                 andModeIdentifiers:(NSSet *)modeIdentifiers
                                           bestOnly:(BOOL)bestOnly;

- (void)fetchBestTripForRequest:(TripRequest *)request
                        success:(TKRouterSuccess)success
                        failure:(TKRouterError)failure;

- (void)downloadTrip:(NSURL *)url
          completion:(SGTripDownloadBlock)completion;

- (void)updateTrip:(Trip *)trip
        completion:(SGTripDownloadBlock)completion;


@end
