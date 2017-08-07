//
//  RouteSection.h
//  TripKit
//
//  Created by Adrian Schönig on 3/03/11.
//  Copyright (c) 2011 SkedGo. All rights reserved.
//

@import Foundation;
@import CoreData;
@import MapKit;

#import "SGKCrossPlatform.h"

@class DLSEntry, SegmentReference, Service, Trip, Vehicle, Alert, StopVisits, Shape, SegmentTemplate;
@class SVKRegion, ModeInfo;
@protocol STKDisplayableTimePoint, STKTripSegment;


typedef NS_ENUM(NSInteger, TKSegmentOrdering) {
  TKSegmentOrderingStart   = 1,
  TKSegmentOrderingRegular = 2,
  TKSegmentOrderingEnd     = 4
};

typedef NS_ENUM(NSInteger, TKSegmentWaypoint) {
  TKSegmentWaypointUnknown,
  TKSegmentWaypointGetOn,
  TKSegmentWaypointGetOff
};

typedef NS_ENUM(NSInteger, TKSegmentType) {
  TKSegmentTypeUnknown = 0,
  TKSegmentTypeStationary,
  TKSegmentTypeScheduled,
  TKSegmentTypeUnscheduled,
};

NS_ASSUME_NONNULL_BEGIN

@interface TKSegment : NSObject <MKAnnotation>

@property (nonatomic, strong, nullable) id<MKAnnotation> start;
@property (nonatomic, strong, nullable) id<MKAnnotation> end;

@property (nonatomic, weak, nullable) TKSegment *previous;
@property (nonatomic, weak, nullable) TKSegment *next;

@property (nonatomic, strong, nullable) SegmentReference *reference;
@property (nonatomic, weak, null_resettable) Trip *trip; // practically nonnull, but can be nulled due to weak reference

- (SegmentTemplate *)template;

- (id)initWithReference:(SegmentReference *)aReference
                forTrip:(Trip *)aTrip;

- (id)initAsTerminal:(TKSegmentOrdering)order
             forTrip:(Trip *)aTrip;

/* 
 Various helper methods for quickly getting values and nice strings for various values.
 */
@property (nonatomic, strong, null_unspecified) NSDate *departureTime;
@property (nonatomic, strong, null_unspecified) NSDate *arrivalTime;

- (void)setTitle:(NSString *)title; // just for KVO

/**
 @return The local region this segment starts in. Cannot be international and thus might be nil.
 */
- (nullable SVKRegion *)startRegion;

/**
 @return The local region this segment ends in. Cannot be international and thus might be nil.
 */
- (nullable SVKRegion *)endRegion;

- (TKSegmentOrdering)order;

/**
 Call this when segment properties have changed (such as a trip's time)
 */
- (void)resetCaches;

- (nullable NSSet<Shape *> *)shapes;
- (nullable NSArray<Shape *> *)shortedShapes;

- (nullable NSString *)notes;
- (NSTimeInterval)duration:(BOOL)includingContinuation;
- (NSInteger)templateHashCode;
- (BOOL)isContinuation;
- (BOOL)hasCarParks;
- (BOOL)isPublicTransport;
- (BOOL)hasTimetable;
- (BOOL)isWalking;
- (BOOL)isCycling;
- (BOOL)isDriving;
- (BOOL)isStationary;
- (BOOL)isSelfNavigating;
- (BOOL)isSharedVehicle;
- (BOOL)isAffectedByTraffic;
- (BOOL)isFlight;
- (BOOL)isImpossible;
- (SGKColor *)color;
- (NSArray<NSNumber *> *)dashPattern;
- (BOOL)isCanceled;
- (BOOL)timesAreRealTime;
- (nullable Vehicle *)realTimeVehicle;
- (NSArray <Vehicle *> *)realTimeAlternativeVehicles;

/**
 @return The payload passed on by the server for the specified key.
 */
- (nullable id)payloadForKey:(NSString *)key;


/**
 @return the transport mode identifier that this segment is using (if any). Can return `nil` for stationary segments such as "leave your house" or "wait between two buses" or "park your car"
 */
- (nullable NSString *)modeIdentifier;
- (nullable ModeInfo *)modeInfo;

/**
 @return All alerts for this segment
 */
- (NSArray<Alert *> *)alerts;

/**
 @return Alerts that also have a location associated with them
 */
- (NSArray<Alert *> *)alertsWithLocation;

/**
 @return Alerts that have content, such as a description or URL
 */
- (NSArray<Alert *> *)alertsWithContent;

- (TKSegment *)finalSegmentIncludingContinuation;

- (NSArray<id<MKAnnotation>> *)annotationsToZoomToOnMap;

/*
 A singe line instruction which is used on the map screen.
 */
- (NSString *)singleLineInstruction;

/**
 True if we support a UI to change the location of the segment
 */
- (BOOL)canShowAlternativeLocation;

///-----------------------------------------------------------------------------
/// @name Public transport
///-----------------------------------------------------------------------------

- (nullable NSString *)smsMessage;
- (nullable NSString *)smsNumber;
- (nullable NSString *)scheduledServiceCode;
- (nullable NSString *)scheduledStartStopCode;
- (nullable NSString *)scheduledEndStopCode;
- (nullable NSString *)scheduledServiceNumber;
- (nullable NSNumber *)frequency;
- (nullable Service *)service;
- (nullable NSString *)ticketWebsiteURLString;

- (BOOL)usesVisit:(StopVisits *)visit;
- (BOOL)shouldShowVisit:(StopVisits *)visit;

/**
 Checks if the provided visit matches this segment. This is not just for where the visit is used by this segment, but also for the parts before and after. This call deals with continuations and if the visit is part of a continuation, the visit is still considered to match this segment.
 
 @param visit The visit to match to this segment.
 
 @return If the provided visit is matching this segment.
 */
- (BOOL)matchesVisit:(StopVisits *)visit;

/**
 @param visit The stop visit that the user nominates to switch to.
 @return The best guess of what kind of waypoint it would be when the user decided to switch to `visit`. Anything before the start of this segment is getting on, anything after its end is getting off, in between we return `unknown` if it's in the middle third.
 */
- (TKSegmentWaypoint)guessWaypointTypeForVisit:(StopVisits *)visit;

- (BOOL)fillInTemplates:(NSMutableString *)string
                inTitle:(BOOL)title;

///-----------------------------------------------------------------------------
/// @name In-app and external bookings
///-----------------------------------------------------------------------------

- (nullable NSString *)bookingTitle;
- (nullable NSURL *)bookingInternalURL;
- (nullable NSURL *)bookingQuickInternalURL;
- (nullable NSArray<NSString *> *)bookingExternalActions;
- (nullable NSDictionary<NSString*, id> *)bookingConfirmationDictionary;


///-----------------------------------------------------------------------------
/// @name Watch app temporary storage
///-----------------------------------------------------------------------------

/**
 Temporary storage for the semaphore image that we want to display on the map for the start of this segment. Used by watch app.
 */
@property (nullable, nonatomic, strong) SGKImage *mapImage;

/**
 Temporary storage to mark the active segment, i.e., the segment that the user is on (presumably) and which should be shown immediately to the user.
 */
@property (nonatomic, assign) BOOL isActiveSegment;

///

@property (nullable, readonly) NSString *tripSegmentModeTitle;
@property (nullable, readonly) NSString *tripSegmentModeSubtitle;
@property (nullable, readonly) SGKColor *tripSegmentModeColor;

@end
NS_ASSUME_NONNULL_END
