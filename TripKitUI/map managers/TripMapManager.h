//
//  TripMapManager.h
//  TripKit
//
//  Created by Adrian Schoenig on 7/09/2016.
//
//

#import "RouteMapManager.h"

NS_ASSUME_NONNULL_BEGIN

@class Trip, Alert, TKSegment, TKBuzzInfoProvider;

@interface TripMapManager : RouteMapManager

@property (nonatomic, strong, nullable) Trip * trip;
@property (nonatomic, strong) NSArray<Alert *>* alerts;
@property (nonatomic, assign) BOOL forceZoom;

- (void)showSegment:(TKSegment *)segment animated:(BOOL)animated;

- (void)showRoute:(Trip *)newTrip animated:(BOOL)animated;

- (void)reloadCurrentTrip;

- (void)selectAlert:(Alert *)alert;

- (nullable TKSegment *)segmentForAlert:(Alert *)alert;

- (void)realTimeUpdateForTrip:(Trip *)theTrip animated:(BOOL)animated;

/// For subclasses

@property (readonly) TKBuzzInfoProvider *infoProvider;

@end

NS_ASSUME_NONNULL_END
