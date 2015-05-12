//
//  Alert.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 19/03/13.
//
//

#import <CoreData/CoreData.h>

#import "STKTransportKit.h"

@class Service, StopLocation, SGNamedCoordinate;

@interface Alert : NSManagedObject <STKDisplayablePoint>

@property (nonatomic, retain) SGNamedCoordinate *location;
@property (nonatomic, retain) NSNumber * hashCode;
@property (nonatomic, copy) NSString * title;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * severity; // higher the more severe
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSDate * endTime;
@property (nonatomic, assign) BOOL toDelete;

@property (nonatomic, retain) NSString *idService;
@property (nonatomic, retain) NSString *idStopCode;

+ (instancetype)fetchAlertWithHashCode:(NSNumber *)hashCode
                      inTripKitContext:(NSManagedObjectContext *)tripKitContext;

+ (NSArray *)fetchAlertsWithHashCodes:(NSArray *)hashCodes
                     inTripKitContext:(NSManagedObjectContext *)tripKitContext
                 sortedByDistanceFrom:(CLLocationCoordinate2D)coordinate;

+ (NSArray *)fetchAlertsForService:(Service *)service;

+ (NSArray *)fetchAlertsForStopLocation:(StopLocation *)stopLocation;

- (STKInfoIconType)infoIconType;

- (void)remove;

@end

