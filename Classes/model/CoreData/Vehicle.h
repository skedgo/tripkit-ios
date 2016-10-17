//
//  Vehicle.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 1/11/12.
//
//

@import Foundation;
@import CoreData;
@import MapKit;
@import SGCoreKit;

@class Service, SegmentReference;

@interface Vehicle : NSManagedObject

// Core Data

@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * occupancyRaw;
@property (nonatomic, retain, nullable) NSDate * lastUpdate;
@property (nonatomic, retain) NSNumber * bearing;
@property (nonatomic, retain, nullable) NSString * label;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * icon;
@property (nonatomic, assign) BOOL toDelete;
@property (nonatomic, retain, nullable) Service *service;
@property (nonatomic, retain) NSSet<Service *> *serviceAlternatives;
@property (nonatomic, retain, nullable) SegmentReference *segment;
@property (nonatomic, retain) NSSet<SegmentReference *> *segmentAlternatives;

// Non-persistent

@property (nonatomic, assign) BOOL displayAsPrimary;

+ (void)removeOrphansFromManagedObjectContext:(NSManagedObjectContext *)context;

- (void)remove;

- (void)setSubtitle:(NSString *)title;

@end
