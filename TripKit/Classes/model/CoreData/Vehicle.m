//
//  Vehicle.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 1/11/12.
//
//

#import "Vehicle.h"

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


- (void)remove
{
  self.toDelete = YES;
}

@end
