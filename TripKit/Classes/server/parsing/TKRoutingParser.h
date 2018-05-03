//
//  TKRoutingParser.h
//  TripKit
//
//  Created by Adrian Schoenig on 7/04/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <MapKit/MapKit.h>

@class TripRequest, TripGroup, Trip;

NS_ASSUME_NONNULL_BEGIN

@interface TKRoutingParser : NSObject

- (id)initWithTripKitContext:(NSManagedObjectContext *)context;

- (nullable TripRequest *)parseAndAddResultBlocking:(NSDictionary *)json;

- (void)parseAndAddResult:(NSDictionary *)json
               completion:(void (^)(TripRequest * _Nullable request))completion;

- (void)parseAndAddResult:(NSDictionary *)json
            intoTripGroup:(TripGroup *)tripGroup
                  merging:(BOOL)mergeWithExistingTrips
               completion:(void (^)(NSArray<Trip *> *addedTrips))completion;

- (void)parseAndAddResult:(NSDictionary *)json
               forRequest:(TripRequest *)request
                  merging:(BOOL)mergeWithExistingTrips
               completion:(void (^)(NSArray<Trip *> *addedTrips))completion;

/**
 Parses the specified content and inserts it into the the parser's context.
 
 @note The requests for any of the trips will *not* be populated!
 
 @param keyToTripGroups      The main trip group content in a dictionary from some key to a list of groups. The keys will be respected in the completion block.
 @param segmentTemplatesJson Required segment templates JSON.
 @param alertJson            Optional alerts JSON.
 @param completion           Called on completion from within the parser's managed object context. Will use the keys from `keyToTripGroups`.
 */
- (void)parseAndAddResult:(NSDictionary<id<NSCopying>, NSArray<NSDictionary *> *> *)keyToTripGroups
     withSegmentTemplates:(NSArray<NSDictionary *> *)segmentTemplatesJson
                andAlerts:(nullable NSArray<NSDictionary *> *)alertJson
               completion:(void (^)(NSDictionary *keyToAddedTrips))completion;

- (void)parseJSON:(NSDictionary *)json
     updatingTrip:(Trip *)trip
       completion:(void (^)(Trip *updatedTrip))completion;

@end

NS_ASSUME_NONNULL_END
