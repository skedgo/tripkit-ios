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
@import SkedGoKit;

@class Service, SegmentReference;

@interface Vehicle : NSManagedObject <STKDisplayablePoint>

// Core Data

@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSDate * lastUpdate;
@property (nonatomic, retain) NSNumber * bearing;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * icon;
@property (nonatomic, assign) BOOL toDelete;
@property (nonatomic, retain) Service *service;
@property (nonatomic, retain) NSSet *serviceAlternatives;
@property (nonatomic, retain) SegmentReference *segment;
@property (nonatomic, retain) NSSet *segmentAlternatives;

// Non-persistent

@property (nonatomic, assign) BOOL displayAsPrimary;

+ (void)removeOrphansFromManagedObjectContext:(NSManagedObjectContext *)context;

- (void)remove;

- (NSString *)serviceNumber;

- (UIColor *)serviceColor;

- (void)setSubtitle:(NSString *)title;

- (CGFloat)ageFactor;

@end
