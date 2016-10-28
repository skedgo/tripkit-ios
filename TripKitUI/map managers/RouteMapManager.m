//
//  RouteMapManager.m
//  TripGo
//
//  Created by Adrian Schönig on 28/02/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import "RouteMapManager.h"

@import CoreLocation;

@import SGCoreKit;

#ifdef TK_NO_FRAMEWORKS
#import "TripKit.h"
#import <TripKit/TripKit-Swift.h>
#endif

#import "CircleAnnotationView.h"
#import "VehicleAnnotationView.h"

@interface RouteMapManager ()

@property (nonatomic, strong) NSMutableArray *vehicleAnnotations;
@property (nonatomic, strong) NSMutableArray *routeAnnotations;
@property (nonatomic, strong) NSMutableArray *routeOverlays;

@property (strong, nonatomic) CLLocationManager *coreLocationManager;
@property (strong, nonatomic) NSMutableDictionary *stopColors;
@property (strong, nonatomic) NSTimer *vehicleUpdateTimer;

@end

@implementation RouteMapManager

#pragma mark - Public methods

- (void)takeChargeOfMap:(MKMapView *)mapView
      forViewController:(UIViewController<ASMapManagerDelegate> *)controller
               animated:(BOOL)animated
						 completion:(void (^)(BOOL finished))completion
{
  // set up local variables
  self.vehicleAnnotations = [NSMutableArray arrayWithCapacity:3];
  self.routeAnnotations = [NSMutableArray arrayWithCapacity:50];
  self.routeOverlays = [NSMutableArray arrayWithCapacity:5];
	self.stopColors = [NSMutableDictionary dictionaryWithCapacity:50];

  // NOTE: no overlay on purpose, it's not needed here
	
	// prepare
  [super takeChargeOfMap:mapView forViewController:controller animated:animated completion:nil];

  if ([MKMapCamera class]) {
    // pitch won't help much, but rotation could be useful
    self.mapView.pitchEnabled  = NO;
    self.mapView.rotateEnabled = YES;
  }

	if (completion != nil) {
		completion(YES);
	}
}

- (void)cleanUp:(BOOL)animated completion:(void(^)(BOOL finished))completion
{
	// deselect everyhing
	for (id<MKAnnotation> selection in self.mapView.selectedAnnotations) {
		[self.mapView deselectAnnotation:selection animated:NO];
	}
	
	[self removeLastRouteFromMap];
	
	[self.vehicleUpdateTimer invalidate];
  
  self.coreLocationManager = nil;
	
	[super cleanUp:animated completion:completion];
}

- (void)removeLastRouteFromMap
{
  if (self.routeAnnotations.count > 0) {
		[self.mapView removeAnnotations:self.vehicleAnnotations];
    [self.mapView removeAnnotations:self.routeAnnotations];
    [self.mapView removeOverlays:self.routeOverlays];
		[self.vehicleAnnotations removeAllObjects];
    [self.routeOverlays removeAllObjects];
    [self.routeAnnotations removeAllObjects];
		[self.stopColors removeAllObjects];
  }
}

- (void)realTimeUpdateForPrimaryVehicles:(NSArray <Vehicle *> *)primary
                       secondaryVehicles:(NSArray <Vehicle *> *)secondary
                                animated:(BOOL)animated
{
   NSMutableArray *previousVehicles = [NSMutableArray arrayWithArray:self.vehicleAnnotations];
   NSArray *newVehicles = [self adjustedVehiclesForPrimaries:primary alternatives:secondary];
   for (Vehicle *vehicle in newVehicles) {
     if ([previousVehicles containsObject:vehicle]) {
       // had it before, all good
       [previousVehicles removeObject:vehicle];
       
       // temporary revert to coordinate based on where the view is,
       // so that we can animate properly to the new view
       VehicleAnnotationView *view = (VehicleAnnotationView *) [self.mapView viewForAnnotation:vehicle];
       CLLocationCoordinate2D goodCoordinate = vehicle.coordinate;
       CGPoint center = CGPointMake(CGRectGetMidX(view.frame), CGRectGetMidY(view.frame));
       vehicle.coordinate = [self.mapView convertPoint:center toCoordinateFromView:view.superview];
       
       [UIView animateWithDuration:animated ? 1 : 0
                        animations:
        ^{
          // now we can animate to the proper coordinate
          vehicle.coordinate = goodCoordinate;
          
          if (vehicle.bearing) {
            [view rotateVehicleForBearing:vehicle.bearing.floatValue - self.heading];
          }
        }];
     
     } else {
       // didn't have it before, add it
       [self.vehicleAnnotations addObject:vehicle];
       [self.mapView addAnnotation:vehicle];
       [self prepareForVehicles];
     }
   }

   // Remove all those which aren't part of the trip anymore
   [self.vehicleAnnotations removeObjectsInArray:previousVehicles];
   [self.mapView removeAnnotations:previousVehicles];
}

