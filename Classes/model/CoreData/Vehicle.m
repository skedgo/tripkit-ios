//
//  Vehicle.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 1/11/12.
//
//

#import "Vehicle.h"

#import "TKTripKit.h"

@implementation Vehicle

@dynamic identifier;
@dynamic latitude;
@dynamic longitude;
@dynamic lastUpdate;
@dynamic bearing;
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

- (CGFloat)ageFactor
{
  if ([self hasLastUpdate]) {
    NSTimeInterval age = [self.lastUpdate timeIntervalSinceNow];
    if (age < -120) {
      // vehicle is more than 2 minutes old. start fading it out
      //	  CGFloat ageFactor = MIN(1, (-age - 120) / (300 - 120));
      CGFloat ageFactor = (CGFloat) MIN(1, (-age - 120) / 180);
      return ageFactor;
    }
  }
  return 0;
}

- (NSString *)serviceNumber
{
  return [[self anyService] number]; // Show nothing for non public transport
}

- (UIColor *)serviceColor
{
  Service *service = [self anyService];
  if (service) {
    return [service color];
  }
  SegmentReference *reference = [self anySegmentReference];
  if (reference) {
    return reference.template.modeInfo.color;
  }
  return nil;
}


#pragma mark - MK Annotation

- (NSString *)title
{
  NSString *modeTitle;
  Service *service = [self anyService];
  if (service) {
    modeTitle = [service.modeTitle capitalizedStringWithLocale:[NSLocale currentLocale]];
  }
  SegmentReference *reference = [self anySegmentReference];
  if (reference) {
    modeTitle = reference.template.modeInfo.descriptor;
  }
  if (!modeTitle) {
    modeTitle = self.label;
  }
  
	if (service.number) {
		return [NSString stringWithFormat:@"%@ %@", modeTitle, service.number];
	} else {
		return modeTitle;
	}
}

- (NSString *)subtitle
{
  if (! [self hasLastUpdate])
    return nil;
  
	NSTimeInterval seconds = [self.lastUpdate timeIntervalSinceNow];
  NSString *durationString = [NSDate durationStringForSeconds:-seconds];
	if (self.label.length > 0 && self.label.length < 20) {
		return [NSString stringWithFormat:NSLocalizedStringFromTable(@"VehicleCalledUpdated", @"TripKit", "Vehicle 'x' updated"), self.label, durationString];
	} else {
		return [NSString stringWithFormat:NSLocalizedStringFromTable(@"VehicleUpdated", @"TripKit", "Vehicle updated"), durationString];
	}
}


#pragma mark - ASDisplayablePoint

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
	self.latitude = @(newCoordinate.latitude);
	self.longitude = @(newCoordinate.longitude);
}

- (CLLocationCoordinate2D)coordinate
{
	return CLLocationCoordinate2DMake(self.latitude.doubleValue, self.longitude.doubleValue);
}

- (BOOL)pointDisplaysImage
{
	return NO;
}

- (BOOL)isDraggable
{
  return NO;
}

#pragma mark - Private helpers

- (Service *)anyService
{
  return self.service ?: [self.serviceAlternatives anyObject];
}

- (SegmentReference *)anySegmentReference
{
  return self.segment ?: [self.segmentAlternatives anyObject];
}

- (BOOL)hasLastUpdate
{
  return [self.lastUpdate timeIntervalSince1970] > 0;
}

@end
