//
//  TripFactory.m
//  TripKit
//
//  Created by Adrian Schoenig on 29/01/2014.
//
//

#import "TKTripFactory.h"

#import <TripKit/TKTripKit.h>

@implementation TKTripFactory

+ (Trip *)existingTripUsingDLSEntry:(DLSEntry *)dlsEntry
                         forSegment:(TKSegment *)prototype
{
  // first we find best matches (and an exact one)
  NSInteger publicTransportCount = 0;
  TripGroup *group = prototype.trip.tripGroup;
  for (Trip *trip in group.trips) {
    for (TKSegment *segment in trip.segments) {
      if (! [segment isPublicTransport])
        continue;
      
      publicTransportCount++;
      if (segment.service == dlsEntry.service) {
        ZAssert(dlsEntry.stop.stopCode    == segment.scheduledStartStopCode, @"DLS mismatch at start.");
        ZAssert(dlsEntry.endStop.stopCode == segment.scheduledEndStopCode,   @"DLS mismatch at end.");
        return trip; // exact match
      }
      
      if (publicTransportCount > 1) {
        return nil;
      }
    }
  }

  return nil; // we used to guess, but we just return exact matches now.}
}

@end