- (void)setHeading:(CLLocationDirection)heading
{
	_heading = heading;
	
  [UIView animateWithDuration:0.25 animations:
	 ^{
		for (id<MKAnnotation> annotation in [self.mapView annotationsInMapRect:self.mapView.visibleMapRect]) {
			MKAnnotationView *annotationView = [self.mapView viewForAnnotation:annotation];
			[self updateAnnotationView:annotationView withHeading:heading];
		}
	}];
}

- (void)updateAnnotationView:(MKAnnotationView *)annotationView withHeading:(CLLocationDirection)heading
{
	if ([annotationView isKindOfClass:[VehicleAnnotationView class]]) {
		VehicleAnnotationView *vehicleView = (VehicleAnnotationView *)annotationView;
		Vehicle *vehicle = (Vehicle *)annotationView.annotation;
		[vehicleView rotateVehicleForHeading:heading andBearing:vehicle.bearing.floatValue];
    
	} else if ([annotationView isKindOfClass:[SGSemaphoreView class]]
					&& [annotationView.annotation conformsToProtocol:@protocol(STKDisplayableTimePoint)]) {
		SGSemaphoreView *semaphore = (SGSemaphoreView *)annotationView;
		[semaphore updateHeadForMagneticHeading:heading andBearing:[(id<STKDisplayableTimePoint>)annotationView.annotation bearing].floatValue];
	
  } else if ([annotationView isKindOfClass:[SGSemaphoreView class]]
              && [annotationView.annotation isKindOfClass:[TKSegment class]]) {
    SGSemaphoreView *semaphore = (SGSemaphoreView *)annotationView;
    TKSegment *segment = (TKSegment *)annotationView.annotation;
    [semaphore updateHeadForMagneticHeading:heading andBearing:segment.bearing.floatValue];
  }
}

- (void)deselectAll
{
  for (id<MKAnnotation> selected in self.mapView.selectedAnnotations) {
    [self.mapView deselectAnnotation:selected animated:NO];
  }
}

- (void)addAnnotation:(id<MKAnnotation>)annotation
{
	[self.routeAnnotations addObject:annotation];
}

- (void)addAnnotations:(NSArray *)annotations
{
	[self.routeAnnotations addObjectsFromArray:annotations];
}

- (void)addAndPresentAnnotation:(id <MKAnnotation>)annotation
{
	[self.routeAnnotations addObject:annotation];
	[self.mapView addAnnotation:annotation];
}

- (void)addShape:(id <STKDisplayableRoute>)shape
{
  for (MKPolyline *existing in self.routeOverlays) {
    if ([existing isKindOfClass:[STKRoutePolyline class]]) {
      STKRoutePolyline *routeAnnotation = (STKRoutePolyline *)existing;
      if (routeAnnotation.route == shape)
        return; // added already
    }
  }
  
	STKRoutePolyline *routePolyline = [STKRoutePolyline routePolylineForRoute:shape];
	if (routePolyline) {
		[self.routeOverlays addObject:routePolyline];
	}
  
  [self.routeOverlays sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
    STKRoutePolyline *routePolyline_one = (STKRoutePolyline *)obj1;
    STKRoutePolyline *routePolyline_two = (STKRoutePolyline *)obj2;
    BOOL travelled_one = [routePolyline_one.route routeIsTravelled];
    BOOL travelled_two = [routePolyline_two.route routeIsTravelled];
    if (!travelled_one && travelled_two) {
      return NSOrderedAscending;
    } else if (travelled_one && !travelled_two){
      return NSOrderedDescending;
    } else {
      return NSOrderedSame;
    }
  }];
}

