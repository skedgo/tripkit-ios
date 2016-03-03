//
//  SGSkedgoifier.h
//  TripGo
//
//  Created by Adrian Schoenig on 31/07/13.
//
//

#import <CoreData/CoreData.h>

@protocol TKAgendaType;
@protocol TKAgendaOutputType;

@interface TKSkedgoifier : NSObject

- (void)fetchTripsForTrack:(nonnull id<TKAgendaType>)track
       withPrivateVehicles:(nullable NSArray <id<STKVehicular>> *)privateVehicles
          withTripPatterns:(nullable NSArray *)tripPatterns
          inTripKitContext:(nonnull NSManagedObjectContext *)tripKitContext
                completion:(nullable void(^)(NSArray<id<TKAgendaOutputType>> * __nullable updatedItems, NSError * __nullable error))completion;

+ (nullable NSDictionary *)skedgoifyJSONObjectForDate:(nonnull NSDate *)date;

- (nullable id)lastInputJSON;

@end
