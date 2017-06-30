//
//  SGBPSection.m
//  TripGo
//
//  Created by Brian Huang on 30/01/2015.
//
//

#import "BPKSection.h"

#import "BPKConstants.h"

#import <MapKit/MapKit.h>

@interface BPKSection ()

@property (nonatomic, strong) NSMutableArray *mItems;
@property (nonatomic, strong) NSMutableArray *mVisibleItems;

@end

@implementation BPKSection

- (instancetype)init
{
  self = [super init];
  
  if (self) {
    _mItems = [NSMutableArray array];
    _mVisibleItems = [NSMutableArray array];
  }
  
  return self;
}

- (void)addItem:(BPKSectionItem *)item
{
  [_mItems addObject:item];
  
  if (! [item isHiddenItem]) {
    [_mVisibleItems addObject:item];
  }
}

- (NSArray *)items
{
  return _mItems;
}

- (NSArray *)visibleItems
{
  return _mVisibleItems;
}

- (BPKSectionItem *)bookingStatusItem
{
  for (BPKSectionItem *item in self.items) {
    if ([item isBookingStatusItem]) {
      return item;
    }
  }
  
  return nil;
}

@end

@interface BPKSectionItem ()

@property (nonatomic, strong) NSDictionary *json;

@end

@implementation BPKSectionItem

- (instancetype)initWithJson:(NSDictionary *)json
{
  self = [super init];
  
  if (self) {
    _json = json;
    _extraRowOnSelect = [self isDateItem] ? YES : NO;
    _allowPrefill = YES;
  }
  
  return self;
}

#pragma mark - Custom accessors

- (id)value
{
  if ([self isFormItem]) {
    return _json;
  } else {
    return [_json objectForKey:kBPKFormValue];
  }
}

- (NSArray *)values
{
  return [_json objectForKey:kBPKFormAllValues];
}

- (NSString *)title
{
  return [_json objectForKey:kBPKFormTitle];
}

- (NSNumber *)minValue
{
  return [_json objectForKey:kBPKFormMinValue];
}

- (NSNumber *)maxValue
{
  return [_json objectForKey:kBPKFormMaxValue];
}

- (NSString *)itemId
{
  return [_json objectForKey:kBPKFormId];
}

#pragma mark - Public methods

- (void)updateValue:(id)newValue
{
//  if (! [_json objectForKey:kBPKFormValue]) {
//    return;
//  }
  
  id formatted = [self formattedValue:newValue];
  
  NSMutableDictionary *mJson = [NSMutableDictionary dictionaryWithDictionary:_json];
  [mJson setObject:formatted forKey:kBPKFormValue];
  _json = mJson;
  
  DLog(@"%@", _json);
}

- (BOOL)isReadOnly
{
  return [[_json objectForKey:kBPKFormReadOnly] boolValue];
}

- (BOOL)isRequired
{
  return [[_json objectForKey:kBPKFormRequired] boolValue];
}

#pragma mark - Value formatting

- (id)formattedValue:(id)value
{
  if ([value isKindOfClass:[NSDate class]]) {
    return [self formatDatetime:value];
    
  } else if ([value conformsToProtocol:@protocol(MKAnnotation)]) {
    return [self formatAddress:value];
    
  } else {
    return value;
  }
}

- (NSDictionary *)formatAddress:(id<MKAnnotation>)annotation
{
  NSString *name = [annotation title];
  NSString *address = [annotation subtitle];
  CLLocationCoordinate2D coordinate = [annotation coordinate];
  
  NSDictionary *newValue = @{ kBPKFormName    : name ?: @"",
                              kBPKFormAddress : address ?: @"",
                              kBPKFormLat     : @(coordinate.latitude),
                              kBPKFormLng     : @(coordinate.longitude) };
  
  return newValue;
}

- (NSNumber *)formatDatetime:(NSDate *)datetime
{
  NSTimeInterval since1970 = [datetime timeIntervalSince1970];
  return @(since1970);
}

