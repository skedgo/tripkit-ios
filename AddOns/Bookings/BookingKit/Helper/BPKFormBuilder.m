//
//  SGBPFormParser.m
//  TripGo
//
//  Created by Brian Huang on 30/01/2015.
//
//

#import "BPKFormBuilder.h"

#ifdef TK_NO_FRAMEWORKS
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#endif


#import "BPKConstants.h"

#import "BPKSection.h"

#import "BPKForm.h"
#import "BPKCost.h"

// Manage reminder
#import "BPKManager.h"

// Verifying data
#import "BPKDataValidator.h"

@implementation BPKFormBuilder

#pragma mark - Booking

+ (NSArray *)buildSectionsFromRawForm:(NSDictionary *)form
{
  NSMutableArray *sections = [NSMutableArray array];
  
  NSArray *elements = [form objectForKey:kBPKForm];
  for (id elementObject in elements) {
    if ([elementObject isKindOfClass:[NSDictionary class]]) {
      NSDictionary *element = (NSDictionary *)elementObject;
      BPKSection *section = [[BPKSection alloc] init];
      
      // section header
      section.title = [element objectForKey:kBPKFormTitle];
      
      // section footer
      NSString *footer = [element objectForKey:kBPKFormFooter];
      if (footer != nil && [footer isEqualToString:@"ok"] == NO) {
        section.footer= [element objectForKey:kBPKFormFooter];
      }
      
      // section items
      NSArray *fields = [element objectForKey:kBPKFormFields];
      for (id fieldObject in fields) {
        if ([fieldObject isKindOfClass:[NSDictionary class]]) {
          NSDictionary *field = (NSDictionary *)fieldObject;
          BPKSectionItem *item = [[BPKSectionItem alloc] initWithJson:field];
          [section addItem:item];
        } else {
          [SGKLog warn:@"BPKFormBuilder" format:@"Server sent form field which isn't a dictionary: %@", fieldObject];
        }
      }
      
      [sections addObject:section];
    } else {
      [SGKLog warn:@"BPKFormBuilder" format:@"Server sent form element which isn't a dictionary: %@", elementObject];
    }
  }
  
  return sections;
}

+ (NSArray *)buildSectionsFromForm:(BPKForm *)form
{
  NSDictionary *rawForm = form.rawForm;
  return [self buildSectionsFromRawForm:rawForm];
}

+ (NSDictionary *)buildFormFromSections:(NSArray *)sections
{
  NSMutableArray *fields = [NSMutableArray array];
  
  NSArray *items = [self itemsInSections:sections];
  
  for (BPKSectionItem *item in items) {
    NSDictionary *aField = [self jsonForItem:item];
    if (aField != nil) {
      [fields addObject:aField];
    } else {
      return nil;
    }
  }
  
  NSDictionary *form = @{ @"input" : fields };
  
  return form;
}

+ (NSArray *)indexPathsForInvalidItemsInSections:(NSArray *)sections
{
  NSMutableArray *indexPaths = [NSMutableArray array];
  
  for (NSUInteger sectionIndex = 0; sectionIndex < sections.count; sectionIndex++) {
    NSArray *items = [self itemsInSections:@[sections[sectionIndex]]];
    for (NSUInteger itemIndex = 0; itemIndex < items.count; itemIndex++) {
      NSDictionary *json = [self jsonForItem:items[itemIndex]];
      if (! json) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:itemIndex inSection:sectionIndex];
        [indexPaths addObject:indexPath];
      }
    }
  }
  
  return indexPaths;
}

#pragma mark - Payment

+ (NSArray *)buildSectionsFromCost:(BPKCost *)cost
{
  NSMutableArray *sections = [NSMutableArray array];
  
  if ([cost acceptCreditCard]) {
    [sections addObject:[self sectionForCreditCardPayment]];
    
    // Receipt section.
    BPKSection *receipt = [self sectionForPaymentReceipt];
    [sections addObject:receipt];
  }
  
  if ([cost acceptPaypal]) {
    [sections addObject:[self sectionForPaypalPayment]];
  }
  
  return sections;
}

#pragma mark - Confirmation

+ (NSArray *)buildReminderSectionWithManager:(BPKManager *)manager
{
  ZAssert(manager != nil, @"Cannot build reminder section without a booking manager");
  
  NSMutableArray *sections = [NSMutableArray array];
  
  BPKSection *reminder = [[BPKSection alloc] init];
  reminder.title = NSLocalizedStringFromTableInBundle(@"Reminder", @"Shared", [SGStyleManager bundle], @"Section title at the end of a booking that allows users to set reminders");
  
  // Add reminder item
  [reminder addItem:[self reminderItemWithManager:manager]];
  
  // Only add headway item if user wants reminder
  if (manager.wantsReminder == YES) {
    [reminder addItem:[self reminderHeadwayItemWithManager:manager]];
  }
  
  [sections addObject:reminder];
  
  return sections;
}

