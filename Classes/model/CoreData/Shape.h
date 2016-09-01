//
//  Shape.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 24/11/12.
//
//

@import Foundation;
@import CoreData;
@import MapKit;
@import SGCoreKit;

@class TKSegment, SegmentTemplate, Service, StopVisits;

@interface Shape : NSManagedObject <STKDisplayableRoute>

@property (nonatomic, retain) NSString * encodedWaypoints;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * friendly;
@property (nonatomic, retain) NSNumber * travelled;
@property (nonatomic, assign) BOOL toDelete;
@property (nonatomic, retain) SegmentTemplate *template;
@property (nonatomic, retain) NSSet *services;
@property (nonatomic, retain) NSSet *visits;

@property (nonatomic, weak) TKSegment *segment;

+ (Shape *)fetchTravelledShapeForTemplate:(SegmentTemplate *)segmentTemplate
                                  atStart:(BOOL)atStart;

- (id<MKAnnotation>)start;
- (id<MKAnnotation>)end;

@end

@interface Shape (CoreDataGeneratedAccessors)

- (void)addServicesObject:(Service *)value;
- (void)removeServicesObject:(Service *)value;
- (void)addServices:(NSSet *)values;
- (void)removeServices:(NSSet *)values;

- (void)addStopVisitsObject:(StopVisits *)value;
- (void)removeStopVisitsObject:(StopVisits *)value;
- (void)addStopVisits:(NSSet *)values;
- (void)removeStopVisits:(NSSet *)values;

@end
