//
//  TKCustomEvent.h
//  TripKit
//
//  Created by Kuan Lun Huang on 25/02/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <MapKit/MapKit.h>

#import "TKCustomEventRecurrenceRule.h"

@protocol TKCustomEvent <NSObject>

NS_ASSUME_NONNULL_BEGIN

@property (nonatomic, copy, nullable) NSString *customizableName;

/**
 The start date and time of this event.
 
 @note If the event is recurring, this could be the start date of the currently displayed occurrence.
 */
@property (nonatomic, strong, nullable) NSDate *customizableStartDate;

/**
 The end date.

 @note If the event is recurring, this could be the end date of the currently displayed occurrence.
*/
@property (nonatomic, strong, nullable) NSDate *customizableEndDate;

@optional

/**
 The location for this item.
 */
@property (nonatomic, strong, nullable) id<MKAnnotation> customizableLocation;

/**
 The permissable locations.
 
 @note Each element of the array is an object conforming to MKAnnotation.
 */
@property (nonatomic, copy, nullable) NSArray *customizableLocations;

/**
 A simple recurrence with an end.
 */
@property (nonatomic, strong, nullable) TKCustomEventRecurrenceRule *customizableRecurrenceRule;

/**
 The duration
 */
@property (nonatomic, assign) NSTimeInterval customizableDuration;

@end

NS_ASSUME_NONNULL_END
