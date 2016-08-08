//
//  StopLocation+Shareable.m
//  Pods
//
//  Created by Adrian Schoenig on 24/06/2016.
//
//

#import "StopLocation+Shareable.h"

#import "TKShareHelper.h"

@implementation StopLocation (Shareable)

- (NSURL *)shareURL
{
  return [TKShareHelper stopURLForStopCode:self.stopCode
                             inRegionNamed:self.region.name
                                    filter:self.filter];
}

@end
