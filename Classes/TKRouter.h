//
//  BHRouter.h
//  TripGo
//
//  Created by Adrian Schönig on 9/02/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "SVKTransportModes.h"

@class TripRequest, TKTripKit;

typedef void(^TKRouterSuccess)(TripRequest *request, NSSet *modeIdentifiers);
typedef void(^TKRouterError)(NSError *error, NSSet *modeIdentifiers);


@interface TKRouter : NSObject

@property (nonatomic, strong) TripRequest *currentRequest;
@property (nonatomic, copy) NSSet *modeIdentifiers;
@property (nonatomic, strong) TKTripKit *tripKit;

- (void)fetchTripsForRequest:(TripRequest *)request
              minimizedModes:(NSSet *)minimized
                 hiddenModes:(NSSet *)hidden
										 success:(TKRouterSuccess)success
										 failure:(TKRouterError)failure;

#pragma mark - For subclasses to overwrite

- (void)cancelRequests;

- (void)fetchTripsForCurrentRequestSuccess:(TKRouterSuccess)success
                                   failure:(TKRouterError)failure;

@end
