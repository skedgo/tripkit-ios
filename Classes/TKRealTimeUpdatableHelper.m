//
//  SGRealTimeUpdatableHelper.m
//  TripGo
//
//  Created by Adrian Schoenig on 16/01/2015.
//
//

#import "TKRealTimeUpdatableHelper.h"

@implementation TKRealTimeUpdatableHelper

+ (BOOL)wantsRealTimeUpdatesForStart:(NSDate *)start
                              andEnd:(NSDate *)end
                      forPreplanning:(BOOL)forPreplanning
{
  if (forPreplanning) {
    return ([start timeIntervalSinceNow]  <  12 * 60 * 60 // half a day in advance
            && [end timeIntervalSinceNow] > -60 * 60);    // 1 hour ago
    
  } else {
    return ([start timeIntervalSinceNow]  <  45 * 60    // start isn't more than 45 minutes from now
            && [end timeIntervalSinceNow] > -30 * 60); // end isn't more than 30 minutes ago
  }
}


@end
