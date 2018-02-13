//
//  BPKForm.h
//  TripKit
//
//  Created by Kuan Lun Huang on 3/06/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BPKSectionItem;

@interface BPKForm : NSObject

@property (nonnull, nonatomic, strong, readonly) NSDictionary *rawForm;

@property (nullable, nonatomic, copy, readonly) NSString *title;
@property (nullable, nonatomic, copy, readonly) NSString *subtitle;

@property (nonatomic, assign, readonly) BOOL isBookingForm;
@property (nonatomic, assign, readonly) BOOL isPaymentForm;
@property (nonatomic, assign, readonly) BOOL isLast;
@property (nonatomic, assign, readonly) BOOL isValid;
@property (nonatomic, assign, readonly) BOOL isCancelled;

+ (BOOL)canBuildFormFromRawObject:(nonnull NSDictionary *)rawForm;

- (nonnull instancetype)initWithJSON:(nonnull NSDictionary *)json;

// Getting form items
- (nullable BPKSectionItem *)updateBookingItem;

// Action
- (BOOL)hasAction;
- (BOOL)isActionEnabled;
- (BOOL)isActionBooking;
- (nullable NSString *)actionTitle;
- (nullable NSURL *)actionURL;
- (nullable NSString *)actionText;

// Refreshing form
- (BOOL)isRefreshable;
- (nullable NSURL *)refreshURL;

// External URL
- (BOOL)shoudLoadExternalLinkAutomatically;
- (nullable BPKSectionItem *)externalItem;

// Refreshing source object (think: trip)
- (nullable NSURL *)refreshURLForSourceObject;

@end

@interface BPKForm (Payment)

- (nullable NSDictionary *)paymentJSON;

@end
