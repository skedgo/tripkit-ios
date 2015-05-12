//
//  BHBuzzRealTime.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 2/11/12.
//
//

#import <Foundation/Foundation.h>

@class SVKRegion, Trip;

@interface TKBuzzRealTime : NSObject

- (void)cancelRequests;

- (void)updateTrip:(Trip *)trip
					 success:(void (^)(Trip *trip))success
					 failure:(void (^)(NSError *error))failure;

- (void)updateDLSEntries:(NSSet *)services
                inRegion:(SVKRegion *)region
                 success:(void (^)(NSSet *entries))success
                 failure:(void (^)(NSError *error))failure;

- (void)updateEmbarkations:(NSSet *)services
                  inRegion:(SVKRegion *)region
                   success:(void (^)(NSSet *embarkations))success
                   failure:(void (^)(NSError *error))failure;

- (void)updateServices:(NSSet *)services
              inRegion:(SVKRegion *)region
               success:(void (^)(NSSet *services))success
               failure:(void (^)(NSError *error))failure;

@end
