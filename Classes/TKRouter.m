//
//  BHRouter.m
//  TripGo
//
//  Created by Adrian Schönig on 9/02/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import "TKRouter.h"

#import "TKTripKit.h"

@implementation TKRouter

- (void)fetchTripsForCurrentRequestSuccess:(TKRouterSuccess)success
                                   failure:(TKRouterError)failure
{
#pragma unused(success, failure)

  // Objective C has no support for abstract methods, so we're raising an exception instead
  NSException *ex = [NSException exceptionWithName:@"Abstract Method Not Overridden"
                                            reason:@"You MUST override this method"
                                          userInfo:nil];
  [ex raise];
}

- (void)cancelRequests 
{
  // Objective C has no support for abstract methods, so we're raising an exception instead
  NSException *ex = [NSException exceptionWithName:@"Abstract Method Not Overridden"
                                            reason:@"You MUST override this method"
                                          userInfo:nil];
  [ex raise];
}

- (void)fetchTripsForRequest:(TripRequest *)request
										 success:(TKRouterSuccess)success
										 failure:(TKRouterError)failure
{
  ZAssert(success && failure, @"Success and failure blocks are required");
  
  if ([request isDeleted]) {
    NSError *error = [NSError errorWithCode:kSVKErrorTypeInternal
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

@end
