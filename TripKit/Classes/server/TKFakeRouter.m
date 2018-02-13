//
//  BHFakeRouter.m
//  TripKit
//
//  Created by Adrian Schönig on 9/02/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import "TKFakeRouter.h"

#import <TripKit/TKTripKit.h>

@implementation TKFakeRouter

@synthesize parser;

- (void)fakeRouteResultForRequest:(TripRequest *)request
{
  if (nil == self.parser) {
    NSManagedObjectContext *tripKitContext = [[TKTripKit sharedInstance] tripKitContext];
    self.parser = [[TKRoutingParser alloc] initWithTripKitContext:tripKitContext];
  }
  
  NSString *jsonString = @"";

  NSDictionary* json = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];

  [self.parser parseAndAddResult:json forRequest:request merging:NO completion:^(NSArray<Trip *> * _Nonnull addedTrips) {
    // nothing to do
  }];
}

- (void)fakedRequestTime:(NSTimer *)timer 
{
#pragma unused(timer)
  [self fakeRouteResultForRequest:self.currentRequest];
  
//  [self.delegate router:self fetchedTripsForRequest:self.currentRequest withModes:self.modes allCompleted:YES forObject:self.object];
}

- (void)cancelRequests
{
  // do nothing
}

@end
