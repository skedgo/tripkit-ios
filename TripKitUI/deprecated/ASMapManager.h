//
//  MapManager.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 28/09/12.
//
//
// The default map manager does the following things:
//
// - Provides an interface to take charge of a map view and clean it up
//   afterwards. This is very useful if a single map view is used for different
//   things.
// - Show overlay buttons on the bottom of the map in a toolbar.
// - Keep track of the visible map region and re-open it later on.
// - Show an overlay to grey out certain areas.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class TKUIMapButtonView;
@protocol ASMapManagerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface ASMapManager : NSObject <MKMapViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;
@property (nonatomic, weak, nullable) TKUIMapButtonView *mapButtonView;

/**
 * A polygon which will be shown as a greyed out overlay. Use this to mark
 * non-supported regions.
 *
 * @default nil, i.e., no overlay
 */
@property (nonatomic, strong, nullable) MKPolygon *overlayPolygon;

@property (nonatomic, assign) BOOL willHotSwap;

/**
 * Boolean if the last viewed map rect should be restored when the map manager
 * is taking charge of the map - if `lastMapRectUserDefaultsKey` is set.
 *
 * @default true
 */
@property (nonatomic, assign) BOOL allowRestoringLastMapRect;

/**
 * The key path to where the last visible map rect is stored in the user
 * defaults.
 *
 * @default nil, i.e., not stored
 */
@property (nonatomic, copy, nullable) NSString *lastMapRectUserDefaultsKey;

/**
 * The key path to where the last `NSDate` is stored when this map manager
 * was last used in the user defaults.
 *
 * @default nil, i.e., not stored
 */
@property (nonatomic, copy, nullable) NSString *lastUseUserDefaultsKey;


+ (MKMapRect)mapRectForUserDefaultsKey:(nullable NSString *)mapKey
                               dateKey:(nullable NSString *)dateKey;

+ (void)saveMapRect:(MKMapRect)rect
 forUserDefaultsKey:(NSString *)mapKey
            dateKey:(nullable NSString *)dateKey;

- (BOOL)isActive;

/**
 @return The map view this map manager is in charge of. `nil` if it's not in charge of any map view currently.
 */
- (nullable MKMapView *)mapView;
- (nullable UIViewController<ASMapManagerDelegate> *)delegate;

- (void)takeChargeOfMap:(MKMapView *)mapView
      forViewController:(UIViewController<ASMapManagerDelegate> *)controller
               animated:(BOOL)animated
						 completion:(nullable void (^)(BOOL finished))completion;

- (void)cleanUp:(BOOL)animated
     completion:(nullable void (^)(BOOL finished))completion;

@end

@protocol ASMapManagerDelegate <NSObject>

/**
 * The view controller that the map manager is presented it.
 */
- (UIViewController *)mapManagerPresentingViewController:(ASMapManager *)mapMan;

- (UIEdgeInsets)mapManagerEdgePadding:(ASMapManager *)mapMan;

@optional

- (UIInterfaceOrientation)mapManagerDeviceOrientation:(ASMapManager*) mapMan;

/**
 * Called before something is overlayed over the map, hiding it.
 */
- (void)mapManager:(ASMapManager *)mapMan willHideMapAnimated:(BOOL)animated;

/**
 * Called before the map is being shown again after hiding it.
 */
- (void)mapManager:(ASMapManager *)mapMan willShowMapAnimated:(BOOL)animated;

- (void)mapManager:(ASMapManager *)mapMan didSelectAnnotation:(id<MKAnnotation>)annotation sender:(id)sender;

- (void)mapManager:(ASMapManager *)mapMan regionWillChangeAnimated:(BOOL)animated;
- (void)mapManager:(ASMapManager *)mapMan regionDidChangeAnimated:(BOOL)animated;

- (BOOL)mapManagerIsVisible:(ASMapManager *)mapMan;

- (void)dismissPopoverAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END

