//
//  TKReporter.h
//  TripGo
//
//  Created by Adrian Schoenig on 8/07/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

@import CoreLocation;

@class Trip;

NS_ASSUME_NONNULL_BEGIN

@interface TKReporter : NSObject

/**
 Reports the provided trip as being planned for the user. This is posted to the server with additional optional data. Example use case: Report a trip as being planned, and then later get push notifications about alerts relevant to the trip, or about ride sharing opportunities.
 
 @note This only does anything if the trip has a `plannedURLString`.
 @note The actual call will be delayed to allow frequently calling this method. Completion handler will only be called for the trip that has actually been reported.
 
 @param trip Trip to report as planned
 @param userInfo Optional dictionary of arbitrary data which gets POST'ed as JSON
 @param completionHandler Called when a trip was posted indicating whether it succeeded or not. Called on an arbitrary thread.
 */
+ (void)reportPlannedTrip:(Trip *)trip
                 userInfo:(nullable NSDictionary<NSString *,id<NSCoding>> *)userInfo
        completionHandler:(nullable void(^)(BOOL success))completionHandler;

/**
Reports progress that the user made along the provided trip.

@note This only does anything if the trip has a `progressURLString`.

@param trip Trip for which to report progress
@param locations Array of `CLLocation` objects indiciating the user's progress
 */
+ (void)reportProgressForTrip:(Trip *)trip
                    locations:(NSArray <CLLocation *> *)locations;

@end

NS_ASSUME_NONNULL_END
