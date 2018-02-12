//
//  TKNextSegmentScorer.h
//  TripKit
//
//  Created by Adrian Schoenig on 5/05/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "Trip.h"
#import "TKSegment.h"

NS_ASSUME_NONNULL_BEGIN

@protocol STKTrip;

@interface Trip (NextSegment)

- (nullable TKSegment *)nextSegmentAtTime:(NSDate *)time
                              forLocation:(nullable CLLocation *)location;

@end

@interface TKSegment (NextSegmentScore)

/**
 Scores the match of this segment for the provided location and time.
 
 Scoring works as follows:
 - Stationary segments have a high score when the location is matching and are "less fuzzy" (see below) about the time.
 - Public transport segments look at where you should be around this time based on the stops. It matches the current stop-to-stop part along the route (with some minor +/- border around which depends on whether real-time is available or not) and then score based on that.
 - Non public-transport segments score highest if the location is matching the trail and are "less fuzzy" (see below) about the time.
 
 Being "less fuzzy" about the time means: If there's no upcoming deadline, e.g., a service to match, the time has little impact on the score. However, if there is a deadline, then being after that deadline will lead to overall a low score.
 
 @param location Optional current location sample
 @param time Last known time at that location (even if that location is nil)
 @return Score in a range from 0 to 100
 */
- (NSUInteger)scoreAtTime:(NSDate *)time
              forLocation:(nullable CLLocation *)location;

@end

@interface TKNextSegmentScorer : NSObject

+ (nullable id<STKTripSegment>)nextSegmentOfTrip:(id<STKTrip>)trip
                                         forTime:(NSDate *)time
                                    withLocation:(nullable CLLocation *)location;

+ (NSUInteger)scoreForSegment:(id<STKTripSegment>)segment
                       atTime:(NSDate *)time
                  forLocation:(nullable CLLocation *)location;

@end

NS_ASSUME_NONNULL_END
