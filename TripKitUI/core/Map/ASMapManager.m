//
//  MapManager.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 28/09/12.
//
//

#import "ASMapManager.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
#endif

#import "SGMapButtonView.h"
#import "SGPolylineRenderer.h"

@interface ASMapManager ()

@property (nonatomic, weak) MKMapView *mapView;
@property (nonatomic, weak) UIViewController<ASMapManagerDelegate> *delegate;
@property (nonatomic, assign, getter = isActive) BOOL active;

@property (nonatomic, strong, nullable) NSArray *originalButtons;

@property (nonatomic, strong) NSTimer *saveTimer; // timer for when to save map rect

@property (nonatomic, strong, nullable) UILongPressGestureRecognizer *tap;
@property (assign, nonatomic) CGPoint firstPoint;
@property (assign, nonatomic) MKCoordinateRegion firstRegion;

@end

@implementation ASMapManager

- (void)setMapButtonView:(SGMapButtonView *)mapButtonView
{
  _mapButtonView = mapButtonView;
  self.originalButtons = [mapButtonView items];
}

- (void)cleanUp:(BOOL)animated
     completion:(void (^)(BOOL finished))completion
{
	// remove the buttons from the toolbar
	[self setMapButtons:nil includingOriginal:YES animated:animated];
  
  [self removeOverlay];
  [self removeDoubleTapZoomGestureRecognizer];

  self.mapView.delegate = nil;
	self.mapView = nil;
	self.active = NO;
	
  // reset this _after_ removing buttons as it relies on the principal controller
  self.delegate = nil;
  self.willHotSwap = NO;

	if (nil != completion) {
		completion(YES);
	}
}

- (void)takeChargeOfMap:(MKMapView *)mapView
      forViewController:(UIViewController<ASMapManagerDelegate> *)controller
               animated:(BOOL)animated
						 completion:(void (^)(BOOL finished))completion
{
  self.delegate = controller;
  self.mapView = mapView;
  self.mapView.delegate = self;
	self.active = YES;
  
  // style the map - we don't want POI's
  self.mapView.showsPointsOfInterest = NO;
  
  // add the overlay
  [self addOverlay];
  
  // restore last used map location
  if (! self.willHotSwap && self.lastMapRectUserDefaultsKey) {
    [self showLastUsedMapRect:NO];
  }
	
	// add the buttons to the toolbar (only on phone)
	if (self.mapButtonView) {
		[self setMapButtons:@[]
      includingOriginal:YES
               animated:animated];
	}
  
  self.willHotSwap = NO;
  
  [self addDoubleTapZoomGestureRecognizer];
	
	if (completion) {
		completion(YES);
	}
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
  
  _tap.delegate = nil;
}

- (CGFloat)topLayoutGuideLength
{
  return self.topOverlap;
}

- (CGFloat)bottomLayoutGuideLength
{
  return self.bottomOverlap;
}

- (void)setOverlayPolygon:(MKPolygon *)overlayPolygon
{
  if (_overlayPolygon == overlayPolygon) {
    return; // nothing to do
  }
  
  if (_overlayPolygon && overlayPolygon != _overlayPolygon) {
    // remove the old
    [self removeOverlay];
  }
  _overlayPolygon = overlayPolygon;
  if (_overlayPolygon && self.isActive) {
    [self addOverlay];
  }
}

