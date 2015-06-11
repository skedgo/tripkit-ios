//
//  AdHocShape.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 21/03/13.
//
//

#import "TKColoredRoute.h"

@interface TKColoredRoute ()

@property (nonatomic, strong) NSArray *routePath;
@property (nonatomic, strong) UIColor *routeColour;
@property (nonatomic, strong) NSArray *routeDashPattern;
@property (nonatomic, assign) BOOL routeIsTravelled;

@end

@implementation TKColoredRoute

- (id)initWithWaypoints:(NSArray *)waypoints
							withColor:(UIColor *)color
						dashPattern:(NSArray *)dashPattern
            isTravelled:(BOOL)isTravelled
{
	self = [super init];
	if (self) {
		self.routePath = waypoints;
		self.routeColour = color;
		self.routeDashPattern = dashPattern;
    self.routeIsTravelled = isTravelled;
	}
	return self;
}

- (id)initWithWaypoints:(NSArray *)waypoints
									 from:(NSInteger)start
										 to:(NSInteger)end
							withColor:(UIColor *)color
						dashPattern:(NSArray *)dashPattern
            isTravelled:(BOOL)isTravelled
{
  NSInteger last = end > 0 ? end : waypoints.count;
  NSRange range = NSMakeRange(start, last - start);
  NSArray *selectedWaypoints = [waypoints subarrayWithRange:range];

  return [self initWithWaypoints:selectedWaypoints
                       withColor:color
                     dashPattern:dashPattern
                     isTravelled:isTravelled];
}

@end
