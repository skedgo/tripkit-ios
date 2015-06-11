//
//  TripRequest+Classify.m
//  TripGo
//
//  Created by Adrian Schoenig on 11/06/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "TripRequest+Classify.h"

#import "TKTripKit.h"

@implementation TripRequest (Classify)

- (void)updateTripGroupClassificationsUsingClassifier:(nonnull id<TKTripClassifier>)classifier
{
  NSSet *tripGroups = [self tripGroups];
  NSDictionary *classifications = [classifier bulkClassifyTripGroups:tripGroups];
  for (TripGroup *group in tripGroups) {
    id rawClassification = classifications[group];
    group.classification = [rawClassification conformsToProtocol:@protocol(NSCoding)] ? rawClassification : nil;
  }
}

@end
