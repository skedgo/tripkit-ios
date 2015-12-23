//
//  TKReporter.m
//  TripGo
//
//  Created by Adrian Schoenig on 8/07/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "TKReporter.h"

#import "TKTripKit.h"

@implementation TKReporter

+ (void)reportPlannedTrip:(Trip *)trip
                 userInfo:(NSDictionary *)userInfo
{
  NSParameterAssert(trip);
  if (!trip.plannedURLString) {
    return;
  }
  
  [SVKServer POST:[NSURL URLWithString:trip.plannedURLString]
            paras:userInfo
       completion:
   ^(id  _Nullable responseObject, NSError * _Nullable error) {
     if (responseObject) {
       [SGKLog debug:@"TKReporter" text:@"Planned trip posted successfully"];
     } else {
       [SGKLog debug:@"TKReporter" block:^NSString * _Nonnull{
         return [NSString stringWithFormat:@"Planned trip post encountered error: %@", error];
       }];
     }
   }];
}

+ (void)reportProgressForTrip:(Trip *)trip
                    locations:(NSArray *)locations
{
  NSParameterAssert(trip);
  NSParameterAssert(locations);
  if (!trip.progressURLString) {
    return;
  }
  
  NSMutableArray *samples = [NSMutableArray arrayWithCapacity:locations.count];
  for (id object in locations) {
    if ([object isKindOfClass:[CLLocation class]]) {
      CLLocation *location = object;
      NSMutableDictionary *sample = [NSMutableDictionary dictionaryWithCapacity:5];
      sample[@"timestamp"] = @([location.timestamp timeIntervalSince1970]);
      sample[@"latitude"] = @(location.coordinate.latitude);
      sample[@"longitude"] = @(location.coordinate.longitude);
      if (location.speed >= 0) {
        sample[@"speed"] = @(location.speed);
      }
      if (location.course >= 0) {
        sample[@"bearing"] = @(location.course);
      }
      [samples addObject:sample];
    }
  }
  
  NSDictionary *paras = @{@"samples": samples};
  
  [SVKServer POST:[NSURL URLWithString:trip.progressURLString]
            paras:paras
       completion:
   ^(id  _Nullable responseObject, NSError * _Nullable error) {
     if (responseObject) {
       [SGKLog debug:@"TKReporter" text:@"Progress posted successfully"];
     } else {
       [SGKLog debug:@"TKReporter" block:^NSString * _Nonnull{
         return [NSString stringWithFormat:@"Progress post encountered error: %@", error];
       }];
     }
   }];
}

@end
