//
//  AdHocShape.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 21/03/13.
//
//

@import Foundation;
@import MapKit;

#import "SGKCrossPlatform.h"

@protocol STKDisplayableRoute;

@interface TKColoredRoute : NSObject <STKDisplayableRoute>

- (id)initWithWaypoints:(NSArray<id<MKAnnotation>> *)waypoints
							withColor:(SGKColor *)color
						dashPattern:(NSArray<NSNumber *> *)dashPattern
            isTravelled:(BOOL)isTravelled;

- (id)initWithWaypoints:(NSArray<id<MKAnnotation>> *)waypoints
									 from:(NSInteger)start
										 to:(NSInteger)end
							withColor:(SGKColor *)color
            dashPattern:(NSArray<NSNumber *> *)dashPattern
            isTravelled:(BOOL)isTravelled;

@end
