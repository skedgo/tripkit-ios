//
//  BaseSegment.h
//  TripGo
//
//  Created by Adrian Schönig on 9/05/12.
//  Copyright (c) 2012 SkedGo. All rights reserved.
//
// The BaseSegment class keeps all the time-independent and unordered information about a segment.
//
// It is meant to be used as a template for creating "full" Segment objects which also have
// time information and a sense of ordering.
//

#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>

#define kBHSegmentModeContinuation  @"[cont]"
#define kBHSegmentModeParking				@"parking"
#define kBHSegmentModePlane         @"aeroplane"

@class SegmentReference, Shape;
@class ModeInfo, STKMiniInstruction;

@interface SegmentTemplate : NSManagedObject

@property (nonatomic, strong) NSString * action;
@property (nonatomic, strong) NSNumber * bearing;
@property (nonatomic, strong) id data; // NSData (or NSDictionary)
@property (nonatomic, strong) NSNumber * flags;
@property (nonatomic, retain) NSNumber * durationWithoutTraffic;
@property (nonatomic, strong) id endLocation;
@property (nonatomic, strong) NSString * modeIdentifier;
@property (nonatomic, strong) NSString * notesRaw;
@property (nonatomic, strong) NSString * scheduledStartStopCode;
@property (nonatomic, strong) NSString * scheduledEndStopCode;
@property (nonatomic, strong) NSString * smsMessage;
@property (nonatomic, strong) NSString * smsNumber;
@property (nonatomic, strong) NSNumber * segmentType;
@property (nonatomic, strong) id startLocation;
@property (nonatomic, strong) NSNumber * visibility;
@property (nonatomic, strong) NSNumber * hashCode;
@property (nonatomic, assign) BOOL toDelete;
@property (nonatomic, strong) NSSet *references;

/*
 Shapes define a sequence of waypoints. A segment can have a couple of those,
 e.g., a number of streets, or a bus line for which only a part is travelled along.
 */
@property (nonatomic, strong) NSSet *shapes;

+ (BOOL)segmentTemplateHashCode:(NSNumber *)hashCode
         existsInTripKitContext:(NSManagedObjectContext *)tripKitContext;

+ (instancetype)fetchSegmentTemplateWithHashCode:(NSNumber *)hashCode
                                inTripKitContext:(NSManagedObjectContext *)tripKitContext;

/* 
 Either first or last waypoint
 @deprecated
 */
- (id<MKAnnotation>)endWaypoint:(BOOL)atStart;

- (BOOL)isPublicTransport;
- (BOOL)isWalking;
- (BOOL)isCycling;
- (BOOL)isDriving;
- (BOOL)isStationary;
- (BOOL)isSelfNavigating;
- (BOOL)isSharedVehicle;
- (BOOL)isFlight;

- (NSArray<NSNumber *> *)dashPattern;

@property (nonatomic, strong) NSString *disclaimer;

@property (nonatomic, strong) ModeInfo *modeInfo;

@property (nonatomic, strong) STKMiniInstruction *miniInstruction;

@property (nonatomic, assign) BOOL hasCarParks;
@property (nonatomic, assign, getter=isContinuation) BOOL continuation;

@end

@interface SegmentTemplate (CoreDataGeneratedAccessors)

- (void)addShapeObject:(Shape *)value;
- (void)removeShapeObject:(Shape *)value;
- (void)addShapes:(NSSet *)values;
- (void)removeShapes:(NSSet *)values;

- (void)addReferencesObject:(SegmentReference *)value;
- (void)removeReferencesObject:(SegmentReference *)value;
- (void)addReferences:(NSSet *)values;
- (void)removeReferences:(NSSet *)values;


@end