#pragma mark - MKMapViewDelegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
#pragma unused(mapView)
  
  if ([overlay isKindOfClass:[MKGeodesicPolyline class]]) {
    MKGeodesicPolyline *geodesic = (MKGeodesicPolyline *)overlay;
    SGPolylineRenderer *routeRenderer = [[SGPolylineRenderer alloc] initWithPolyline:geodesic];
    return routeRenderer;
    
  } else if ([overlay isKindOfClass:[STKRoutePolyline class]]) {
    STKRoutePolyline * routeAnnotation = (STKRoutePolyline *) overlay;
    UIColor *routeColor = [[routeAnnotation route] routeColor];
    
    SGPolylineRenderer *routeRenderer	= [[SGPolylineRenderer alloc] initWithPolyline:routeAnnotation];
    routeRenderer.strokeColor       = routeColor;
    
    id<STKDisplayableRoute> route = [routeAnnotation route];
    NSArray *lineDashPattern = [route routeDashPattern];
    if (nil != lineDashPattern) {
      routeRenderer.lineDashPattern = lineDashPattern;
    }
    return routeRenderer;
  
  } else if ([overlay isKindOfClass:[MKPolygon class]]) {
    MKPolygonRenderer *aRenderer = [[MKPolygonRenderer alloc] initWithPolygon:(MKPolygon*)overlay];
    aRenderer.fillColor = [UIColor colorWithRed:52/255.0f green:78/255.0f blue:109/255.0f alpha:0.5f];
    aRenderer.lineWidth = 0;
    return aRenderer;
    
  } else {
    return nil;
  }
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
#pragma unused(mapView, animated)
  if ([self.delegate respondsToSelector:@selector(mapManager:regionDidChangeAnimated:)]) {
    [self.delegate mapManager:self regionDidChangeAnimated:animated];
  }
}


- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
#pragma unused(mapView, animated)
	// save it in a second. this is to not save it while the user
	// is still panning.
	[self.saveTimer invalidate];
	self.saveTimer = [NSTimer scheduledTimerWithTimeInterval:1
																										target:self
																									selector:@selector(saveMapRectAsLastUsed)
																									userInfo:nil
																									 repeats:NO];
  
  if ([self.delegate respondsToSelector:@selector(mapManager:regionDidChangeAnimated:)]) {
    [self.delegate mapManager:self regionDidChangeAnimated:animated];
  }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
#pragma unused(mapView, control)
  if ([self.delegate respondsToSelector:@selector(mapManager:didSelectAnnotation:sender:)]) {
    [self.delegate mapManager:self
          didSelectAnnotation:view.annotation
                       sender:view];
  }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
#pragma unused(mapView)
  if ([self.delegate respondsToSelector:@selector(mapManager:didSelectAnnotation:sender:)]) {
    [self.delegate mapManager:self
          didSelectAnnotation:view.annotation
                       sender:view];
  }
}

#pragma mark - Notifications

- (void)shouldRefreshOverlay:(NSNotification *)notification
{
#pragma unused(notification)
  ZAssert(self.overlayPolygon && self.isActive, @"Only call this if we have an overlay polygon and are active!");

  // re-add the overlay
  __weak typeof(self) weakSelf = self;
	dispatch_async(dispatch_get_main_queue(), ^{
    typeof(weakSelf) strongSelf = weakSelf;
    if (strongSelf.isActive) {
      [strongSelf removeOverlay];
      [strongSelf addOverlay];
    }
  });
}

#pragma mark - Private methods

- (void)addOverlay
{
  if (! self.overlayPolygon)
    return;
  
  ZAssert(self.isActive, @"Only call this if we have an overlay polygon and are active!");
  
  if (! self.willHotSwap &&
      ! [self.mapView.overlays containsObject:self.overlayPolygon]) {
    // in with the new
    if ([self.mapView respondsToSelector:@selector(addOverlay:level:)]) {
      [self.mapView addOverlay:self.overlayPolygon
                         level:MKOverlayLevelAboveLabels];
    } else {
      // iOS 6
      [self.mapView addOverlay:self.overlayPolygon];
    }
  }
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(shouldRefreshOverlay:)
                                               name:SGMapShouldRefreshOverlayNotification
                                             object:nil];
}

- (void)removeOverlay
{
  if (! self.overlayPolygon)
    return;

  if (! self.willHotSwap) {
    [self.mapView removeOverlay:self.overlayPolygon];
  }
  [[NSNotificationCenter defaultCenter] removeObserver:self name:SGMapShouldRefreshOverlayNotification object:nil];
}

- (void)setMapButtons:(nullable NSArray *)buttons
    includingOriginal:(BOOL)includeOriginal
             animated:(BOOL)animated
{
	if (self.mapButtonView) {
		if (! buttons || buttons.count == 0) {
			// restore
			[self.mapButtonView setItems:self.originalButtons animated:animated];
		} else {
			NSMutableArray *items = [NSMutableArray array];
			if (includeOriginal) {
				[items addObjectsFromArray:self.originalButtons];
			}
			[items addObjectsFromArray:buttons];
			[self.mapButtonView setItems:items animated:animated];
		}
	}
}

