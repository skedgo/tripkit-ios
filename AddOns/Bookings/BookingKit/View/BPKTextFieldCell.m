//
//  SGPaymentTextFieldCell.m
//  TripKit
//
//  Created by Kuan Lun Huang on 27/01/2015.
//
//

#import "BPKTextFieldCell.h"

#ifdef TK_NO_FRAMEWORKS
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#endif



#import "BPKUser.h"
#import "BPKTextPrefiller.h"

@interface BPKTextFieldCell () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet SGLabel *prompt;

@property (nonatomic, strong) BPKSectionItem *item;

// Textfield delegate blocks
@property (nonatomic, copy) BPKTextFieldNilReturnBlock textFieldDidEndEditingBlock;
@property (nonatomic, copy) BPKTextFieldNilReturnBlock textFieldIsEditingBlock;
@property (nonatomic, copy) BPKTextFieldBoolReturnBlock textFieldShouldReturnBlock;
@property (nonatomic, copy) BPKTextFieldBoolReturnBlock textFieldShouldBeginEditingBlock;

// Input accessory view
@property (nonatomic, copy) NSString *rightKbToolBarItemTitle;
@property (nonatomic, copy) NSString *leftKbToolBarItemTitle;
@property (nonatomic, strong) UIBarButtonItem *rightKbToolBarItem;
@property (nonatomic, strong) UIBarButtonItem *leftKbToolBarItem;

@end

@implementation BPKTextFieldCell

@synthesize didChangeValueHandler;

- (void)prepareForReuse
{
  self.textField.text = nil;
  
  [super prepareForReuse];
}

#pragma mark - BPKFormCell

- (void)configureForItem:(BPKSectionItem *)item
{
  self.item = item;
  
  [self configureForPrompt:[self promptForItem:item]
               placeholder:[self placeholderForItem:item]
                      text:[self textForItem:item]];
  
  UIKeyboardType kbType = [item keyboardType];
  self.textField.keyboardType = kbType;
  
  // Insert accessory view to allow users to move onto
  // next textfield if possible.
  switch (kbType) {
    case UIKeyboardTypeNumberPad:
    case UIKeyboardTypePhonePad:
      [self insertNextKbToolBar];
      break;
      
    default:
      self.textField.inputAccessoryView = nil;
      break;
  }

  // Enable secure entry.
  self.textField.secureTextEntry = [self.item requiresSecureEntry];
}

#pragma mark - BPKTextFieldBlock

- (void)setTextFieldShouldBeginEditingBlock:(BPKTextFieldBoolReturnBlock)block
{
  _textFieldShouldBeginEditingBlock = block;
}

- (void)setTextFieldIsEditingBlock:(BPKTextFieldNilReturnBlock)block
{
  _textFieldIsEditingBlock = block;
}

- (void)setTextFieldShouldReturnBlock:(BPKTextFieldBoolReturnBlock)block
{
  _textFieldShouldReturnBlock = block;
}

- (void)setTextFieldDidEndEditingBlock:(BPKTextFieldNilReturnBlock)block
{
  _textFieldDidEndEditingBlock = block;
}

#pragma mark - Public methods

- (void)configureForPrompt:(NSString *)prompt
               placeholder:(NSString *)placeHolder 
                      text:(NSString *)text
{
  self.prompt.text = prompt;
  self.textField.text = text;
  self.textField.placeholder = placeHolder;
}

- (void)updateText:(NSString *)newText withAttributes:(NSDictionary *)attributes
{
  if (! attributes) {
    self.textField.text = newText;
  } else {
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:newText attributes:attributes];
    self.textField.attributedText = attributed;
  }
}

- (void)updatePlaceholder:(NSString *)newText withAttributes:(NSDictionary *)attributes
{
  if (! attributes) {
    self.textField.placeholder = newText;
  } else {
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:newText attributes:attributes];
    self.textField.attributedPlaceholder = attributed;
  }
}

- (void)insertNextKbToolBar
{
  _rightKbToolBarItemTitle = Loc.Next;
  _leftKbToolBarItemTitle = nil;
  _textField.inputAccessoryView = [self kbToolBar];
}

- (void)insertDoneKbToolBar
{
  _rightKbToolBarItemTitle = Loc.Done;
  _leftKbToolBarItemTitle = nil;
  _textField.inputAccessoryView = [self kbToolBar];
}

- (void)highlightPlaceholder:(BOOL)highlight
{
  NSString *plain = self.textField.placeholder;
  if (! plain) return;
  
  UIColor *color = highlight ? [UIColor redColor] : [UIColor lightGrayColor];
  NSDictionary *attributes = @{NSForegroundColorAttributeName: color};
  [self updatePlaceholder:plain withAttributes:attributes];
}

#pragma mark - Private: Items

- (NSString *)promptForItem:(BPKSectionItem *)item
{
  return [item.json objectForKey:kBPKFormTitle];
}

