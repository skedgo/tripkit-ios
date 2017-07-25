//
//  SGUserAccountTextFieldCell.m
//  TripKit
//
//  Created by Kuan Lun Huang on 12/12/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

#import "AKTextFieldCell.h"

#ifdef TK_NO_FRAMEWORKS
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#endif


#import "AKTextFieldItem.h"

@interface AKTextFieldCell () <UITextFieldDelegate>

@end

@implementation AKTextFieldCell

@synthesize item = _item;

+ (AKTextFieldCell *)sharedInstance
{
  static AKTextFieldCell *_cell;
  
  static dispatch_once_t onceToken;
  
  dispatch_once(&onceToken, ^{
    _cell = [[self alloc] init];
  });
  
  return _cell;
}

#pragma mark - UITableViewCell

- (void)awakeFromNib
{
  [super awakeFromNib];
  
  self.promptLabel.textColor = [SGStyleManager darkTextColor];
  self.textField.textColor = [SGStyleManager lightTextColor];
}

- (void)prepareForReuse
{
  self.promptLabel.text = nil;
  self.textField.text = nil;
  self.shouldReturnHandler = nil;
  self.didEndEditingHandler = nil;
}

#pragma mark - AKItemCell

- (void)configureForItem:(AMKItem *)item
{
  _item = item;
  
  [self configureForPrompt:item.primaryText placeholder:nil text:item.secondaryText];
  
  if ([item isKindOfClass:[AKTextFieldItem class]]) {
    AKTextFieldItem *textfieldItem = (AKTextFieldItem *)item;
    self.textField.secureTextEntry = textfieldItem.secureEntry;
    self.textField.userInteractionEnabled = textfieldItem.enabled;
    self.textField.keyboardType = textfieldItem.keyboardType;
    self.textField.returnKeyType = textfieldItem.returnKeyType;
    self.textField.enablesReturnKeyAutomatically = YES;
    self.textField.clearsOnBeginEditing = textfieldItem.clearsOnBeginningEditing;
    self.shouldReturnHandler = textfieldItem.shouldReturnBlock;
    self.didEndEditingHandler = textfieldItem.didEndEditingBlock;
  }
}

#pragma mark - Public methods

- (void)configureForPrompt:(NSString *)prompt placeholder:(NSString *)placeholder text:(NSString *)text
{
  self.promptLabel.text = prompt;
  
  self.textField.placeholder = placeholder;
  self.textField.text = text;
}

- (void)makeActive:(BOOL)active
{
  if (active) {
    [self.textField becomeFirstResponder];
  } else {
    [self.textField resignFirstResponder];
  }
}

#pragma mark - TextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  if (self.shouldReturnHandler) {
    // The handle should be dismissing the keyboard.
    return self.shouldReturnHandler(textField);
  }
  
  [self makeActive:NO];
  return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
  if (self.didEndEditingHandler != nil) {
    self.didEndEditingHandler(textField);
  }
}

@end
