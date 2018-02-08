//
//  PlainCell.m
//  TripKit
//
//  Created by Adrian Schoenig on 29/10/2014.
//
//

#import "TKPlainCell.h"

@interface TKPlainCell ()

@property (nonatomic, strong, nullable) NSNumber *hashCode;
@property (nullable, nonatomic, strong) NSDate *lastUpdate;
@property (nullable, nonatomic, copy) NSArray<STKModeCoordinate *>* locations;
@property (nullable, nonatomic, strong) NSArray<STKModeCoordinate *>* previousLocations;

@end

@implementation TKPlainCell

- (void)updateLocations:(nonnull NSArray<STKModeCoordinate *>*)locations
               hashCode:(nonnull NSNumber *)hashCode
{
  self.lastUpdate = [NSDate date];
  self.previousLocations = self.locations;
  self.locations = locations;
  self.hashCode = hashCode;
}

@end
