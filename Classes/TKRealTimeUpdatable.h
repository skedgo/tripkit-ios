//
//  SGRealTimeUpdatable.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 13/12/12.
//
//

#import <Foundation/Foundation.h>

@class SVKRegion;

@protocol TKRealTimeUpdatable <NSObject>

// return true if the particular objects should be updated at all
- (BOOL)wantsRealTimeUpdates;

/**
 @return The object that should be updated. Needs to be something that our real-time updater can understand, e.g., a Trip, a Service, a DLS entry, a StopVisit.
 */
- (id)objectForRealTimeUpdates;

- (SVKRegion *)regionForRealTimeUpdates;


@end
