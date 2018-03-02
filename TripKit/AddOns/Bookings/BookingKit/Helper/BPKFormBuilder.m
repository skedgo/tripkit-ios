//
//  SGBPFormParser.m
//  TripKit
//
//  Created by Brian Huang on 30/01/2015.
//
//

#import "BPKFormBuilder.h"

#ifdef TK_NO_MODULE
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
  reminder.title = Loc.Reminder;
  
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
                                                        title:Loc.ForWhenToLeave
                                                         type:kBPKFormTypeSwitch
                                                  placeholder:nil
                                                        value:@(manager.wantsReminder) // default is want reminder
                                                       kbType:nil
                                                     readOnly:YES]];
}

+ (BPKSectionItem *)reminderHeadwayItemWithManager:(BPKManager *)manager
{
  return [[BPKSectionItem alloc] initWithJson:[self jsonForId:kBPKFormIdHeadway
                                                        title:Loc.MinutesBeforeTrip
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

+ (BPKSection *)sectionForPaypalPayment
{
  BPKSection *section = [[BPKSection alloc] init];
  [section setTitle:@"PayPal"];
  [section addItem:[self commonEmailItem]];
  [section addItem:[self commonPasswordItem]];
  return section;
}

#pragma mark - Common items

+ (BPKSectionItem *)commonEmailItem
{
  NSDictionary *emailJSON = [self jsonForId:kBPKFormIdEmail
                                      title:Loc.Mail
                                       type:kBPKFormTypeString
                                placeholder:Loc.ExampleMail
                                      value:@""
                                     kbType:kBPKKeyboardTypeEmail];
  BPKSectionItem *emailItem = [[BPKSectionItem alloc] initWithJson:emailJSON];
  return emailItem;
}

+ (BPKSectionItem *)commonPasswordItem
{
  NSDictionary *passwordJson = [self jsonForId:kBPKFormIdPassword
                                         title:Loc.Password
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
                                     title:Loc.Name
                                      type:kBPKFormTypeString
                               placeholder:Loc.JohnAppleseed
                                     value:@""
                                    kbType:kBPKKeyboardTypeText];
  BPKSectionItem *nameItem = [[BPKSectionItem alloc] initWithJson:nameJSON];
  return nameItem;
}

@end
