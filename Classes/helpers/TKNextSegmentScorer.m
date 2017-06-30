//
//  TKNextSegmentScorer.m
//  TripGo
//
//  Created by Adrian Schoenig on 5/05/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "TKNextSegmentScorer.h"

#ifdef TK_NO_FRAMEWORKS
#import "TripKit.h"
#endif

#import "TripKit/TripKit-Swift.h"

@implementation Trip (NextSegment)

- (TKSegment *)nextSegmentAtTime:(NSDate *)time
                     forLocation:(CLLocation *)location
{
  id<STKTripSegment> bestSegment = [TKNextSegmentScorer nextSegmentOfTrip:self
                                                                  forTime:time
                                                             withLocation:location];
  if (bestSegment) {
    ZAssert([bestSegment isKindOfClass:[TKSegment class]], @"Trips shouldn't only have TKSegment objects in them!");
    TKSegment *segment = (TKSegment *)bestSegment;
    [SGKLog debug:@"NextSegmentScorer" block:^{
      return [NSString stringWithFormat:@"Best: %@", segment.title];
    }];
    return segment;
  } else {
    [SGKLog debug:@"NextSegmentScorer" block:^{
      return [NSString stringWithFormat:@"Missing best segment for Trip: %@", [self debugString]];
    }];
    return nil;
  }
}

@end

@implementation TKSegment (NextSegmentScore)

- (NSUInteger)scoreAtTime:(NSDate *)time
              forLocation:(nullable CLLocation *)location
{
  return [TKNextSegmentScorer scoreForSegment:self
                                       atTime:time
                                  forLocation:location];
}


@end

@implementation TKNextSegmentScorer

+ (id<STKTripSegment>)nextSegmentOfTrip:(id<STKTrip>)trip
                                forTime:(NSDate *)time
                           withLocation:(CLLocation *)location
{
  if ([time timeIntervalSinceDate:[trip arrivalTime]] > 0) {
    return nil;
  }
  
  id<STKTripSegment> bestSegment = nil;
  NSUInteger bestScore = 0;
  
  for (id<STKTripSegment> segment in [trip segmentsWithVisibility:STKTripSegmentVisibilityInDetails]) {
    NSUInteger score = [self scoreForSegment:segment
                                      atTime:time
                                 forLocation:location];
    if (score >= bestScore) { // we prefer later
      bestScore = score;
      bestSegment = segment;
    }
  }
  
  if (bestScore > 0) {
    return bestSegment;
  } else {
    return nil;
  }
}

+ (NSUInteger)scoreForSegment:(id<STKTripSegment>)segment
                       atTime:(NSDate *)time
                  forLocation:(nullable CLLocation *)location
{
  if ([segment isKindOfClass:[TKSegment class]]) {
    TKSegment *tripKitSegment = (TKSegment *)segment;
    NSUInteger score = [self scoreForTripKitSegment:tripKitSegment
                                             atTime:time
                                        forLocation:location];
    
    [SGKLog debug:@"NextSegmentScorer" block:^{
      return [NSString stringWithFormat:@"%@, S: %ld", tripKitSegment.title, (unsigned long)score];
    }];
    return score;
  } else {
    return [self scoreForBasicSegment:segment
                               atTime:time
                          forLocation:location];
  }
}

#pragma mark - Helper: Wrapper around our classes

