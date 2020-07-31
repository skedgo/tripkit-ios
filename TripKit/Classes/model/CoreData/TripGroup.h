//
//  TripGroup.h
//  TripKit
//
//  Created by Adrian Schönig on 16/04/12.
//  Copyright (c) 2012 SkedGo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Trip, TripRequest;
@class DLSEntry, TKSegment;


typedef NS_CLOSED_ENUM(NSInteger, TKTripGroupVisibility) {
	TKTripGroupVisibilityFull = 0,
  TKTripGroupVisibilityMini = 1,
  TKTripGroupVisibilityHidden = 2,
};

NS_ASSUME_NONNULL_BEGIN

@interface TripGroup : NSManagedObject

@property (nonatomic, strong, nullable) NSString * classification;
@property (nonatomic, strong, nullable) NSNumber * frequency;

/// :nodoc:
@property (nonatomic, strong) NSNumber * flags;

/// :nodoc:
@property (nonatomic, strong, nullable) NSArray<id<NSCoding, NSObject>> *sourcesRaw;

/// :nodoc:
@property (nonatomic, strong) NSNumber * visibilityRaw;

@property (nonatomic, strong, null_resettable) TripRequest *request;
@property (nonatomic, strong) NSSet<Trip *> *trips;
@property (nonatomic, strong, nullable) Trip *visibleTrip;

// Non-CoreData properties

@property (nonatomic, assign) TKTripGroupVisibility visibility;

/// :nodoc:
- (void)adjustVisibleTrip;

- (nullable NSDate *)earliestDeparture;

- (NSSet<NSString *> *)usedModeIdentifiers;

/// :nodoc:
- (NSString *)debugString;

#pragma mark - Caches

/**
 A set of 'pairIdentifiers' for public transport segments for quicker timetable look-up.
 
 @see DLSEntry
 */
- (void)setPairIdentifiers:(NSSet<NSString *> *)pairIdentifiers forPublicSegment:(TKSegment *)segment;

- (nullable NSSet<NSString *> *)pairIdentifiersForPublicSegment:(TKSegment *)segment;

#pragma mark - User interaction

/// :nodoc:
@property (nonatomic, assign) BOOL userDidSaveToCalendar;

@end


/// :nodoc:
@interface TripGroup (CoreDataGeneratedAccessors)
- (void)addTripsObject:(Trip *)value;
- (void)removeTripsObject:(Trip *)value;
- (void)addTrips:(NSSet *)values;
- (void)removeTrips:(NSSet *)values;
@end

NS_ASSUME_NONNULL_END
