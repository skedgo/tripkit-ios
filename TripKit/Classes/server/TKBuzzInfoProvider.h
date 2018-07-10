//
//  BHBuzzInfoProvider.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 29/11/12.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TKDLSTable, TKRegion, Service, StopLocation;

typedef void (^TKServiceCompletionBlock)(Service *service, BOOL success);

enum TKInfoProviderError {
  kTKInfoProviderErrorNothingFound    = 1,
  kTKInfoProviderErrorStopWithoutCode = 2
};

@interface TKBuzzInfoProvider : NSObject

- (void)downloadContentOfService:(Service *)service
							forEmbarkationDate:(NSDate *)date
												inRegion:(nullable TKRegion *)regionOrNil
											completion:(TKServiceCompletionBlock)completion;

- (void)addContentToService:(Service *)service
               fromResponse:(NSDictionary *)responseDict;

@end

NS_ASSUME_NONNULL_END
