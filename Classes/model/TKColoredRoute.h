//
//  AdHocShape.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 21/03/13.
//
//

#import <Foundation/Foundation.h>

#import "STKRoutePolyline.h"

@interface TKColoredRoute : NSObject <STKDisplayableRoute>

- (id)initWithWaypoints:(NSArray *)waypoints // NSArray <MKAnnotation>
							withColor:(UIColor *)color
						dashPattern:(NSArray *)dashPattern
            isTravelled:(BOOL)isTravelled;

- (id)initWithWaypoints:(NSArray *)waypoints // NSArray <MKAnnotation>
									 from:(NSInteger)start
										 to:(NSInteger)end
							withColor:(UIColor *)color
            dashPattern:(NSArray *)dashPattern
            isTravelled:(BOOL)isTravelled;

@end
