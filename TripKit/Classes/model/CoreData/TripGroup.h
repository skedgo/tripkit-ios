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


typedef NS_ENUM(NSInteger, TripGroupVisibility) {
	TripGroupVisibilityFull = 0,
  TripGroupVisibilityMini = 1,
  TripGroupVisibilityHidden = 2,
};

NS_ASSUME_NONNULL_BEGIN

@interface TripGroup : NSManagedObject

@property (nonatomic, strong, nullable) id<NSCoding, NSObject> classification;
@property (nonatomic, strong, nullable) NSNumber * frequency;
@property (nonatomic, strong) NSNumber * flags;
@property (nonatomic, strong, nullable) NSArray<id<NSCoding, NSObject>> *sourcesRaw;
@property (nonatomic, strong) NSNumber * visibilityRaw;
@property (nonatomic, assign) BOOL toDelete;
@property (nonatomic, strong, null_resettable) TripRequest *request;
@property (nonatomic, strong) NSSet *trips;
@property (nonatomic, strong, nullable) Trip *visibleTrip;

// Non-CoreData properties

@property (nonatomic, assign) TripGroupVisibility visibility;

- (void)adjustVisibleTrip;
- (nullable NSDate *)earliestDeparture;

- (NSSet *)usedModeIdentifiers;

- (NSString *)debugString;

#pragma mark - Caches

/**
 A set of 'pairIdentifiers' for public transport segments for quicker timetable look-up.
 
 @see DLSEntry
 */
- (void)setPairIdentifiers:(NSSet<NSString *> *)pairIdentifiers forPublicSegment:(TKSegment *)segment;

- (nullable NSSet<NSString *> *)pairIdentifiersForPublicSegment:(TKSegment *)segment;

#pragma mark - User interaction

@property (nonatomic, assign) BOOL userDidSaveToCalendar;

@end


@interface TripGroup (CoreDataGeneratedAccessors)
- (void)addTripsObject:(Trip *)value;
- (void)removeTripsObject:(Trip *)value;
- (void)addTrips:(NSSet *)values;
- (void)removeTrips:(NSSet *)values;
@end

NS_ASSUME_NONNULL_END
