//
//  DLSTable.m
//  TripGo
//
//  Created by Adrian Schoenig on 27/05/2014.
//
//

#import "TKDLSTable.h"

@implementation TKDLSTable

- (instancetype)initWithStartStopCode:(NSString *)startStopCode
                          endStopCode:(NSString *)endStopCode
                    withPreviousPairs:(NSSet *)previousPairs
                             inRegion:(SVKRegion *)region
                    forTripKitContext:(NSManagedObjectContext *)context
{
  self = [super init];
  if (self) {
    _startStopCode = startStopCode;
    _endStopCode = endStopCode;
    _previousPairs = previousPairs;
    _region = region;
    _tripKitContext = context;
  }
  return self;
}
@end
