//
//  SGAgenda.h
//  TripGo
//
//  Created by Adrian Schoenig on 2/04/2014.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 @param startDate The computed start date for the agenda
 @param endDate   The computed end date for the agenda
 @param itemIDs   A sorted list of IDs for the items that should be part of the agenda
 */
typedef void(^TKAgendaInputBuilderTemplate)(NSDate *startDate, NSDate *endDate, NSTimeZone *primaryTimeZone, NSArray *itemIDs);

FOUNDATION_EXPORT NSString *const kTKAgendaInputBuilderTemplateStay;
FOUNDATION_EXPORT NSString *const kTKAgendaInputBuilderTemplatePlaceholder;
FOUNDATION_EXPORT NSString *const kTKAgendaInputBuilderTemplateCurrentLocation;

@interface TKAgendaInputBuilder : NSObject

+ (CLLocationDistance)minimumDistanceToCreateTrips;


/**
 The logic for creating an agenda for a set of source items. It filters out irrelevant entries and inserts stubs for things like 'home', 'work' and so on.
 
 If you have an "effective" start or end times determined by previous Skedgoification, then it's worthwhile to pass these in as the start and end times of everything.
 
 @param items           The list of track items to feed in. Don't need to be ordered but it's faster if they are ordered chronically already.
 @param dateComponents  The date for which to create the agenda, the factory will turn these in dates.
 @param currentLocation The last known `CLLocation` object available
 @param success         Block called on success. This will be called before returning.
 */
//- (void)buildAgendaTemplateForItems:(NSArray<id<TKAgendaInputType>> *)items
//                      withStartDate:(NSDate *)startDate
//                        withEndDate:(NSDate *)endDate
//              limitToDateComponents:(nullable NSDateComponents *)dateComponents
//                     stayCoordinate:(CLLocationCoordinate2D)stayCoordinate
//                       stayTimeZone:(NSTimeZone *)stayTimeZone
//                    currentLocation:(nullable CLLocation *)currentLocation
//                            success:(TKAgendaInputBuilderTemplate)success;
//
///**
// Inserts the new track item at the correct position in the list of existing track items
// 
// @param trackItem Item to insert
// @param items     A mutable list of `SGTrackItem` objects into which the item will be inserted
// */
//+ (void)insertTrackItem:(id<TKAgendaInputType>)trackItem
//              intoItems:(NSMutableArray<id<TKAgendaInputType>> *)items;
//
//+ (BOOL)agendaInputShouldBeIgnored:(id<TKAgendaInputType>)trackItem;
//
//+ (BOOL)trackItem:(id<TKAgendaInputType>)trackItem
// containsLocation:(CLLocation *)location
//           atTime:(NSDate *)time;
//
//+ (BOOL)agendaItems:(NSArray<id<TKAgendaInputType>> *)agendaItems
//    containLocation:(CLLocation *)location
//             atTime:(NSDate *)time;

@end
NS_ASSUME_NONNULL_END
