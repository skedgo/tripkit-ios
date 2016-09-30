//
//  RouteViewController.h
//  TripGo
//
//  Created by Adrian Schönig on 28/02/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

@import MapKit;

@import SGCoreUIKit;

#ifndef TK_NO_FRAMEWORKS
@import TripKit;
#else
@class StopVisits, Vehicle;
#endif

@interface RouteMapManager : ASMapManager <CLLocationManagerDelegate>

@property (assign, nonatomic) CLLocationDirection heading;

/**
 * Deselect selections on the map;
 */
- (void)deselectAll;

/**
 * Remove everything related to the current route
 */
- (void)removeLastRouteFromMap;

- (void)addAnnotation:(id <MKAnnotation>)annotation;
- (void)addAnnotations:(NSArray <id <MKAnnotation>> *)annotations;

- (void)addShape:(id <STKDisplayableRoute>)shape;

- (void)addGeodesicShape:(NSArray <id <MKAnnotation>> *)annotations;

- (void)addPrimaryVehicles:(NSArray <Vehicle *> *)primary
         secondaryVehicles:(NSArray <Vehicle *> *)secondary;

/**
 * React to real-time updates for vehicles
 */
- (void)realTimeUpdateForPrimaryVehicles:(NSArray <Vehicle *> *)primary
                       secondaryVehicles:(NSArray <Vehicle *> *)secondary
                                animated:(BOOL)animated;

- (void)presentRoute;

- (void)addAndPresentAnnotation:(id <MKAnnotation>)annotation;

- (void)zoomToRoute:(BOOL)animated edgePadding:(UIEdgeInsets)insets;

#pragma mark - For subclasses to add to.

// Always call super!
- (void)updateAnnotationView:(MKAnnotationView *)annotationView
								 withHeading:(CLLocationDirection)heading;

// draws stop visits large by default
- (BOOL)drawAsLargeCircle:(id<MKAnnotation>)annotation;

- (BOOL)drawCircleAsTravelled:(id <MKAnnotation>)annotation;

- (BOOL)zoomToAnnotation:(id<MKAnnotation>)annotation;

- (BOOL)showAsSemaphore:(StopVisits *)visit;

@end
