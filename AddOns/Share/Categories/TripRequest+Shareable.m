//
//  TripRequest+Shareable.m
//  Pods
//
//  Created by Adrian Schoenig on 24/06/2016.
//
//

#import "TripRequest+Shareable.h"

#import "TKShareHelper.h"

@implementation TripRequest (Shareable)

- (NSURL *)shareURL
{
  return [TKShareHelper queryURLForStart:[self.fromLocation coordinate]
                                     end:[self.toLocation coordinate]
                                timeType:self.type
                                    time:self.time];
}


@end
