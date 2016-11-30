//
//  TKWaypointRouter.h
//  TripGo
//
//  Created by Adrian Schoenig on 7/04/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

@class TKSegment, DLSEntry, Trip;

@interface TKWaypointRouter : NSObject

#pragma mark - Trip modifications

- (void)fetchTripReplacingSegment:(TKSegment *)segment
                     withDLSEntry:(DLSEntry *)dlsEntry
             usingPrivateVehicles:(nullable NSArray *)privateVehicles
                       completion:(void(^)(Trip * __nullable trip, NSError * __nullable error))completion;

@end

NS_ASSUME_NONNULL_END
