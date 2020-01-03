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


@class Service, SegmentReference;

NS_ASSUME_NONNULL_BEGIN;

@interface Vehicle : NSManagedObject

// Core Data

@property (nonatomic, retain, nullable) NSNumber * latitude;
@property (nonatomic, retain, nullable) NSNumber * longitude;
@property (nonatomic, retain, nullable) NSDate * lastUpdate;
@property (nonatomic, retain, nullable) NSNumber * bearing;
@property (nonatomic, retain, nullable) NSData * componentsData;
@property (nonatomic, retain, nullable) NSString * label;
@property (nonatomic, retain, nullable) NSString * identifier;
@property (nonatomic, retain, nullable) NSString * icon;
@property (nonatomic, assign) BOOL toDelete;
@property (nonatomic, retain, nullable) Service *service;
@property (nonatomic, retain) NSSet<Service *> *serviceAlternatives;
@property (nonatomic, retain, nullable) SegmentReference *segment;
@property (nonatomic, retain) NSSet<SegmentReference *> *segmentAlternatives;

// Non-persistent

@property (nonatomic, assign) BOOL displayAsPrimary;

- (void)remove;

- (void)setSubtitle:(nullable NSString *)title;

@end

NS_ASSUME_NONNULL_END;