+ (BPKSectionItem *)reminderItemWithManager:(BPKManager *)manager
{
  return [[BPKSectionItem alloc] initWithJson:[self jsonForId:kBPKFormIdReminder
                                                        title:NSLocalizedStringFromTableInBundle(@"For when to leave", @"Shared", [SGStyleManager bundle], @"Option that allows users to indicate whether reminder is needed")
                                                         type:kBPKFormTypeSwitch
                                                  placeholder:nil
                                                        value:@(manager.wantsReminder) // default is want reminder
                                                       kbType:nil
                                                     readOnly:YES]];
}

+ (BPKSectionItem *)reminderHeadwayItemWithManager:(BPKManager *)manager
{
  return [[BPKSectionItem alloc] initWithJson:[self jsonForId:kBPKFormIdHeadway
                                                        title:NSLocalizedStringFromTableInBundle(@"Minutes before trip", @"Shared", [SGStyleManager bundle], @"Option that allows users to indicate how eary to show trip reminder")
                                                         type:kBPKFormTypeStepper
                                                  placeholder:nil
                                                        value:@(manager.reminderHeadway) // default is 3 minutes
                                                     minValue:@(0)
                                                     maxValue:@(100)
                                                       kbType:nil
                                                      readOnly:YES]];
}

#pragma mark - Private: Convert sections to form

+ (NSArray *)itemsInSections:(NSArray *)sections
{
  NSMutableArray *items = [NSMutableArray array];
  
  for (BPKSection *section in sections) {
    for (BPKSectionItem *item in section.items) {
      if (! [item isReadOnly]) {
        [items addObject:item];
      }
    }
  }
  
  return items;
}

+ (NSDictionary *)jsonForItem:(BPKSectionItem *)item
{
  if (! [BPKDataValidator validateItem:item]) {
    return nil;
  }
  
  NSMutableDictionary *json = [NSMutableDictionary dictionary];
  
  NSString *identifier = [item.json objectForKey:kBPKFormId];
  if (identifier != nil) {
    [json setObject:identifier forKey:kBPKFormId];
  }
  
  NSString *type = [item.json objectForKey:kBPKFormType];
  if (type != nil) {
    [json setObject:type forKey:kBPKFormType];
  }
  
  id value = [self valueForItem:item];
  if (value) {
    [json setObject:value forKey:kBPKFormValue];
  } else {
//    ZAssert(false, @"form field must have a value");
  }
  
  return json;
}

+ (id)valueForItem:(BPKSectionItem *)item
{
  return [item.json objectForKey:kBPKFormValue];
}

#pragma mark - Private: client side JSON

+ (NSDictionary *)jsonForId:(NSString *)identifier
                      title:(NSString *)title
                       type:(NSString *)type
                placeholder:(NSString *)placeholder
                      value:(id)value
                     kbType:(NSString *)kbType
{
  ZAssert(identifier && type && title, @"nil value found");
  
  NSMutableDictionary *json = [NSMutableDictionary dictionary];
  [json setObject:identifier forKey:kBPKFormId];
  [json setObject:title forKey:kBPKFormTitle];
  [json setObject:type forKey:kBPKFormType];
  
  if (value != nil) {
    [json setObject:value forKey:kBPKFormValue];
  }
  
  if (placeholder != nil) {
    [json setObject:placeholder forKey:kBPKFormPlaceholder];
  }
  
  if (kbType != nil) {
    [json setObject:kbType forKey:kBPKFormKeyboardType];
  }
  
  return json;
}

+ (NSDictionary *)jsonForId:(NSString *)identifier
                      title:(NSString *)title
                       type:(NSString *)type
                placeholder:(NSString *)placeholder
                      value:(id)value
                     kbType:(NSString *)kbType
                   readOnly:(BOOL)readOnly
{
  NSDictionary *json = [self jsonForId:identifier
                                 title:title
                                  type:type
                           placeholder:placeholder
                                 value:value
                                kbType:kbType];
  
  NSMutableDictionary *mJSON = [[NSMutableDictionary alloc] initWithDictionary:json];
  [mJSON setObject:@(readOnly) forKey:kBPKFormReadOnly];
 
  return mJSON;
}

+ (NSDictionary *)jsonForId:(NSString *)identifier
                      title:(NSString *)title
                       type:(NSString *)type
                placeholder:(NSString *)placeholder
                      value:(id)value
                   minValue:(id)minValue
                   maxValue:(id)maxValue
                     kbType:(NSString *)kbType
                   readOnly:(BOOL)readOnly
{
  if ((minValue != nil || maxValue != nil) && type != kBPKFormTypeStepper) {
    ZAssert(false, @"Only item of STEPPER type can have min or max value");
    return nil;
  }
  
  NSDictionary *json = [self jsonForId:identifier
                                 title:title
                                  type:type
                           placeholder:placeholder
                                 value:value
                                kbType:kbType
                              readOnly:readOnly];
  
  NSMutableDictionary *mJSON = [NSMutableDictionary dictionaryWithDictionary:json];
  if (minValue != nil) {
    [mJSON setObject:minValue forKey:kBPKFormMinValue];
  }
  if (maxValue != nil) {
    [mJSON setObject:maxValue forKey:kBPKFormMaxValue];
  }
  
  return mJSON;
}

