//
//  TripFactory.h
//  TripGo
//
//  Created by Adrian Schoenig on 29/01/2014.
//
//

#import <Foundation/Foundation.h>

@class DLSEntry, TKSegment, Trip;

typedef void(^TripFactoryCompletionBlock)(Trip *trip, NSError *error);

@interface TKTripFactory : NSObject

/**
 @param dlsEntry A DLS entry which will replace the specified prototype segment
 @param prototype The segment that will be replaced with the DLS entry
 
 @return An exact match of what the trip will look like. Can return nil if it fails, especially when there's more than 1 public transport segment.
 */
+ (Trip *)existingTripUsingDLSEntry:(DLSEntry *)dlsEntry
                         forSegment:(TKSegment *)prototype;

@end
