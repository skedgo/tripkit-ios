//
//  SGSkedgoifier.h
//  TripGo
//
//  Created by Adrian Schoenig on 31/07/13.
//
//

@import CoreData;
@import SkedGoKit;

@interface TKSkedgoifier : NSObject

+ (nullable NSDictionary *)skedgoifyJSONObjectForDate:(nonnull NSDate *)date;

- (void)fetchTripsForItems:(nonnull NSArray *)items
                 startDate:(nonnull NSDate *)startDate
                   endDate:(nonnull NSDate *)endDate
                  inRegion:(nonnull SVKRegion *)region
       withPrivateVehicles:(nullable NSArray <id<STKVehicular>> *)privateVehicles
          withTripPatterns:(nullable NSArray *)tripPatterns
                completion:(nullable void(^)(NSArray * __nullable updatedItems, NSError * __nullable error))completion;

- (nullable id)lastInputJSON;

@end
