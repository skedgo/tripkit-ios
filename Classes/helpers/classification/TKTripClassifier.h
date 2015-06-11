//
//  TKTripClassifier.h
//  TripGo
//
//  Created by Adrian Schoenig on 11/06/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 A trip classifier is used to classify TripGroup instances within the same TripRequest.
 */
@protocol TKTripClassifier <NSObject>

/**
 @param The set of trip groups to classify.
 @return A dictionary of TripGroup to id<NSCoding> where the latter is your classification.
 */
- (NSDictionary *)bulkClassifyTripGroups:(NSSet *)tripGroups;

@end
