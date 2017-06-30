//
//  Shape.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 24/11/12.
//
//

#import "Shape.h"

#import <TripKit/TKTripKit.h>

@interface Shape ()

@property (nonatomic, strong) NSArray *sortedWaypoints;

@end

@implementation Shape

@dynamic encodedWaypoints;
@dynamic friendly;
@dynamic index;
@dynamic title;
@dynamic travelled;
@dynamic toDelete;
@dynamic template;
@dynamic services;
@dynamic visits;

@synthesize segment = _segment;
@synthesize sortedWaypoints = _sortedWaypoints;

+ (Shape *)fetchTravelledShapeForTemplate:(SegmentTemplate *)segmentTemplate
                                  atStart:(BOOL)atStart
{
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"toDelete = NO AND template = %@ AND travelled = 1", self];
  NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:atStart];
  NSArray *shapes = [segmentTemplate.managedObjectContext fetchObjectsForEntityClass:self
                                                                       withPredicate:predicate
                                                                  andSortDescriptors:@[sortDescriptor ]
                                                                       andFetchLimit:1];
  if (shapes.count > 0) {
    return shapes[0];
  } else {
    return nil;
  }
}

- (NSArray *)sortedWaypoints
{
	if (!_sortedWaypoints) {
		if (self.encodedWaypoints) {
			_sortedWaypoints = [CLLocation decodePolyLine:self.encodedWaypoints];
		}
	}
	return _sortedWaypoints;
}

- (id<MKAnnotation>)start
{
	if (self.sortedWaypoints.count == 0) {
		ZAssert(false, @"Uh-oh. This shape is empty!");
		return nil;
	}
	
	return [self.sortedWaypoints objectAtIndex:0];
}

- (id<MKAnnotation>)end
{
	if (self.sortedWaypoints.count == 0) {
		ZAssert(false, @"Uh-oh. This shape is empty!");
		return nil;
	}
	
	return [self.sortedWaypoints objectAtIndex:self.sortedWaypoints.count - 1];
}

- (void)dealloc
{
	[self cleanUp];
}

- (void)didTurnIntoFault
{
	[super didTurnIntoFault];
	[self cleanUp];
}

- (void)cleanUp
{
	_segment = nil;
	_sortedWaypoints = nil;
}


#pragma mark - ASDisplayableRoute protocol

- (NSArray *)routePath
{
	return self.sortedWaypoints;
}

- (SGKColor *)routeColour
{
  // Non-travelled always gets a special colour
	if (NO == self.travelled.boolValue) {
    return [SGKTransportStyler routeDashColorNontravelled];
	}
	
  // If we have a service, use that
	Service *service = [self.services anyObject];
	SGKColor *color = service.color;
  if (color) {
    return color;
  }
  
  // Next, we prefer the friendly vs unfriendly colours
  if (self.friendly) {
    return [self.friendly boolValue]
      ? [SGKColor colorWithRed:73/255.f green:220/255.f blue:99/255.f alpha:1]
      : [SGKColor colorWithRed:255/255.f green:231/255.f blue:73/255.f alpha:1];
  }
  
	color = self.segment.color;
  if (color) {
    return color;
  }
  return [SGKColor colorWithRed:143/255.f green:139/255.f blue:138/255.f alpha:1]; // Dark grey
}

- (BOOL)routeIsTravelled
{
  return [self.travelled boolValue];
}

@end
