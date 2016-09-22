//
//  TripGroup.h
//  TripGo
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


@interface TripGroup : NSManagedObject

@property (nonatomic, strong) id<NSCoding, NSObject> classification;
@property (nonatomic, strong) NSNumber * frequency;
@property (nonatomic, strong) NSNumber * flags;
@property (nonatomic, strong) NSNumber * visibilityRaw;
@property (nonatomic, assign) BOOL toDelete;
@property (nonatomic, strong) TripRequest *request;
@property (nonatomic, strong) NSSet *trips;
@property (nonatomic, strong) Trip *visibleTrip;

@property (nonatomic, assign) TripGroupVisibility visibility;

- (void)adjustVisibleTrip;
- (NSDate *)earliestDeparture;

- (NSSet *)usedModeIdentifiers;

- (NSString *)debugString;

#pragma mark - Caches

/**
 A set of 'pairIdentifiers' for public transport segments for quicker timetable look-up.
 
 @see DLSEntry
 */
- (void)setPairIdentifiers:(NSSet *)pairIdentifiers forPublicSegment:(TKSegment *)segment;

- (NSSet *)pairIdentifiersForPublicSegment:(TKSegment *)segment;

#pragma mark - User interaction

@property (nonatomic, assign) BOOL userDidSaveToCalendar;

@end


@interface TripGroup (CoreDataGeneratedAccessors)
- (void)addTripsObject:(Trip *)value;
- (void)removeTripsObject:(Trip *)value;
- (void)addTrips:(NSSet *)values;
- (void)removeTrips:(NSSet *)values;
@end
