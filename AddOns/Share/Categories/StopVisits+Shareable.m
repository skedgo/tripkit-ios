//
//  StopVisits+Shareable.m
//  Pods
//
//  Created by Adrian Schoenig on 24/06/2016.
//
//

#import "StopVisits+Shareable.h"

#import "TKShareHelper.h"
#import "StopLocation.h"

@implementation StopVisits (Shareable)

- (NSURL *)shareURL
{
  return [TKShareHelper meetURLForCoordinate:[self.stop coordinate] atTime:self.time];
  
  // Once the web app supports it: https://redmine.buzzhives.com/issues/2200
  //  return [ShareHelper serviceURLForServiceID:self.service.code
  //                                  atStopCode:self.stop.stopCode
  //                               inRegionNamed:self.stop.region.name];
}

@end