+ (MKMapRect)mapRectForUserDefaultsKey:(NSString *)key
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSArray *rectArray = [defaults objectForKey:key];
  if (rectArray.count == 4) {
		return MKMapRectMake([rectArray[0] doubleValue],
                         [rectArray[1] doubleValue],
                         [rectArray[2] doubleValue],
												 [rectArray[3] doubleValue]);
    
  } else {
    // set to null, don't change the map
		return MKMapRectNull;
  }
}

- (void)showLastUsedMapRect:(BOOL)animated
{
  MKMapRect mapRect = [[self class] mapRectForUserDefaultsKey:self.lastMapRectUserDefaultsKey];
  if (! MKMapRectIsNull(mapRect)) {
    [self.mapView setVisibleMapRect:mapRect animated:animated];
  }
}

- (void)saveMapRectAsLastUsed
{
  NSString *key = self.lastMapRectUserDefaultsKey;
  if (!key) {
    return;
  }
	// don't keep it if the map view is too small
	if (self.mapView.frame.size.height < 10) {
		return;
	}
	
	// keep it for later if it's a valid rect
	MKMapRect rect = self.mapView.visibleMapRect;
	if (rect.origin.x > 0 && rect.origin.y > 0 && rect.size.height > 0) {
		NSArray *rectArray = @[
                           @(rect.origin.x),
                           @(rect.origin.y),
                           @(rect.size.width),
                           @(rect.size.height)
                           ];
		
		[[NSUserDefaults standardUserDefaults] setObject:rectArray
                                              forKey:key];
	}
}

- (void)addDoubleTapZoomGestureRecognizer
{
    if (!self.tap) {
        self.tap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(tapResponder:)];
        self.tap.delegate = self;
        self.tap.numberOfTapsRequired = 1;
        self.tap.numberOfTouchesRequired = 1;
        self.tap.minimumPressDuration = 0.2;
        self.tap.allowableMovement = 200.0;
        [self.mapView addGestureRecognizer:self.tap];
    }
}

- (void)removeDoubleTapZoomGestureRecognizer
{
    if (self.tap) {
        [self.mapView removeGestureRecognizer:self.tap];
    }
}

- (void)tapResponder:(UILongPressGestureRecognizer *)sender
{
    double factor = 1.05;
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.firstPoint = [sender locationInView:self.mapView];
        self.firstRegion = self.mapView.region;
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint newPoint = [sender locationInView:self.mapView];
        CGFloat distance = (newPoint.y - self.firstPoint.y);
        if (distance > 1.0) {
            MKCoordinateSpan span = self.firstRegion.span;
            
            span.latitudeDelta = span.latitudeDelta / factor;
            span.longitudeDelta = span.longitudeDelta / factor;
            
            self.firstRegion = MKCoordinateRegionMake(self.firstRegion.center, span);
            [self.mapView setRegion:self.firstRegion animated:NO];
            self.firstPoint = newPoint;
        }
        else if (distance < -1.0) {
            MKCoordinateSpan span = self.firstRegion.span;
            
            span.latitudeDelta = span.latitudeDelta * factor;
            span.longitudeDelta = span.longitudeDelta * factor;
            
            CLLocationCoordinate2D topLeft = CLLocationCoordinate2DMake(self.firstRegion.center.latitude - span.latitudeDelta, self.firstRegion.center.longitude - span.longitudeDelta);
            CLLocationCoordinate2D bottomRight = CLLocationCoordinate2DMake(self.firstRegion.center.latitude + span.latitudeDelta, self.firstRegion.center.longitude + span.longitudeDelta);
            if (!CLLocationCoordinate2DIsValid(topLeft) || !CLLocationCoordinate2DIsValid(bottomRight)) {
                return;
            }
            
            self.firstRegion = MKCoordinateRegionMake(self.firstRegion.center, span);
            [self.mapView setRegion:self.firstRegion animated:NO];
            self.firstPoint = newPoint;
        }
    } else if (sender.state == UIGestureRecognizerStateEnded) {
      // nothing to do
    }
}

@end
