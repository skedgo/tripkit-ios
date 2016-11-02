//
//  TKSegment+Shareable.m
//  Pods
//
//  Created by Adrian Schoenig on 24/06/2016.
//
//

#import "TKSegment+Shareable.h"

#import "TKShareHelper.h"

@implementation TKSegment (Shareable)

- (NSURL *)shareURL
{
  BOOL isEnd = (self.order == TKSegmentOrderingEnd);
  CLLocationCoordinate2D coordinate = isEnd ? [self.end coordinate] : [self.start coordinate];
  NSDate *time = isEnd ? self.arrivalTime : self.departureTime;
  return [TKShareHelper meetURLForCoordinate:coordinate atTime:time];
}

@end