#pragma mark - Private methods

- (NSString *)itemType
{
  return [_json objectForKey:kBPKFormType];
}

- (NSString *)idType
{
  return [_json objectForKey:kBPKFormId];
}

- (BOOL)isRefreshable
{
  return [[_json objectForKey:kBPKFormRefreshable] boolValue];
}

@end

#pragma mark - Item test category

@implementation BPKSectionItem (ItemTest)

- (BOOL)isRefreshableItem
{
  return [self isRefreshable];
}

- (BOOL)isHiddenItem
{
  return [[_json objectForKey:kBPKFormHidden] boolValue];
}

#pragma mark - Test using type

- (BOOL)isTypeEqualTo:(NSString *)comparisonType
{
  return [[self itemType] caseInsensitiveCompare:comparisonType] == NSOrderedSame;
}

- (BOOL)isFormItem
{
  return [self isTypeEqualTo:kBPKFormTypeBookingForm] || [self isTypeEqualTo:kBPKFormTypePaymentForm];
}

- (BOOL)isAddressItem
{
  return [self isTypeEqualTo:kBPKFormTypeAddress];
}

- (BOOL)isDateItem
{
  return [self isTypeEqualTo:kBPKFormTypeDatetime];
}

- (BOOL)isTimeItem
{
  return [self isTypeEqualTo:kBPKFormTypeTime];
}

- (BOOL)isStepperItem
{
  return [self isTypeEqualTo:kBPKFormTypeStepper];
}

- (BOOL)isOptionItem
{
  return [self isTypeEqualTo:kBPKFormTypeOption];
}

- (BOOL)isStringItem
{
  return [self isTypeEqualTo:kBPKFormTypeString];
}

- (BOOL)isSwitchItem
{
  return [self isTypeEqualTo:kBPKFormTypeSwitch];
}

- (BOOL)isLinkItem
{
  return [self isTypeEqualTo:kBPKFormTypeLink];
}

- (BOOL)isExternalItem
{
  return [self isTypeEqualTo:kBPKFormTypeExternal];
}

- (BOOL)isTextItem
{
  return [self isTypeEqualTo:kBPKFormTypeText];
}

- (BOOL)isPasswordItem
{
  return [self isTypeEqualTo:kBPKFormTypePassword];
}

#pragma mark - Test using id

- (BOOL)isIdTypeEqualTo:(NSString *)comparisonType
{
  return [self idType] != nil && [[self idType] caseInsensitiveCompare:comparisonType] == NSOrderedSame;
}

- (BOOL)isCardNoItem
{
  return [self isIdTypeEqualTo:kBPKFormIdCardNo];
}

- (BOOL)isExpiryDateItem
{
  return [self isIdTypeEqualTo:kBPKFormIdExpiryDate];
}

- (BOOL)isCVCItem
{
  return [self isIdTypeEqualTo:kBPKFormIdCVC];
}

- (BOOL)isCCFirstNameItem
{
  return [self isIdTypeEqualTo:kBPKFormIdCCFirstName];
}

- (BOOL)isCCLastNameItem
{
  return [self isIdTypeEqualTo:kBPKFormIdCCLastName];
}

- (BOOL)isMessageItem
{
  return [self isIdTypeEqualTo:kBPKFormIdMessage];
}

- (BOOL)isReminderItem
{
  return [self isIdTypeEqualTo:kBPKFormIdReminder];
}

- (BOOL)isReminderHeadwayItem
{
  return [self isIdTypeEqualTo:kBPKFormIdHeadway];
}

- (BOOL)isBookingStatusItem
{
  return [self isIdTypeEqualTo:kBPKFormIdBookingStatus];
}

- (BOOL)isPayBookingItem
{
  return [self isIdTypeEqualTo:kBPKFormIdPayBooking];
}

- (BOOL)isCancelBookingItem
{
  return [self isIdTypeEqualTo:kBPKFormIdCancelBooking];
}