- (void)addGeodesicShape:(NSArray *)annotations
{
  MKGeodesicPolyline *geodesicPolyline = [STKRoutePolyline geodesicPolylineForAnnotations:annotations];
  [self.routeOverlays addObject:geodesicPolyline];
}

- (void)addPrimaryVehicles:(NSArray<Vehicle *> *)primary
          secondaryVehicles:(NSArray<Vehicle *> *)secondary
{
  NSArray *adjusted = [self adjustedVehiclesForPrimaries:primary alternatives:secondary];
  if (adjusted.count > 0) {
    [self.vehicleAnnotations addObjectsFromArray:adjusted];
  }
}

- (void)presentRoute
{
	[self prepareForVehicles];
  
  // add what we found
  [self.mapView addOverlays:self.routeOverlays level:MKOverlayLevelAboveRoads];
  [self.mapView addAnnotations:self.routeAnnotations];
	[self.mapView addAnnotations:self.vehicleAnnotations];
}

- (void)zoomToRoute:(BOOL)animated edgePadding:(UIEdgeInsets)insets
{
	NSMutableArray *annotations = [NSMutableArray arrayWithCapacity:self.routeAnnotations.count + self.vehicleAnnotations.count];
	for (id<MKAnnotation> annotation in self.routeAnnotations) {
		if ([self zoomToAnnotation:annotation]) {
			[annotations addObject:annotation];
		}
	}
	[annotations addObjectsFromArray:self.vehicleAnnotations];	
	if (annotations.count > 0) {
		[self.mapView zoomToAnnotations:annotations edgePadding:insets animated:animated];
	}
}


#pragma mark - View lifecycle

- (void)dealloc
{
	[_vehicleUpdateTimer invalidate];
	
  [self.mapView removeAnnotations:self.mapView.annotations];
  [self.mapView removeOverlays:self.mapView.overlays];
  
  _coreLocationManager.delegate = nil;
}

#pragma mark - Core location delegate

- (void)locationManager:(CLLocationManager *)manager
       didUpdateHeading:(CLHeading *)newHeading
{
#pragma unused(manager)

  double heading = newHeading.magneticHeading;
  
  UIInterfaceOrientation orientation;
  if ([self.delegate respondsToSelector:@selector(mapManagerDeviceOrientation:)]) {
    orientation = [self.delegate mapManagerDeviceOrientation:self];
  } else {
    orientation = UIInterfaceOrientationPortrait; // assume portait
  }
  
	if(orientation == UIInterfaceOrientationPortraitUpsideDown)
		heading += 180;
	else if(orientation == UIInterfaceOrientationLandscapeLeft)
		heading -= 90;
	else if(orientation == UIInterfaceOrientationLandscapeRight)
		heading += 90;
	
	self.heading = heading;
}

#pragma mark - MapView delegate

- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
#pragma unused(mapView, animated)

  if (mode == MKUserTrackingModeFollowWithHeading) {
    if (nil == self.coreLocationManager) {
      self.coreLocationManager = [[CLLocationManager alloc] init];
      self.coreLocationManager.delegate = self;
    }
    [self.coreLocationManager startUpdatingHeading];
  } else if (self.coreLocationManager != nil) {
    
    // reset all the views
		self.heading = 0;
    
    [self.coreLocationManager stopUpdatingHeading];
    self.coreLocationManager = nil;
  }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView
            rendererForOverlay:(id <MKOverlay>)overlay
{
  if ([overlay isKindOfClass:[MKGeodesicPolyline class]]) {
    MKGeodesicPolyline *geodesic = (MKGeodesicPolyline *)overlay;
    SGPolylineRenderer *routeRenderer	= [[SGPolylineRenderer alloc] initWithPolyline:geodesic];
    return routeRenderer;
    
  } else if ([overlay isKindOfClass:[STKRoutePolyline class]]) {
    STKRoutePolyline * routePolyline = (STKRoutePolyline *) overlay;
    id<STKDisplayableRoute> route = [routePolyline route];
		
		SGPolylineRenderer *routeRenderer	= [[SGPolylineRenderer alloc] initWithPolyline:routePolyline];
		routeRenderer.strokeColor       = [route routeColour];
    NSArray *lineDashPattern        = [route respondsToSelector:@selector(routeDashPattern)] ? [route routeDashPattern] : nil;
    if (lineDashPattern) {
      routeRenderer.lineDashPattern = lineDashPattern;
    }
		return routeRenderer;
  } else {
    return [super mapView:mapView rendererForOverlay:overlay];
  }
}