#pragma mark - Sections

+ (BPKSection *)sectionForCreditCardPayment
{
  BPKSection *section = [[BPKSection alloc] init];
  section.title = NSLocalizedStringFromTableInBundle(@"Credit card", @"Shared", [SGStyleManager bundle], @"Section title for credit card payment");
  
  // Card number
  NSDictionary *cardNumberJSON = [self jsonForId:kBPKFormIdCardNo
                                           title:NSLocalizedStringFromTableInBundle(@"Card No.", @"Shared", [SGStyleManager bundle], @"Credit card number")
                                            type:kBPKFormTypeString
                                     placeholder:@""
                                           value:@""
                                          kbType:kBPKKeyboardTypeNumber];
  BPKSectionItem *cardNumberItem = [[BPKSectionItem alloc] initWithJson:cardNumberJSON];
  [section addItem:cardNumberItem];
  
  // Expiry date.
  NSDictionary *expiryDateJSON = [self jsonForId:kBPKFormIdExpiryDate
                                           title:NSLocalizedStringFromTableInBundle(@"Expiry Date", @"Shared", [SGStyleManager bundle], @"Credit card expiry date")
                                            type:kBPKFormTypeString
                                     placeholder:NSLocalizedStringFromTableInBundle(@"mm/yy", @"Shared", [SGStyleManager bundle], "Credit card expiry date placeholder, mm/yy")
                                           value:@""
                                          kbType:kBPKKeyboardTypeNumber];
  BPKSectionItem *expiryDateItem = [[BPKSectionItem alloc] initWithJson:expiryDateJSON];
  [section addItem:expiryDateItem];
  
  // CVV.
  NSDictionary *cvvJSON = [self jsonForId:kBPKFormIdCVC
                                    title:NSLocalizedStringFromTableInBundle(@"CVC", @"Shared", [SGStyleManager bundle], @"Credit card CVC")
                                     type:kBPKFormTypeString
                              placeholder:@""
                                    value:@""
                                   kbType:kBPKKeyboardTypeNumber];
  BPKSectionItem *cvvItem = [[BPKSectionItem alloc] initWithJson:cvvJSON];
  [section addItem:cvvItem];
  
  return section;
}

+ (BPKSection *)sectionForPaypalPayment
{
  BPKSection *section = [[BPKSection alloc] init];
  [section setTitle:NSLocalizedStringFromTableInBundle(@"Paypal", @"Shared", [SGStyleManager bundle], @"Section title for Paypal payment")];
  [section addItem:[self commonEmailItem]];
  [section addItem:[self commonPasswordItem]];
  return section;
}

+ (BPKSection *)sectionForPaymentReceipt
{
  BPKSection *section = [[BPKSection alloc] init];
  [section setTitle:NSLocalizedStringFromTableInBundle(@"Receipt", @"Shared", [SGStyleManager bundle], @"Title for section that asks users where payment receipt should be sent")];
  [section addItem:[self commonNameItem]];
  [section addItem:[self commonEmailItem]];
  return section;
}

#pragma mark - Common items

+ (BPKSectionItem *)commonEmailItem
{
  NSDictionary *emailJSON = [self jsonForId:kBPKFormIdEmail
                                      title:NSLocalizedStringFromTableInBundle(@"Email", @"Shared", [SGStyleManager bundle], @"Email address where receipt is sent")
                                       type:kBPKFormTypeString
                                placeholder:NSLocalizedStringFromTableInBundle(@"example@example.com", @"Shared", [SGStyleManager bundle], @"Email placeholder text")
                                      value:@""
                                     kbType:kBPKKeyboardTypeEmail];
  BPKSectionItem *emailItem = [[BPKSectionItem alloc] initWithJson:emailJSON];
  return emailItem;
}

+ (BPKSectionItem *)commonPasswordItem
{
  NSDictionary *passwordJson = [self jsonForId:kBPKFormIdPassword
                                         title:NSLocalizedStringFromTableInBundle(@"Password", @"Shared", [SGStyleManager bundle], nil)
                                          type:kBPKFormTypePassword
                                   placeholder:nil
                                         value:@""
                                        kbType:kBPKKeyboardTypeText];
  BPKSectionItem *passwordItem = [[BPKSectionItem alloc] initWithJson:passwordJson];
  return passwordItem;
}

+ (BPKSectionItem *)commonNameItem
{
  NSDictionary *nameJSON = [self jsonForId:kBPKFormIdName
                                     title:NSLocalizedStringFromTableInBundle(@"Name", @"Shared", [SGStyleManager bundle], @"Name to which receipt is sent")
                                      type:kBPKFormTypeString
                               placeholder:NSLocalizedStringFromTableInBundle(@"John Appleseed", @"Shared", [SGStyleManager bundle], @"Name placeholder text")
                                     value:@""
                                    kbType:kBPKKeyboardTypeText];
  BPKSectionItem *nameItem = [[BPKSectionItem alloc] initWithJson:nameJSON];
  return nameItem;
}

@end
