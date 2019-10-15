//
//  BHBuzzRealTime.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 2/11/12.
//
//

#import <Foundation/Foundation.h>

@class TKRegion, Trip;
@class DLSEntry, Service, StopVisits;

NS_ASSUME_NONNULL_BEGIN

@interface TKBuzzRealTime : NSObject

- (void)updateTrip:(Trip *)trip
					 success:(void (^)(Trip *trip, BOOL tripUpdated))success
					 failure:(void (^)(NSError * _Nullable error))failure;

+ (void)updateDLSEntries:(NSSet<DLSEntry *> *)entries
                inRegion:(TKRegion *)region
                 success:(void (^)(NSSet<DLSEntry *> *entries))success
                 failure:(void (^)(NSError * _Nullable error))failure;

+ (void)updateEmbarkations:(NSSet<StopVisits *> *)embarkations
                  inRegion:(TKRegion *)region
                   success:(void (^)(NSSet<StopVisits *> *embarkations))success
                   failure:(void (^)(NSError * _Nullable error))failure;

+ (void)updateServices:(NSSet<Service *> *)services
              inRegion:(TKRegion *)region
               success:(void (^)(NSSet<Service *> *services))success
               failure:(void (^)(NSError * _Nullable error))failure;

@end

NS_ASSUME_NONNULL_END
