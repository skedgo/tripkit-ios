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

/**
 A TKRouter calculates trips for routing requests.
 
 @note TKRouter itself is an abstract class. Most likely you will want to create an instance of TKBuzzRouter to talk to the SkedGo backend.
 
 @note Subclasses need to implement `-fetchTripsForCurrentRequestSuccess:failure` and `-cancelRequests`.
 */
@interface TKRouter : NSObject

@property (nonatomic, strong) TripRequest *currentRequest;
@property (nonatomic, copy) NSSet *modeIdentifiers;

/**
 The main method to call to have the router calculate trips.
 
 @param request An instance of a `TripRequest` which specifies what kind of trips should get calculated.
 @param minimized 
 */
- (void)fetchTripsForRequest:(TripRequest *)request
										 success:(TKRouterSuccess)success
										 failure:(TKRouterError)failure;

#pragma mark - For subclasses to overwrite

- (void)cancelRequests;

/**
 @note Abstract method called by the superclass. Only for subclasses to overwrite. Do not call this directly.
 */
- (void)fetchTripsForCurrentRequestSuccess:(TKRouterSuccess)success
                                   failure:(TKRouterError)failure;

@end
