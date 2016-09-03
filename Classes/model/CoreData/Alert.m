//
//  Alerts.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 19/03/13.
//
//

#import "Alert.h"

#import <TripKit/TKTripKit.h>

@implementation Alert

@dynamic location;
@dynamic hashCode;
@dynamic title;
@dynamic text;
@dynamic url;
@dynamic severity;
@dynamic remoteIcon;
@dynamic startTime;
@dynamic endTime;
@dynamic toDelete;
@dynamic idService, idStopCode;

+ (instancetype)fetchAlertWithHashCode:(NSNumber *)hashCode
                      inTripKitContext:(NSManagedObjectContext *)tripKitContext
{
  NSSet *existingAlerts = [tripKitContext fetchObjectsForEntityClass:self
                                                 withPredicateString:@"toDelete = NO AND hashCode = %@", hashCode];
  return [existingAlerts anyObject];
}

+ (NSArray *)fetchAlertsWithHashCodes:(NSArray *)hashCodes
                     inTripKitContext:(NSManagedObjectContext *)tripKitContext
                 sortedByDistanceFrom:(CLLocationCoordinate2D)coordinate
{
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"toDelete = NO AND hashCode in %@", hashCodes];
  NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"severity" ascending:NO];
  
  // get rid of duplicates and sort by distance from start
  NSArray *alerts = [tripKitContext fetchObjectsForEntityClass:self
                                                 withPredicate:predicate
                                            andSortDescriptors:@[sorter]];
  NSMutableSet *hashes = [NSMutableSet setWithCapacity:alerts.count];
  NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:alerts.count];
  for (Alert *alert in alerts) {
    NSNumber *hashCode = [alert hashCode];
    if (! [hashes containsObject:hashCode]) {
      [hashes addObject:hashCode];
      [filtered addObject:alert];
    }
  }
  
  if (filtered.count > 0) {
    CLLocation *fromLocation = [[CLLocation alloc] initWithLatitude:coordinate.latitude
                                                          longitude:coordinate.longitude];
    [filtered sortUsingComparator:^NSComparisonResult(Alert *alert1, Alert *alert2) {
      CLLocation *loc1 = nil;
      CLLocation *loc2 = nil;
      
      if (alert1.location) {
        loc1 = [[CLLocation alloc] initWithLatitude:alert1.location.coordinate.latitude
                                          longitude:alert1.location.coordinate.longitude];
      }
      if (alert2.location) {
        loc2 = [[CLLocation alloc] initWithLatitude:alert2.location.coordinate.latitude
                                          longitude:alert2.location.coordinate.longitude];
      }
      CLLocationDistance distance1 = loc1 ? [fromLocation distanceFromLocation:loc1] : 0;
      CLLocationDistance distance2 = loc2 ? [fromLocation distanceFromLocation:loc2] : 0;
      return [@(distance1) compare:@(distance2)];

    }];
  }
  
  return filtered;
}

+ (NSArray *)fetchAlertsForService:(Service *)service
{
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"toDelete = NO AND idService = %@", service.code];
  NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"severity" ascending:NO];
  return [service.managedObjectContext fetchObjectsForEntityClass:self
                                                    withPredicate:predicate
                                               andSortDescriptors:@[sorter]];
}

+ (NSArray *)fetchAlertsForStopLocation:(StopLocation *)stopLocation
{
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"toDelete = NO AND idStopCode = %@", stopLocation.stopCode];
  NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"severity" ascending:NO];
  return [stopLocation.managedObjectContext fetchObjectsForEntityClass:self
                                                         withPredicate:predicate
                                                    andSortDescriptors:@[sorter]];
}

- (AlertSeverity)alertSeverity {
  return (AlertSeverity) [self.severity integerValue];
}

- (void)setAlertSeverity:(AlertSeverity)alertSeverity {
  self.severity = @(alertSeverity);
}

- (STKInfoIconType)infoIconType
{
  switch (self.alertSeverity) {
    case AlertSeverityInfo:
      return STKInfoIconTypeNone;
    case AlertSeverityWarning:
      return STKInfoIconTypeWarning;
    case AlertSeverityAlert:
      return STKInfoIconTypeAlert;
  }
}

- (nullable NSURL *)imageURL
{
  if (!self.remoteIcon) {
    return nil;
  } else {
    return [SVKServer imageURLForIconFileNamePart:self.remoteIcon ofIconType:SGStyleModeIconTypeAlert];
  }
}

- (void)remove
{
  self.toDelete = YES;
}


#pragma mark - ASDisplayablePoint

- (CLLocationCoordinate2D)coordinate
{
  if (self.location) {
    return [self.location coordinate];
  } else {
    return kCLLocationCoordinate2DInvalid;
  }
}

- (BOOL)pointDisplaysImage
{
  return (self.location != nil);
}

- (UIImage *)pointImage
{
  NSString *imageName = [STKInfoIcon imageNameForInfoIconType:self.infoIconType usage:STKInfoIconUsageMap];
  return [SGStyleManager imageNamed:imageName];
}

- (NSURL *)pointImageURL
{
  return self.imageURL;
}

- (BOOL)isDraggable
{
  return NO;
}

@end
