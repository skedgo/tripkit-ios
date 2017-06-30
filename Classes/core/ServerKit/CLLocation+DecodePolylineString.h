//
//  CLLocation+DecodePolylineString.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 2/05/13.
//
//

#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLLocation (DecodePolylineString)

+ (NSArray<CLLocation *> *)decodePolyLine:(NSString *)encodedStr;

@end

NS_ASSUME_NONNULL_END
