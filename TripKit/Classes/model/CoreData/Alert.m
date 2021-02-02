//
//  Alerts.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 19/03/13.
//
//

#import "Alert.h"

#import "NSManagedObjectContext+SimpleFetch.h"

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
@dynamic action;
@dynamic idService, idStopCode;

+ (nullable instancetype)fetchAlertWithHashCode:(NSNumber *)hashCode
                               inTripKitContext:(NSManagedObjectContext *)tripKitContext
{
  NSSet *existingAlerts = [tripKitContext fetchObjectsForEntityClass:self
                                                 withPredicateString:@"hashCode = %@", hashCode];
  return [existingAlerts anyObject];
}

- (TKAlertSeverity)alertSeverity {
  return (TKAlertSeverity) [self.severity integerValue];
}

- (void)setAlertSeverity:(TKAlertSeverity)alertSeverity {
  self.severity = @(alertSeverity);
}


@end