- (NSString *)placeholderForItem:(BPKSectionItem *)item
{
  NSString *placeholder = [item.json objectForKey:kBPKFormPlaceholder];
  
  if (item.isRequired) {
    if (! placeholder) {
      placeholder = @"*";
    } else {
//      placeholder = [placeholder stringByAppendingString:@"*"];
    }
  }
  
  return placeholder;
}

- (NSString *)textForItem:(BPKSectionItem *)item
{
  NSString *prefillText = [self prefillTextForItem:item];
  if (! prefillText) {
    id value = [item.json objectForKey:kBPKFormValue];
    return [NSString stringWithFormat:@"%@", value];
  } else {
    return prefillText;
  }
}

#pragma mark - Prefill

- (NSString *)prefillTextForItem:(BPKSectionItem *)item
{
  if (! item.allowPrefill) {
    return nil;
  }
  
  NSString *prefillText;
  
#ifdef DEBUG
  NSString *itemId = item.itemId;
  if ([itemId isEqualToString:@"first_name"]) {
    prefillText = @"John";
  } else if ([itemId isEqualToString:@"last_name"]) {
    prefillText = @"Appleseed";
  } else if ([itemId isEqualToString:@"address1"]) {
    prefillText = @"1 infinite loop";
  } else if ([itemId isEqualToString:@"address2"]) {
    prefillText = @"Cupertino";
  } else if ([itemId isEqualToString:@"city"]) {
    prefillText = @"California";
  } else if ([itemId isEqualToString:@"country"]) {
    prefillText = @"USA";
  } else if ([itemId isEqualToString:@"phone_code"]) {
    prefillText = @"1";
  } else if ([itemId isEqualToString:@"phone"]) {
    prefillText = @"+61412345678";
  } else if ([itemId isEqualToString:@"email"]) {
    prefillText = @"brian@skedgo.com";
  }
#endif
  
  if (prefillText == nil) {
    prefillText = [BPKTextPrefiller prefillTextForItem:item];
  }
  
  if (prefillText != nil) {
    [item updateValue:prefillText];
    [[BPKUser sharedUser] updateInfoFromItem:item];
  }
  
  return prefillText;
}

#pragma mark - Private: Input accessory

- (UIToolbar *)kbToolBar
{
  UIToolbar *kbToolBar = [[UIToolbar alloc] init];
  NSMutableArray *toolbarItems = [NSMutableArray arrayWithObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                                               target:nil
                                                                                                               action:nil]];
  if (self.leftKbToolBarItem) {
    [toolbarItems insertObject:self.leftKbToolBarItem atIndex:0];
  }
  if (self.rightKbToolBarItem) {
    [toolbarItems addObject:self.rightKbToolBarItem];
  }
  kbToolBar.items = toolbarItems;
  [kbToolBar sizeToFit];
  
  return kbToolBar;
}

- (UIBarButtonItem *)rightKbToolBarItem
{
  if (! _rightKbToolBarItem) {
    if (_rightKbToolBarItemTitle != nil) {
      _rightKbToolBarItem = [[UIBarButtonItem alloc] initWithTitle:_rightKbToolBarItemTitle
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(rightKbToolBarItemPressed:)];
    } else {
      _rightKbToolBarItem = nil;
    }
  }
  
  return _rightKbToolBarItem;
}

- (UIBarButtonItem *)leftKbToolBarItem
{
  if (! _leftKbToolBarItem) {
    if (_leftKbToolBarItemTitle != nil) {
      _leftKbToolBarItem = [[UIBarButtonItem alloc] initWithTitle:_leftKbToolBarItemTitle
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(leftKbToolBarItemPressed:)];
    } else {
      _leftKbToolBarItem = nil;
    }
  }
  
  return _leftKbToolBarItem;
}

- (void)rightKbToolBarItemPressed:(id)sender
{
#pragma unused (sender)
  [_textField resignFirstResponder];
}

- (void)leftKbToolBarItemPressed:(id)sender
{
#pragma unused (sender)
  [_textField resignFirstResponder];
}

#pragma mark - TextField delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
#pragma unused(textField)
  [self highlightPlaceholder:NO];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
#pragma unused (textField)
  if (_textFieldShouldBeginEditingBlock) {
    return _textFieldShouldBeginEditingBlock(textField);
  } else {
    return YES;
  }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
#pragma unused (range, string)
  if (_textFieldIsEditingBlock != nil) {
    _textFieldIsEditingBlock(textField);
  }
  
  return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
#pragma unused (textField)
  return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
  // as soon as user decides to edit an item, we think that he doesn't
  // need prefilling service anymore.
  self.item.allowPrefill = NO;
  
  if (_textFieldDidEndEditingBlock != nil) {
    _textFieldDidEndEditingBlock(textField);
  }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  if (! _textFieldShouldReturnBlock) {
    [textField resignFirstResponder];
    return YES;
  } else {
    return _textFieldShouldReturnBlock(textField);
  }
}

@end
