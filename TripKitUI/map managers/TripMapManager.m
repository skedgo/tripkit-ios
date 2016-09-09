//
//  TripMapManager.m
//  Pods
//
//  Created by Adrian Schoenig on 7/09/2016.
//
//

#import "TripMapManager.h"

#import <TripKitUI/TripKitUI-Swift.h>

#define TIME_BETWEEN_UPDATES 10

@interface TripMapManager ()

@property (nonatomic, strong) NSTimer *realTimeUpdateTimer;

@end

@implementation TripMapManager

#pragma mark - RouteMapManager

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

- (void)cleanUp:(BOOL)animated completion:(void (^)(BOOL finished))completion
{
  // stop updating
  [self.realTimeUpdateTimer invalidate];
  self.realTimeUpdateTimer = nil;
	 
  [super cleanUp:animated completion:completion];
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

- (void)kickOffRealTimeUpdates:(BOOL)animated
{
  [self scheduleRealTimeUpdateTimer];
  [self updateTripWithRealTimeData:animated];
}

- (void)setEnableRealTimeUpdates:(BOOL)enableRealTimeUpdates
{
  if (_enableRealTimeUpdates == enableRealTimeUpdates) {
    return;
  }
  
  _enableRealTimeUpdates = enableRealTimeUpdates;
  
  if (enableRealTimeUpdates) {
    [self scheduleRealTimeUpdateTimer];
  } else {
    [self.realTimeUpdateTimer invalidate];
    self.realTimeUpdateTimer = nil;
  }
}

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

- (void)subsequentRealtimeUpdate:(NSTimer *)timer
{
#pragma unused(timer)
  [self updateTripWithRealTimeData:YES];
}

- (void)updateTripWithRealTimeData:(BOOL)animated
{
  if (!self.enableRealTimeUpdates
      || nil == self.trip
      || nil == self.trip.managedObjectContext // this would happen if the user deleted the trip (say, via the favourites)
      || NO == [self.trip wantsRealTimeUpdates]
      )
  {
    [self.realTimeUpdateTimer invalidate];
    self.realTimeUpdateTimer = nil;
    return;
  }
  
  TKBuzzRealTime *realTime = [[TKBuzzRealTime alloc] init];
  [realTime updateTrip:self.trip
               success:
   ^(Trip *updatedTrip, BOOL tripDidUpdate) {
     if (tripDidUpdate && self.trip == updatedTrip) {
       // Update map and details
       [self realTimeUpdateForTrip:updatedTrip animated:animated];
     }
   }
               failure:
   ^(NSError *error) {
#pragma unused(error)
     DLog(@"Error: %@", error);

   }];
}

- (void)scheduleRealTimeUpdateTimer
{
  // Invalidate old if we have one
  [self.realTimeUpdateTimer invalidate];
  
  // Schedule new
  self.realTimeUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:TIME_BETWEEN_UPDATES
                                                              target:self
                                                            selector:@selector(subsequentRealtimeUpdate:)
                                                            userInfo:nil
                                                             repeats:YES];
}


@end
