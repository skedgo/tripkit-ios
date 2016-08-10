//
//  PlainCell.m
//  TripGo
//
//  Created by Adrian Schoenig on 29/10/2014.
//
//

#import "TKPlainCell.h"

@implementation TKPlainCell

- (void)addLocation:(STKModeCoordinate *)location
{
  NSMutableArray *mutableLocations;
  if ([self.locations isKindOfClass:[NSMutableArray class]]) {
    mutableLocations = (NSMutableArray *)self.locations;
  } if (self.locations) {
    mutableLocations = [self.locations mutableCopy];
  } else {
    mutableLocations = [NSMutableArray arrayWithCapacity:100];
  }
  [mutableLocations addObject:location];
  self.locations = mutableLocations;
}

- (void)deleteAllLocations
{
  self.locations = nil;
}

@end