+ (NSUInteger)scoreForTripKitSegment:(TKSegment *)segment
                              atTime:(NSDate *)time
                         forLocation:(nullable CLLocation *)location
{
  id<MKAnnotation> start;
  float locationWeight;
  CLLocationDistance zeroScoreDistance;
  NSDate *startTime;
  NSDate *endTime;

  id<MKAnnotation> end = nil;
  id<NSFastEnumeration> shapes = nil;
  
  if ([segment isStationary]) {
    locationWeight = 0.85f;
    zeroScoreDistance = 250;
    
    start = [segment start];
    startTime = [segment departureTime];
    endTime = [segment arrivalTime];
  
  } else if (location && [segment isPublicTransport] && [segment.service hasServiceData]) {
    NSTimeInterval allowedOffset = [segment.service isRealTime] ? 1 * 60 : 3 * 60;
    
    // TODO: this needs testing; it seems like these times can be out of whack
    //       which then sets a 0 score on the segments.
    
    NSArray *visits = [segment.service sortedVisits];
    StopVisits *lastStopBeforeOffset = [visits firstObject];
    StopVisits *firstStopAfterOffset = [visits lastObject];
    for (StopVisits *visit in visits) {
      if ([time timeIntervalSinceDate:visit.time] > allowedOffset) {
        // the visit is sufficiently before 'time'
        lastStopBeforeOffset = visit;
      }
      if ([visit.time timeIntervalSinceDate:time] > allowedOffset) {
        // found the first sufficiently one after 'time'
        firstStopAfterOffset = visit;
        break; // this also means we are done!
      }
    }
    
    locationWeight = 0.75f;
    zeroScoreDistance = 250;
    start = lastStopBeforeOffset;
    end = firstStopAfterOffset;
    startTime = [lastStopBeforeOffset time];
    endTime = [firstStopAfterOffset time];
    shapes = [segment.service shapesForEmbarkation:lastStopBeforeOffset
                                    disembarkingAt:firstStopAfterOffset];
  
  } else {
    locationWeight = 0.75;
    zeroScoreDistance = 500;
    start = [segment start];
    end = [segment end];
    startTime = [segment departureTime];
    endTime = [segment arrivalTime];
    shapes = [segment shapes];
  }
  
  NSDate *deadline = [self nextDeadlineOfSegment:segment];
  NSUInteger timeScore = [self basicScoreBetweenStartTime:startTime
                                                  endTime:endTime
                                                 deadline:deadline
                                             segmentOrder:segment.order
                                                  forTime:time];
  
  NSUInteger locationScore = [self basicScoreBetweenStart:start
                                                      end:end
                                              usingShapes:shapes
                                         zeroScoreDistnce:zeroScoreDistance
                                              forLocation:location];
  
  if (location && locationScore > 0 && timeScore > 0) {
    float timeWeight = 1.0f - locationWeight;
    return (NSUInteger) (locationScore * locationWeight + timeScore * timeWeight);
    
  } else if (!location) {
    return timeScore;
    
  } else {
    return 0;
  }
}

+ (NSUInteger)scoreForBasicSegment:(id<STKTripSegment>)segment
                            atTime:(NSDate *)time
                       forLocation:(nullable CLLocation *)location
{
#pragma unused(segment, time, location)
  // We don't use generic STKTripSegments currently, but once we do
  // this is where to add a score.
  return 0;
}

#pragma mark - Helper: Advanced segment properties

+ (NSDate *)nextDeadlineOfSegment:(TKSegment *)segment
{
  for (TKSegment *aSegment = segment.next; aSegment != nil; aSegment = aSegment.next) {
    if ([aSegment isPublicTransport]
        && ![aSegment isContinuation]
        && ![aSegment.service isFrequencyBased]) {
      return [aSegment departureTime];
    }
  }
  return nil;
}

#pragma mark - Helper: Scoring

