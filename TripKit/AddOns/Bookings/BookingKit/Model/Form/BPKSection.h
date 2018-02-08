//
//  SGBPSection.h
//  TripKit
//
//  Created by Brian Huang on 30/01/2015.
//
//

#import <Foundation/Foundation.h>

@import UIKit;

@class BPKSectionItem;

@interface BPKSection : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *footer;
@property (nonatomic, strong, readonly) NSArray *items;
@property (nonatomic, strong, readonly) NSArray *visibleItems;

- (void)addItem:(BPKSectionItem *)item;

- (BPKSectionItem *)bookingStatusItem;

@end

@interface BPKSectionItem : NSObject

@property (nonatomic, assign) BOOL extraRowOnSelect;
@property (nonatomic, assign) BOOL allowPrefill;

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *itemId;
@property (nonatomic, strong, readonly) NSDictionary *json;
@property (nonatomic, strong, readonly) id value;
@property (nonatomic, strong, readonly) NSArray *values;
@property (nonatomic, strong, readonly) NSNumber *minValue;
@property (nonatomic, strong, readonly) NSNumber *maxValue;
@property (nonatomic, assign, readonly, getter=isReadOnly) BOOL readOnly;
@property (nonatomic, assign, readonly, getter=isRequired) BOOL required;

- (instancetype)initWithJson:(NSDictionary *)json;
- (void)updateValue:(id)newValue;

@end

@interface BPKSectionItem (ItemTest)

- (BOOL)isRefreshableItem;
- (BOOL)isHiddenItem;

// --------------- Test using type ---------------

- (BOOL)isFormItem;
- (BOOL)isAddressItem;
- (BOOL)isDateItem;
- (BOOL)isTimeItem;
- (BOOL)isStepperItem;
- (BOOL)isOptionItem;
- (BOOL)isStringItem;
- (BOOL)isSwitchItem;
- (BOOL)isLinkItem;
- (BOOL)isExternalItem;
- (BOOL)isTextItem;
- (BOOL)isPasswordItem;

// --------------- Test using id ---------------

// Credit card
- (BOOL)isCardNoItem;
- (BOOL)isExpiryDateItem;
- (BOOL)isCVCItem;
- (BOOL)isCCFirstNameItem;
- (BOOL)isCCLastNameItem;

// Confirmation message
- (BOOL)isMessageItem;
- (BOOL)isReminderItem;
- (BOOL)isReminderHeadwayItem;
- (BOOL)isBookingStatusItem;

// Manage bookings
- (BOOL)isPayBookingItem;
- (BOOL)isCancelBookingItem;
- (BOOL)isUpdateBookingItem;

// Receipt, contact
- (BOOL)isNameItem;
- (BOOL)isFirstNameItem;
- (BOOL)isLastNameItem;
- (BOOL)isEmailItem;

// Terms and conditions
- (BOOL)isBookingTCItem;
- (BOOL)isInsuranceTCItem;
- (BOOL)isTermsLinkItem;

@end

@interface BPKSectionItem (ExternalLinkSupport)

- (NSURL *)externalURL;
- (NSURL *)disregardURL;
- (NSURL *)nextURL;
- (NSString *)nextHUD;
- (NSString *)externalLinkMessage;

@end

@interface BPKSectionItem (CellType)

- (BOOL)requiresLabelCell;
- (BOOL)requiresStepperCell;
- (BOOL)requiresTextfieldCell;
- (BOOL)requiresSwitchCell;
- (BOOL)requiresMessageCell;
- (BOOL)requiresTextCell;

@end

@interface BPKSectionItem (TextfieldSupport)

- (BOOL)requiresSecureEntry;
- (UIKeyboardType)keyboardType;

@end
