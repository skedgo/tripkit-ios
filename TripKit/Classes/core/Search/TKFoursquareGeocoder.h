//
//  TKFoursquareGeocoder.h
//  TripKit
//
//  Created by Adrian Schoenig on 26/05/2014.
//
//

#import "TKBaseGeocoder.h"

#import "SGAutocompletionDataProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface TKFoursquareGeocoder : TKBaseGeocoder <SGAutocompletionDataProvider>

- (instancetype)initWithClientID:(NSString *)clientID
                    clientSecret:(NSString *)clientSecret;

@end

NS_ASSUME_NONNULL_END
