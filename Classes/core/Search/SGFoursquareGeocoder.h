//
//  SGFoursquareGeocoder.h
//  TripKit
//
//  Created by Adrian Schoenig on 26/05/2014.
//
//

#import "SGBaseGeocoder.h"

#import "SGAutocompletionDataProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface SGFoursquareGeocoder : SGBaseGeocoder <SGAutocompletionDataProvider>

- (instancetype)initWithClientID:(NSString *)clientID
                    clientSecret:(NSString *)clientSecret;

@end

NS_ASSUME_NONNULL_END