- (BOOL)isUpdateBookingItem
{
  return [self isIdTypeEqualTo:kBPKFormIdUpdateBooking];
}

- (BOOL)isNameItem
{
  return [self isIdTypeEqualTo:kBPKFormIdName];
}

- (BOOL)isFirstNameItem
{
  return [self isIdTypeEqualTo:kBPKFormIdFirstName];
}

- (BOOL)isLastNameItem
{
  return [self isIdTypeEqualTo:kBPKFormIdLastName];
}

- (BOOL)isEmailItem
{
  return [self isIdTypeEqualTo:kBPKFormIdEmail];
}

- (BOOL)isBookingTCItem
{
  return [self isIdTypeEqualTo:kBPKFormIdTC];
}

- (BOOL)isInsuranceTCItem
{
  return [self isIdTypeEqualTo:kBPKFormIdInsuranceTC];
}

- (BOOL)isTermsLinkItem
{
  return [self isIdTypeEqualTo:kBPKFormIdTCLink];
}

@end

#pragma mark - External link support category

@implementation BPKSectionItem (ExternalLinkSupport)

- (NSURL *)externalURL
{
  return [NSURL URLWithString:self.value];
}

- (NSURL *)disregardURL
{
  return [NSURL URLWithString:[self.json objectForKey:@"disregardURL"]];
}

- (NSURL *)nextURL
{
  return [NSURL URLWithString:[self.json objectForKey:@"nextURL"]];
}

- (NSString *)nextHUD
{
  return [self.json objectForKey:@"nextHudText"];
}

- (NSString *)externalLinkMessage
{
  return [self.json objectForKey:@"message"];
}

@end

#pragma mark - Cell type category

@implementation BPKSectionItem (CellType)

- (BOOL)requiresLabelCell
{
  BOOL stringItemRequiresLabelCell = ([self isStringItem] && ![self isMessageItem]) && self.isReadOnly;
  return [self isFormItem] || [self isAddressItem] || [self isDateItem] || [self isTimeItem] || [self isOptionItem] || [self isLinkItem] || [self isExternalItem] || stringItemRequiresLabelCell;
}

- (BOOL)requiresStepperCell
{
  return [self isStepperItem];
}

- (BOOL)requiresTextfieldCell
{
//  return ([self isStringItem] && !self.isReadOnly) && ! [self isMessageItem];
  return ([self isStringItem] || [self isPasswordItem]) && self.isReadOnly == NO;
}

- (BOOL)requiresSwitchCell
{
  return [self isSwitchItem];
}

- (BOOL)requiresMessageCell
{
  return [self isMessageItem];
}

- (BOOL)requiresTextCell
{
  return [self isTextItem];
}

@end

#pragma mark - Textfield support category

@implementation BPKSectionItem (TextfieldSupport)

- (BOOL)requiresSecureEntry
{
  return [self isPasswordItem];
}

- (UIKeyboardType)keyboardType
{
  NSString *kbType = [_json objectForKey:kBPKFormKeyboardType];
  
  // Password item isn't a STRING type, hence, doesn't get keyboard type.
  // This is okay as it will simply use the default type.
  if (! [self isPasswordItem] && ! kbType) {
    ZAssert(false, @"The backing JSON has no keyboard type specified");
  }
  
  if ([kbType isEqualToString:kBPKKeyboardTypeText]) {
    return UIKeyboardTypeDefault;
  } else if ([kbType isEqualToString:kBPKKeyboardTypeEmail]) {
    return UIKeyboardTypeEmailAddress;
  } else if ([kbType isEqualToString:kBPKKeyboardTypePhone]) {
    return UIKeyboardTypePhonePad;
  } else if ([kbType isEqualToString:kBPKKeyboardTypeNumber]) {
    return UIKeyboardTypeNumberPad;
  } else if ([kbType isEqualToString:kBPKKeyboardTypeNumPun]) {
    return UIKeyboardTypeNumbersAndPunctuation;
  } else {
    return UIKeyboardTypeDefault;
  }
}

@end
