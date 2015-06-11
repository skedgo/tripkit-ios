//
//  TKTripClassifier.h
//  TripGo
//
//  Created by Adrian Schoenig on 11/06/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TripGroup;

/**
 A trip classifier is used to classify TripGroup instances within the same TripRequest.
 */
@protocol TKTripClassifier <NSObject>

/**
 Called before starting a classifiction of multiple trip groups.
 @param The set of trip groups that will be classified.
 */
- (void)prepareForClassifictionOfTripGroups:(nonnull NSSet *)tripGroups;

/**
 @return The classifiction of that particular trip group.
 */
- (nullable id<NSCoding>)classificationOfTripGroup:(nonnull TripGroup *)tripGroup;

@end
