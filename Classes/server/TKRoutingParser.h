//
//  TKRoutingParser.h
//  TripGo
//
//  Created by Adrian Schoenig on 7/04/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <MapKit/MapKit.h>

@class TripRequest, TripGroup, Trip;

@interface TKRoutingParser : NSObject

- (id)initWithTripKitContext:(NSManagedObjectContext *)context;

- (TripRequest *)parseAndAddResultBlocking:(NSDictionary *)json;

- (void)parseAndAddResult:(NSDictionary *)json
               completion:(void (^)(TripRequest *request))completion;

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
                andAlerts:(NSArray<NSDictionary *> *)alertJson
               completion:(void (^)(NSDictionary *keyToAddedTrips))completion;

- (void)parseJSON:(NSDictionary *)json
     updatingTrip:(Trip *)trip
       completion:(void (^)(Trip *updatedTrip))completion;

/**
 Helper method to fill in a request wich the specified location. Typically used on requests that were created as part of a previous call to `parseAndAddResult`. All parameters except `request` are optional.
 
 @return If the request was populated successfully. This fails if the request has no trips.
 */
+ (BOOL)populateRequestWithTripInformation:(TripRequest *)request
                              fromLocation:(id<MKAnnotation>)fromOrNil
                                toLocation:(id<MKAnnotation>)toOrNil
                                leaveAfter:(NSDate *)leaveAfter
                                  arriveBy:(NSDate *)arriveBy;
@end