- (MKAnnotationView *)mapView:(MKMapView *)mv 
            viewForAnnotation:(id <MKAnnotation>)annotation 
{
  if ([annotation isKindOfClass:[MKUserLocation class]])
    return nil;
	
	MKAnnotationView* annotationView = nil;
	static NSString *SmallCircleIdentifier = @"SmallCircleView";
	static NSString *LargeCircleIdentifier = @"LargeCircleView";
	static NSString *VehicleIdentifier = @"VehicleAnnotationView";
  
  if ([annotation isKindOfClass:[Vehicle class]]) {
    // vehicles are little arrows
    Vehicle *vehicle = (Vehicle *)annotation;
    
    VehicleAnnotationView *vehicleView = (VehicleAnnotationView *) [mv dequeueReusableAnnotationViewWithIdentifier:VehicleIdentifier];
    if (nil == vehicleView) {
      vehicleView = [[VehicleAnnotationView alloc] initWithAnnotation:vehicle reuseIdentifier:VehicleIdentifier];
    }
    
    if (nil != vehicle.bearing) {
      [vehicleView rotateVehicleForHeading:self.heading andBearing:vehicle.bearing.floatValue];
    }
    vehicleView.annotationColor = [UIColor colorWithRed:.31f green:.64f blue:.22f alpha:1];
    [vehicleView updateForAge:vehicle.ageFactor];
    
    annotationView = vehicleView;
    
  } else if ([annotation isKindOfClass:[StopVisits class]] && [self showAsSemaphore:(StopVisits *)annotation]) {

    // Visits can be drawn as semaphores as they have a direction
    
    static NSString *sempahoreIdentifier = @"Semaphore";
    SGSemaphoreView * semaphoreView = (SGSemaphoreView *)[mv dequeueReusableAnnotationViewWithIdentifier:sempahoreIdentifier];
    
    StopVisits *visit = (StopVisits *)annotation;
    if (nil == semaphoreView) {
      semaphoreView = [[SGSemaphoreView alloc] initWithAnnotation:visit
                                                  reuseIdentifier:sempahoreIdentifier
                                                      withHeading:self.heading];
    } else {
      [semaphoreView updateForAnnotation:visit
                             withHeading:self.heading];
    }
    
    // Set the time stamp on the side opposite to the travel direction.
    CLLocationDirection absoluteBearing = visit.bearing.floatValue - self.heading;
    SGSemaphoreLabel side = (absoluteBearing > 180 ? SGSemaphoreLabelOnRight : SGSemaphoreLabelOnLeft);
    
    [semaphoreView setTime:visit.departure
                isRealTime:[visit.service isRealTime]
                inTimeZone:visit.stop.region.timeZone
                    onSide:side];

    annotationView = semaphoreView;
    annotationView.canShowCallout = YES;
    
    
  } else if ([annotation isKindOfClass:[StopLocation class]]
             || [annotation isKindOfClass:[StopVisits class]]) {
    // a circle
    // we make visits large and changes
    BOOL isLarge = [self drawAsLargeCircle:annotation];
    NSString *identifier = isLarge ? LargeCircleIdentifier : SmallCircleIdentifier;
    
    CircleAnnotationView* circle = (CircleAnnotationView*)[mv dequeueReusableAnnotationViewWithIdentifier:identifier];
    if (nil == circle) {
      circle = [[CircleAnnotationView alloc] initWithAnnotation:annotation
                                                      drawLarge:isLarge
                                                reuseIdentifier:identifier];
    }
    
    // determine the faded state
    BOOL travelled = [self drawCircleAsTravelled:annotation];
    circle.isFaded = (NO == travelled);

    // determine the colour
    if ([annotation isKindOfClass:[StopLocation class]]) {
      StopLocation *stop = (StopLocation *)annotation;
      circle.circleColor = [SGKTransportStyler routeDashColorNontravelled];
      if (travelled && stop.name) {
        circle.circleColor = [self.stopColors valueForKey:stop.name];
      }
    } else if ([annotation isKindOfClass:[StopVisits class]])  {
      StopVisits *visit = (StopVisits *)annotation;
      circle.circleColor = travelled
                            ? visit.service.color
                            : [SGKTransportStyler routeDashColorNontravelled];
    }
    
    circle.alpha = [self alphaForCircleAnnotations:circle.isLarge];
    [circle setNeedsDisplay];
    annotationView = circle;
    
  } else if ([annotation isKindOfClass:[TKSegment class]]) {
    // Segments get drawn as semaphores
    TKSegment *segment = (TKSegment *)annotation;
    
    static NSString *sempahoreIdentifier = @"Semaphore";
    SGSemaphoreView *semaphoreView = (SGSemaphoreView *)[mv dequeueReusableAnnotationViewWithIdentifier:sempahoreIdentifier];
    
    if (nil == semaphoreView) {
      semaphoreView = [[SGSemaphoreView alloc] initWithAnnotation:segment
                                                  reuseIdentifier:sempahoreIdentifier
                                                      withHeading:self.heading];
    } else {
      [semaphoreView updateForAnnotation:segment
                             withHeading:self.heading];
    }
    
    // Only public transport get the time stamp. And they get it on the side opposite to the
    // travel direction.
    SGSemaphoreLabel side = SGSemaphoreLabelDisabled;
    
    CLLocationDirection absoluteBearing = segment.bearing.floatValue - self.heading;
    if ([segment isPublicTransport]) {
      side = (absoluteBearing > 180 ? SGSemaphoreLabelOnRight : SGSemaphoreLabelOnLeft);
    } else if ([segment isTerminal]) {
      CLLocationCoordinate2D fromCoordinate = [segment.trip.request.fromLocation coordinate];
      CLLocationCoordinate2D toCoordinate = [segment.trip.request.toLocation coordinate];
      BOOL isLeft = (fromCoordinate.longitude > toCoordinate.longitude);
      side = isLeft ? SGSemaphoreLabelOnLeft : SGSemaphoreLabelOnRight;
    }
    
    if (segment.frequency.integerValue > 0) {
      [semaphoreView setFrequency:segment.frequency
                           onSide:side];
    } else {
      [semaphoreView setTime:segment.departureTime
                  isRealTime:segment.timeIsRealTime
                  inTimeZone:segment.timeZone
                      onSide:side];
    }
    
    annotationView = semaphoreView;
    
  } else if ([annotation conformsToProtocol:@protocol(STKDisplayablePoint)]) {
      
    static NSString *ImageIdentifier = @"ImageAnnotationIdenfifier";
    ASImageAnnotationView *imageAnnotationView = (ASImageAnnotationView *) [mv dequeueReusableAnnotationViewWithIdentifier:ImageIdentifier];
    if (nil == imageAnnotationView) {
      imageAnnotationView = [[ASImageAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:ImageIdentifier];
    } else {
      imageAnnotationView.annotation = annotation;
    }
    
    imageAnnotationView.alpha = 1;
    imageAnnotationView.leftCalloutAccessoryView = nil;
    imageAnnotationView.rightCalloutAccessoryView = nil;

    annotationView = imageAnnotationView;
  }
  
  [annotationView setCanShowCallout:[annotation respondsToSelector:@selector(title)]];
  [annotationView setEnabled:YES];
	
	return annotationView;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
  [super mapView:mapView regionDidChangeAnimated:animated];

	// see if the user manually rotated the map
  MKMapCamera *camera = [mapView camera];
  self.heading = camera.heading;
	
	// fade stuff in and out
	CGFloat alphaSmall = [self alphaForCircleAnnotations:NO];
	CGFloat alphaLarge = [self alphaForCircleAnnotations:YES];
	for (id<MKAnnotation> visibleAnnotation in [mapView annotationsInMapRect:mapView.visibleMapRect]) {
		MKAnnotationView *view = [mapView viewForAnnotation:visibleAnnotation];
		if ([view isKindOfClass:[CircleAnnotationView class]]) {
			CircleAnnotationView *circleView = (CircleAnnotationView *)view;
			if (circleView.isLarge) {
				view.alpha = alphaLarge;
			} else {
				view.alpha = alphaSmall;
			}
		}
	}
}

- (BOOL)drawAsLargeCircle:(id<MKAnnotation>)annotation
{
	return [annotation isKindOfClass:[StopVisits class]];
}

- (BOOL)drawCircleAsTravelled:(id <MKAnnotation>)annotation
{
#pragma unused(annotation)
  return YES;
}

- (BOOL)zoomToAnnotation:(id<MKAnnotation>)annotation
{
#pragma unused(annotation)
  return YES;
}

- (BOOL)showAsSemaphore:(StopVisits *)visit
{
#pragma unused(visit)
  return NO;
}


#pragma mark - Private methods

- (CGFloat)alphaForCircleAnnotations:(BOOL)isLarge
{
  TG_ASSERT_MAIN_THREAD;
  
	NSUInteger zoomLevel = [self.mapView zoomLevel];
	if (isLarge) {
		return zoomLevel > 10 ? 0 : 1;
	} else {
		return zoomLevel > 7 ? 0 : 1;
	}
//	int min = 7.5, max = 10;
//	if (zoomLevel >= max)
//		return 0;
//	else if (zoomLevel <= min)
//		return 1;
//	else
//		return 1 - (zoomLevel - min) / (max - min);
}


- (void)prepareForVehicles
{
	// add a timer to update the vehicles
	[self.vehicleUpdateTimer invalidate];
	if (self.vehicleAnnotations.count > 0) {
		self.vehicleUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1
																															 target:self
																														 selector:@selector(vehicleUpdateTimerFired:)
																														 userInfo:nil
																															repeats:YES];
	}
}