+ (NSUInteger)basicScoreBetweenStart:(id<MKAnnotation>)startAnnotation
                                 end:(nullable id<MKAnnotation>)endAnnotation
                         usingShapes:(nullable id<NSFastEnumeration>)shapes
                    zeroScoreDistnce:(CLLocationDistance)zeroScoreDistance
                         forLocation:(nullable CLLocation *)location
{
  if (!location) {
    return 0;
  }
  
  CLLocationCoordinate2D startCoordinate = [startAnnotation coordinate];
  CLLocation *start = [[CLLocation alloc] initWithLatitude:startCoordinate.latitude
                                                 longitude:startCoordinate.longitude];
  CLLocationDistance distanceFromStart = [location distanceFromLocation:start];
  
  CLLocationDistance distance;
  NSUInteger max;
  
  if (!endAnnotation || !shapes) {
    max = 100;
    distance = distanceFromStart;
    
  } else {
    CLLocationCoordinate2D endCoordinate = [endAnnotation coordinate];
    CLLocation *end = [[CLLocation alloc] initWithLatitude:endCoordinate.latitude
                                                 longitude:endCoordinate.longitude];
    
    CLLocationDistance totalDistance = [end distanceFromLocation:start];
    zeroScoreDistance = MIN(zeroScoreDistance, totalDistance);
    
    CLLocationDistance distanceFromEnd = [location distanceFromLocation:end];
    distance = MIN(distanceFromStart, distanceFromEnd);
    
    // We want to provide a lower score the closer we are to the end as preference should be for the following segments.
    CLLocationDistance closeToEndDistance = 250;
    NSUInteger maxMax = 75;
    NSUInteger lowMaxAtEnd = 25;
    CLLocationDistance outsideEndAccuracy = MAX(0, distanceFromEnd - location.horizontalAccuracy);
    if (outsideEndAccuracy >= closeToEndDistance) {
      max = maxMax; // even at best, we gotta be less than stationaries, as stationaries are more relevant than how we got there or are getting away from there.
    } else {
      double proportion = outsideEndAccuracy / closeToEndDistance;
      max = lowMaxAtEnd + (NSUInteger) (proportion * (maxMax - lowMaxAtEnd));
    }
    
    for (id<STKDisplayableRoute> route in shapes) {
      if ([route respondsToSelector:@selector(routeIsTravelled)]
          && ! [route routeIsTravelled]) {
        continue;
      }
      
      for (id object in [route routePath]) {
        CLLocation *waypoint;
        if ([object isKindOfClass:[CLLocation class]]) {
          waypoint = object;
        } else if ([object respondsToSelector:@selector(coordinate)]) {
          CLLocationCoordinate2D coordinate = [object coordinate];
          waypoint = [[CLLocation alloc] initWithLatitude:coordinate.latitude
                                                longitude:coordinate.longitude];
        } else {
          ZAssert(false, @"waypoint has no coordinate!");
          continue;
        }
        CLLocationDistance distanceFromWaypoint = [location distanceFromLocation:waypoint];
        distance = MIN(distance, distanceFromWaypoint);
        if (distance - location.horizontalAccuracy <= zeroScoreDistance) {
          break;
        }
      }
      if (distance - location.horizontalAccuracy <= zeroScoreDistance) {
        break;
      }
    }
  }
  
  // it's relevant if we are between location's horizontal accuracy + X meters, with highest score of being within horizontal accuracy, and lowest at the X meters margin.
  CLLocationDistance outsideAccuracy = MAX(0, distance - location.horizontalAccuracy);
  if (outsideAccuracy >= zeroScoreDistance) {
    return 0;
  } else {
    double match = outsideAccuracy / zeroScoreDistance;
    double proportion = 1.0 - match;
    return (NSUInteger) (proportion * max);
  }
}

+ (NSUInteger)basicScoreBetweenStartTime:(NSDate *)startTime
                                 endTime:(NSDate *)endTime
                                deadline:(NSDate *)deadline
                            segmentOrder:(TKSegmentOrdering)order
                                 forTime:(NSDate *)time
{
  // for the time, we prefer being in the middle of the segment, but leaving early (up to tens mins) and leaving late (up to 5 mins) is fine.
  if ([time isInBetweenStartDate:startTime andEnd:endTime]) {
    return 100;
  } else {
    NSTimeInterval minScoreOffset;
    NSTimeInterval offset;
    NSUInteger minScore;
    
    NSTimeInterval timeToStart = [startTime timeIntervalSinceDate:time];
    NSTimeInterval timeSinceEnd = [time timeIntervalSinceDate:endTime];
    if (timeToStart > 0) {
      // segment didn't start yet
      offset = timeToStart;
      minScore = (order == TKSegmentOrderingStart) ? 10 : 0;
      minScoreOffset = 10 * 60;
    } else {
      // segment is over
      if (deadline && [time timeIntervalSinceDate:deadline] > 60) {
        return 0;
      }
      
      ZAssert(timeSinceEnd > 0, @"Shouldn't end up in the middle!");
      offset = timeSinceEnd;
      minScore = 0;
      minScoreOffset = (order == TKSegmentOrderingEnd ? 1 : 5) * 60;
      minScoreOffset = MIN(minScoreOffset, [endTime timeIntervalSinceDate:startTime]);
    }
    
    if (offset >= minScoreOffset) {
      return minScore;
    } else {
      double match = offset / minScoreOffset;
      double proportion = 1.0 - match;
      NSUInteger max = (order == TKSegmentOrderingStart) ? 50 : 100;
      return minScore + (NSUInteger) (proportion * (max - minScore));
    }
  }
}

@end
