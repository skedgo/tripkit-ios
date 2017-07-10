//
//  TripMapManager.m
//  Pods
//
//  Created by Adrian Schoenig on 7/09/2016.
//
//

#import "TripMapManager.h"

#ifdef TK_NO_FRAMEWORKS
#import <TripKit/TKTripKit.h>
#import <TripKit/TripKit-Swift.h>
#else
#import <TripKitUI/TripKitUI-Swift.h>
#endif

#define TIME_BETWEEN_UPDATES 10

@interface TripMapManager ()

@property (nonatomic, strong) TKBuzzInfoProvider *infoProvider;

@end

@implementation TripMapManager

#pragma mark - RouteMapManager

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.alerts = @[];
  }
  return self;
}

- (void)takeChargeOfMap:(MKMapView *)mapView
      forViewController:(UIViewController<ASMapManagerDelegate> *)controller
               animated:(BOOL)animated
             completion:(void (^)(BOOL finished))completion
{
  [super takeChargeOfMap:mapView forViewController:controller animated:animated completion:nil];
  
  // We always want to zoom at first
  self.forceZoom = YES;
  
  if (self.trip) {
    [self showRoute:self.trip animated:animated];
  }
  
  if (completion != nil) {
    completion(YES);
  }
}

- (BOOL)drawAsLargeCircle:(id<MKAnnotation>)annotation
{
#pragma unused(annotation)
  return NO; // we already show segment pins
}

- (BOOL)drawCircleAsTravelled:(id<MKAnnotation>)annotation
{
  if ([annotation isKindOfClass:[StopVisits class]]) {
    return [self.trip usesVisit:(StopVisits *)annotation];
  } else {
    return NO;
  }
}

- (BOOL)zoomToAnnotation:(id<MKAnnotation>)annotation
{
  if ([annotation isKindOfClass:[StopVisits class]]) {
    return [self.trip usesVisit:(StopVisits *)annotation];
  } else {
    return YES;
  }
}

#pragma mark - Showing the trip

- (void)reloadCurrentTrip
{
  [self refreshRouteWithAnimated:NO forceRebuild:YES zoom:ZoomModeZoomOnly];
}

- (void)showSegment:(TKSegment *)segment
           animated:(BOOL)animated
{
  ZAssert(nil != segment, @"TripMapManager needs a segment to display!");
  
  if (self.trip != segment.trip) {
    [self showRoute:segment.trip animated:animated];
    return;
  }
  
  [self refreshRouteWithAnimated:NO forceRebuild:NO zoom:ZoomModeZoomOnly];
  
  [self deselectAll];
  [self.mapView selectAnnotation:segment animated:YES];
  
  NSArray *annotationsToZoomTo = [segment annotationsToZoomToOnMap];
  if (annotationsToZoomTo) {
    [self.mapView zoomToAnnotations:annotationsToZoomTo
                        edgePadding:[self.delegate mapManagerEdgePadding:self]
                           animated:animated];
  }
}

- (void)showRoute:(Trip *)newTrip animated:(BOOL)animated
{
  [self show:newTrip zoom:ZoomModeAddAndZoomToTrip animated:animated];
}

#pragma mark - Alerts

- (void)selectAlert:(Alert *)alert
{
  if (alert.location) {
    [self.mapView selectAnnotation:alert animated:YES];
  } else {
    TKSegment *segment = [self segmentForAlert:alert];
    [self.mapView selectAnnotation:segment animated:YES];
  }
}

- (TKSegment *)segmentForAlert:(Alert *)alert
{
  for (TKSegment *segment in self.trip.segments) {
    for (Alert *ale in segment.alerts){
      if ([alert.hashCode isEqualToNumber:ale.hashCode]) {
        return segment;
      }
    }
  }
  ZAssert(false, @"Alert matches no segment: %@", alert);
  return nil;
}



#pragma mark - RealTime

- (void)realTimeUpdateForTrip:(Trip *)theTrip animated:(BOOL)animated
{
  NSMutableArray *newAlerts = [NSMutableArray array];
  
  NSMutableArray<Vehicle *> *primaries = [NSMutableArray array];
  NSMutableArray<Vehicle *> *secondaries = [NSMutableArray array];
  
  for (TKSegment *segment in theTrip.segments) {
    segment.time = segment.time; // KVO :(
    segment.title = @""; // KVO :(
    
    Vehicle *primary = segment.realTimeVehicle;
    if (primary) {
      [primaries addObject:primary];
    }
    NSArray *secondary = segment.realTimeAlternativeVehicles;
    if (secondary) {
      [secondaries addObjectsFromArray:secondary];
    }
    
    for (Alert *alert in segment.alertsWithLocation) {
      if (! [self.alerts containsObject:alert]) {
        [newAlerts addObject:alert];
      }
    }
  }
  
  [self realTimeUpdateForPrimaryVehicles:primaries
                       secondaryVehicles:secondaries
                                animated:animated];
  
  [UIView animateWithDuration:animated ? 1 : 0
                   animations:
   ^{
     [self addAnnotations:newAlerts];
     [self.mapView addAnnotations:newAlerts];
   }];
}


#pragma mark - Lazy

- (TKBuzzInfoProvider *)infoProvider {
  if (!_infoProvider) {
    _infoProvider = [[TKBuzzInfoProvider alloc] init];
  }
  return _infoProvider;
}


@end
