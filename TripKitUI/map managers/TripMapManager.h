//
//  TripMapManager.h
//  Pods
//
//  Created by Adrian Schoenig on 7/09/2016.
//
//

#import <TripKitUI/TripKitUI.h>

@import TripKit;

@interface TripMapManager : RouteMapManager

@property (nonatomic, strong) Trip * trip;
@property (nonatomic, strong) NSArray<Alert *>* alerts;
@property (nonatomic, assign) BOOL enableRealTimeUpdates;
@property (nonatomic, assign) BOOL forceZoom;

- (void)showSegment:(TKSegment *)segment animated:(BOOL)animated;

- (void)showRoute:(Trip *)newTrip animated:(BOOL)animated;

- (void)reloadCurrentTrip;

- (void)selectAlert:(Alert *)alert;

- (TKSegment *)segmentForAlert:(Alert *)alert;

- (void)kickOffRealTimeUpdates:(BOOL)animated;

- (void)realTimeUpdateForTrip:(Trip *)theTrip animated:(BOOL)animated;

@end
