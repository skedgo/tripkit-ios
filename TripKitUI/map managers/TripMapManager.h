//
//  TripMapManager.h
//  Pods
//
//  Created by Adrian Schoenig on 7/09/2016.
//
//

#import <TripKitUI/TripKitUI.h>

@import TripKit;

NS_ASSUME_NONNULL_BEGIN

@interface TripMapManager : RouteMapManager

@property (nonatomic, strong, nullable) Trip * trip;
@property (nonatomic, strong) NSArray<Alert *>* alerts;
@property (nonatomic, assign) BOOL enableRealTimeUpdates;
@property (nonatomic, assign) BOOL forceZoom;

- (void)showSegment:(TKSegment *)segment animated:(BOOL)animated;

- (void)showRoute:(Trip *)newTrip animated:(BOOL)animated;

- (void)reloadCurrentTrip;

- (void)selectAlert:(Alert *)alert;

- (nullable TKSegment *)segmentForAlert:(Alert *)alert;

- (void)kickOffRealTimeUpdates:(BOOL)animated;

- (void)realTimeUpdateForTrip:(Trip *)theTrip animated:(BOOL)animated;

/// For subclasses

@property (readonly) TKBuzzInfoProvider *infoProvider;

@end

NS_ASSUME_NONNULL_END
