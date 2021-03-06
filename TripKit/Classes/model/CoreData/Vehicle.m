//
//  Vehicle.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 1/11/12.
//
//

#import "Vehicle.h"

#import "NSManagedObjectContext+SimpleFetch.h"

@implementation Vehicle

@dynamic icon;
@dynamic identifier;
@dynamic latitude;
@dynamic longitude;
@dynamic lastUpdate;
@dynamic bearing;
@dynamic componentsData;
@dynamic label;
@dynamic toDelete;
@dynamic service, serviceAlternatives;
@dynamic segment, segmentAlternatives;

@synthesize displayAsPrimary;

- (void)setSubtitle:(NSString *)title
{
#pragma unused(title) // do nothing, this is just for KVO
}

+ (void)removeOrphansFromManagedObjectContext:(NSManagedObjectContext *)context
{
	NSSet *vehicles = [context fetchObjectsForEntityClass:self
                                    withPredicateString:@"toDelete = NO AND service = nil"];
	for (Vehicle *vehicle in vehicles) {
		DLog(@"Deleting vehicle %@ which has no service.", vehicle);
    [vehicle remove];
	}
}

- (void)remove
{
  self.toDelete = YES;
}

@end
