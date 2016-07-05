//
//  PlainCell.m
//  TripGo
//
//  Created by Adrian Schoenig on 29/10/2014.
//
//

#import "TKPlainCell.h"

@implementation TKPlainCell

- (void)addStop:(STKStopCoordinate *)stop
{
  NSMutableArray *mutableStops;
  if ([self.stops isKindOfClass:[NSMutableArray class]]) {
    mutableStops = (NSMutableArray *)self.stops;
  } if (self.stops) {
    mutableStops = [self.stops mutableCopy];
  } else {
    mutableStops = [NSMutableArray arrayWithCapacity:100];
  }
  [mutableStops addObject:stop];
  self.stops = mutableStops;
}

- (void)deleteAllStops
{
  self.stops = nil;
}

@end
