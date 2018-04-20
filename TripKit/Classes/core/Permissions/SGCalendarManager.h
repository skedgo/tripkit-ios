//
//  CalendarManager.h
//  TripKit
//
//  Created by Adrian Schönig on 28/10/11.
//  Copyright (c) 2011 SkedGo. All rights reserved.
//

#import <EventKit/EventKit.h>

#import "SGPermissionManager+AuthorizationAlert.h"

NS_ASSUME_NONNULL_BEGIN

@interface SGCalendarManager : SGPermissionManager

+ (SGCalendarManager *)sharedInstance NS_REFINED_FOR_SWIFT;

@property (nonatomic, strong, nullable) EKEventStore *eventStore;

+ (NSString *)titleStringForEvent:(EKEvent *)event;

- (NSArray<EKEvent *> *)fetchEventsMatchingString:(NSString *)string;
  
- (NSArray<EKEvent *> *)fetchEventsBetweenDate:(NSDate *)startDate
                                    andEndDate:(NSDate *)endDate
                                 fromCalendars:(nullable NSArray *)calendarsOrNil;

- (nullable EKEvent *)eventForIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
