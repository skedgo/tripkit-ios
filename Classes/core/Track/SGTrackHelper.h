//
//  SGTrackHelper.h
//  WotGo
//
//  Created by Adrian Schoenig on 20/01/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@protocol SGTrack, SGTrackItem;

/**
 A collection of helper classes for processing and preparing objects that conform to the the `SGTrack` and `SGTrackItem` protocols.
 */
@interface SGTrackHelper : NSObject

/**
 Identifies the time zone that the specified track item takes place. The time zone typically depends on the location that this event starts in.
 
 @param trackItem An object implementing the `SGTrackItem` protocol.
 
 @return Best guess of the time zone or default time zone. Never nil.
 */
+ (NSTimeZone *)timeZoneForTrackItem:(id<SGTrackItem>)trackItem;

/**
 @return Time zone for the track item if it has an annotation or is a 'trip'.
 */
+ (NSTimeZone *)attendanceTimeZoneForTrackItem:(id<SGTrackItem>)trackItem;

/**
 @param trackItem An object implementing the `SGTrackItem` protocol.
 
 @return The title for the track item to display it on a single line.
 */
+ (NSString *)titleForTrackItem:(id<SGTrackItem>)trackItem includingTimes:(BOOL)includeTime;
+ (NSAttributedString *)attributedTitleForTrackItem:(id<SGTrackItem>)trackItem;

/**
 @param trackItem           An object implementing the `SGTrackItem` protocol.
 @param dayComponents       Optional date components for a specific day which will be used for formatting times, e.g., if the track item extends beyond those date components it might only show start/end
 @param relativeTimeZone  Optional time zone, where the track item's time zone will be included in the title if it doesn't match that time zone.
 
 @return The side title (potentially multi-line) to display for this track item respecting the date components
 */
+ (NSAttributedString *)attributedSideTitleForTrackItem:(id<SGTrackItem>)trackItem
                                       forDayComponents:(NSDateComponents *)dayComponents
                                     relativeToTimeZone:(NSTimeZone *)relativeTimeZone;


/**
 The subtitle for the track item to display it on a single line. This is typically the location where this track item takes place.
 
 @param trackItem An object implementing the `SGTrackItem` protocol.
 
 @return A subtitle for the item or `nil`.
 */
+ (NSString *)subtitleForTrackItem:(id<SGTrackItem>)trackItem;
+ (NSAttributedString *)attributedSubtitleForTrackItem:(id<SGTrackItem>)trackItem;

+ (NSString *)timeStringForTrack:(id<SGTrack>)track;

+ (id<MKAnnotation>)originOfTrackItem:(id<SGTrackItem>)trackItem;

+ (id<MKAnnotation>)destinationOfTrackItem:(id<SGTrackItem>)trackItem;

+ (BOOL)trackItemShouldBeIgnored:(id<SGTrackItem>)trackItem;

+ (NSString *)debugDescriptionForTrackItem:(id<SGTrackItem>)trackItem;
+ (NSString *)debugDescriptionForTrackItems:(NSArray<id<SGTrackItem>> *)trackItems;

@end
