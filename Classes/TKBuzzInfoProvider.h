//
//  BHBuzzInfoProvider.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 29/11/12.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TKDLSTable, SVKRegion, Service, StopLocation;

typedef void (^SGServiceCompletionBlock)(Service *service, BOOL success);
typedef void (^SGDeparturesStopSuccessBlock)(BOOL addedChildren);
typedef void (^SGDeparturesDLSSuccessBlock)(NSSet *pairIdentifiers);

enum SGInfoProviderError {
  kSGInfoProviderErrorNothingFound    = 1,
  kSGInfoProviderErrorStopWithoutCode = 2
};

@interface TKBuzzInfoProvider : NSObject

+ (NSDictionary *)queryParametersForDLSTable:(TKDLSTable *)table
                                    fromDate:(NSDate *)date
                                       limit:(NSInteger)limit;


- (void)downloadDeparturesForStop:(StopLocation *)stop
												 fromDate:(NSDate *)date
														limit:(NSInteger)limit
											 completion:(SGDeparturesStopSuccessBlock)completion
													failure:(void(^ __nullable)(NSError * __nullable error))failure;

- (void)downloadDeparturesForDLSTable:(TKDLSTable *)table
                             fromDate:(NSDate *)date
                                limit:(NSInteger)limit
                           completion:(SGDeparturesDLSSuccessBlock)completion
                              failure:(void(^ __nullable)(NSError * __nullable error))failure;

- (void)downloadContentOfService:(Service *)service
							forEmbarkationDate:(NSDate *)date
												inRegion:(nullable SVKRegion *)regionOrNil
											completion:(SGServiceCompletionBlock)completion;

+ (void)fillInStop:(StopLocation *)stop
        completion:(void (^)(NSError * __nullable error))completion;

- (void)addContentToService:(Service *)service
               fromResponse:(NSDictionary *)responseDict;

@end

NS_ASSUME_NONNULL_END
