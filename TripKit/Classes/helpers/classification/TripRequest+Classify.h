//
//  TripRequest+Classify.h
//  TripKit
//
//  Created by Adrian Schoenig on 11/06/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "TripRequest.h"

@protocol TKTripClassifier;

@interface TripRequest (Classify)

- (void)updateTripGroupClassificationsUsingClassifier:(nonnull id<TKTripClassifier>)classifier;

@end