- (NSArray *)adjustedVehiclesForPrimaries:(NSArray <Vehicle *> *)primaries
                             alternatives:(NSArray <Vehicle *> *)secondaries
{
  NSMutableArray *vehicles = [NSMutableArray array];
  if (primaries) {
    for (Vehicle *vehicle in primaries) {
      vehicle.displayAsPrimary = YES;
      [vehicles addObject:vehicle];
    }
  }
  if (secondaries) {
    for (Vehicle *vehicle in secondaries) {
      vehicle.displayAsPrimary = NO;
      [vehicles addObject:vehicle];
    }
  }
  return vehicles;
}

- (void)vehicleUpdateTimerFired:(id)sender
{
#pragma unused(sender)

  NSMutableArray *vehiclesToRemove = [NSMutableArray arrayWithCapacity:self.vehicleAnnotations.count];
	for (Vehicle *vehicle in self.vehicleAnnotations) {
		// check if the vehicle still exists
		if (nil == vehicle.managedObjectContext || [vehicle isDeleted]) {
			[vehiclesToRemove addObject:vehicle];
			continue;
		}
		
		[vehicle setSubtitle:nil];
		
		VehicleAnnotationView *vehicleView = (VehicleAnnotationView *) [self.mapView viewForAnnotation:vehicle];
    [vehicleView updateForAge:vehicle.ageFactor];
	}
	
	// remove the vehicles
	for (Vehicle *vehicle in vehiclesToRemove) {
		[self.mapView removeAnnotation:vehicle];
		[self.vehicleAnnotations removeObject:vehicle];
	}
}


@end
