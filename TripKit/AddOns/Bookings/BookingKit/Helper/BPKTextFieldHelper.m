//
//  BPKTextFieldHelper.m
//  TripKit
//
//  Created by Kuan Lun Huang on 18/05/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "BPKTextFieldHelper.h"

#import "BPKSection.h"

#import "BPKTextFieldCell.h"

#import "TKStyleManager.h"

// user info
#import "BPKUser.h"

@interface BPKTextFieldHelper ()

@property (nonatomic, weak) BPKBookingViewController *form;

@end

@implementation BPKTextFieldHelper

- (instancetype)initWithForm:(BPKBookingViewController *)form
{
  self = [super init];
  
  if (self) {
    _form = form;
  }
  
  return self;
}

#pragma mark - Public methods

- (BOOL (^)(UITextField *))shouldReturnBlockForIndexPath:(NSIndexPath *)indexPath
{
  return ^BOOL(UITextField *textField) {
    NSIndexPath *next = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
    self.willMoveToNext = [self requiresTextFieldCellAtIndexPath:next];
    [textField resignFirstResponder];
    return YES;
  };
}

- (void (^)(UITextField *))didEndEditingBlockForIndexPath:(NSIndexPath *)indexPath
{
  if (! [self requiresTextFieldCellAtIndexPath:indexPath]) {
    return nil;
  }
  
  return ^(UITextField *textField) {
    BOOL valid = YES;
    BPKTextFieldCell *textCell = [self textFieldCellAtIndexPath:indexPath];
    
    BPKSectionItem *item = [self.form itemForIndexPath:indexPath];
    NSIndexPath *next = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
    
    // Validation checks go here
    
    if (valid) {
      [item updateValue:textField.text];
      [self updateUserInfoFromItem:item];
    }
    
    // If a value from the textfield is required, we need to provide visual
    // hint to the user if such value is missing.
    if (item.isRequired && textField.text.length == 0) {
      [textCell highlightPlaceholder:YES];
    }

    if ([self requiresTextFieldCellAtIndexPath:next]) {
      [self moveToTextFieldAtIndexPath:next];
    }
  };
}

#pragma mark - Private: Others

- (void)updateUserInfoFromItem:(BPKSectionItem *)item
{
  BPKUser *user = [BPKUser sharedUser];
  [user updateInfoFromItem:item];
}

- (BPKTextFieldCell *)textFieldCellAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [_form.tableView cellForRowAtIndexPath:indexPath];
  if ([cell isKindOfClass:[BPKTextFieldCell class]]) {
    return (BPKTextFieldCell *)cell;
  } else {
    return nil;
  }
}

- (NSDictionary *)attributesForInvalidString:(BOOL)isInvalid
{
  UIColor *color = isInvalid ? [UIColor redColor] : [TKStyleManager lightTextColor];
  return @{ NSForegroundColorAttributeName : color };
}

- (BOOL)shouldShowKbToolBarForTextField:(UITextField *)textField
{
  UIKeyboardType type = textField.keyboardType;
  return type == UIKeyboardTypePhonePad || type == UIKeyboardTypeNumberPad;
}

#pragma mark - Private: Moving to next textfield

- (BOOL)requiresTextFieldCellAtIndexPath:(NSIndexPath *)indexPath
{
  BPKSectionItem *item = [_form itemForIndexPath:indexPath];
  
  if (item != nil) {
    return [item requiresTextfieldCell];
  } else {
    return NO;
  }
}

- (void)moveToTextFieldAtIndexPath:(NSIndexPath *)indexPath
{
  if (_disableMoveToNextOnReturn) {
    return;
  }
  
  BPKTextFieldCell *textCell = [self textFieldCellAtIndexPath:indexPath];
  if (textCell != nil) {
    [textCell.textField becomeFirstResponder];
  }
}

@end
