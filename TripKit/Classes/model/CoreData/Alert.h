//
//  Alert.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 19/03/13.
//
//

@import CoreData;
@import CoreLocation;

@class TKNamedCoordinate;

typedef NS_CLOSED_ENUM(NSInteger, TKAlertSeverity) {
  TKAlertSeverityInfo = -1,
  TKAlertSeverityWarning = 0,
  TKAlertSeverityAlert = 1,
};

NS_ASSUME_NONNULL_BEGIN

@interface Alert : NSManagedObject

@property (nonatomic, retain, nullable) TKNamedCoordinate *location;
@property (nonatomic, retain) NSNumber * hashCode;
@property (nonatomic, copy, nullable) NSString * title;
@property (nonatomic, retain, nullable) NSString * text;
@property (nonatomic, retain, nullable) NSString * url;
@property (nonatomic, retain, nullable) NSString * remoteIcon;
@property (nonatomic, retain) NSNumber * severity; // Don't access this, use alertSeverity instead
@property (nonatomic, retain, nullable) NSDate * startTime;
@property (nonatomic, retain, nullable) NSDate * endTime;
@property (nonatomic, retain, nullable) NSDictionary<NSString *, id> *action;

@property (nonatomic, retain, nullable) NSString *idService;
@property (nonatomic, retain, nullable) NSString *idStopCode;

// Non core-data properties
@property (nonatomic, assign) TKAlertSeverity alertSeverity;

+ (nullable instancetype)fetchAlertWithHashCode:(NSNumber *)hashCode
                               inTripKitContext:(NSManagedObjectContext *)tripKitContext;

@end

NS_ASSUME_NONNULL_END
