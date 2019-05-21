//
//  TKFoursquareGeocoder.h
//  TripKit
//
//  Created by Adrian Schoenig on 26/05/2014.
//
//

#import "SGDeprecatedAutocompletionDataProvider.h"

#import "SGDeprecatedGeocoder.h"

NS_ASSUME_NONNULL_BEGIN

@interface TKFoursquareGeocoder : NSObject <SGDeprecatedAutocompletionDataProvider, SGDeprecatedGeocoder>

- (instancetype)initWithClientID:(NSString *)clientID
                    clientSecret:(NSString *)clientSecret;

@end

NS_ASSUME_NONNULL_END
