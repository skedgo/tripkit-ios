//
//  SGUserAccountPasswordViewController.m
//  TripKit
//
//  Created by Brian Huang on 16/12/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

#import "AKPasswordEditViewController.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#endif


#import "AMKAccountKit.h"

@interface AKPasswordEditViewController ()

@property (nonatomic, copy) NSString *current;
@property (nonatomic, copy) NSString *next;
@property (nonatomic, copy) NSString *confirmed;

@property (nonatomic, assign) BOOL isDisappearing;

@end

@implementation AKPasswordEditViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.navigationItem.title = @"Password";
  
  __weak typeof(self) weakSelf = self;
  
  [self showSaveButton:YES
              animated:NO
               handler:
   ^{
     __strong typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     [strongSelf changePassword];
   }];
}

- (void)viewWillDisappear:(BOOL)animated
{
  self.isDisappearing = YES;
  
  [super viewWillDisappear:animated];
}

- (void)dealloc
{
  [SGKLog verbose:NSStringFromClass([self class]) block:^NSString * _Nonnull{
    return [NSString stringWithFormat:@"%@ is dealloc'ed", NSStringFromClass([self class])];
  }];
}

#pragma mark - Private: textfield

- (UITableViewCell *)cellNextToItem:(AMKItem *)item
{
  // The section and row index for the item.
  NSInteger sectionIndex = 0;
  NSInteger rowIndex = 0;
  
  for (NSUInteger i = 0; i < _sections.count; i++) {
    AMKSection *section = _sections[i];
    for (NSUInteger j = 0; j < section.items.count; j++) {
      AMKItem *testItem = section.items[j];
      if (testItem == item) {
        sectionIndex = i;
        rowIndex = j;
        break;
      }
    }
  }
  
  // Index path for the next item.
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndex + 1 inSection:sectionIndex];
  return [self.tableView cellForRowAtIndexPath:indexPath];
}

- (void)moveToTextFieldNextToItem:(AMKItem *)item
{
  UITableViewCell *cell = [self cellNextToItem:item];
  
  if (cell != nil && [cell isKindOfClass:[AKTextFieldCell class]]) {
    [(AKTextFieldCell *)cell makeActive:YES];
  }
}

#pragma mark - Private: editing password

- (void)resetPassword
{
  AMKManager *amkManager = [AMKManager sharedInstance];
  [amkManager resetPassword:nil];
}

- (void)changePassword
{
  if (self.isDisappearing) {
    return;
  }
  
  // Make sure we have valid inputs from user.
  if ([self showAlertIfRequired]) {
    return;
  }

  // Disable the save button while password is being changed.
  self.saveButton.enabled = NO;
  
  AMKManager *akManager = [AMKManager sharedInstance];
  
  [akManager changePasswordFrom:self.current
                             to:self.next
                     completion:
   ^(NSString *newPassword, NSError *error) {
#pragma unused (newPassword)
     self.saveButton.enabled = YES;
     
     if (error) {
       [SGAlert showWithText:error.localizedDescription inController:self];
     } else {
       [KVNProgress showSuccessWithStatus:@"Password changed"
                               completion:
        ^{
          [self performSelector:@selector(popSelfFromStack)
                     withObject:nil
                     afterDelay:0.0f];
        }];
     }
   }];
}

#pragma mark - Private: navigation

- (void)popSelfFromStack
{
  [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Private: alert

- (BOOL)showAlertIfRequired
{
  if (_current.length == 0) {
    [SGAlert showWithText:@"You must enter your current password to save a new one" inController:self];
    return YES;
  }
  
  if (_next.length == 0) {
    [SGAlert showWithText:@"New password is invalid" inController:self];
    return YES;
  }
  
  if (! [_next isEqualToString:_confirmed]) {
    [SGAlert showWithText:@"Passwords do not match" inController:self];
    return YES;
  }
  
  return NO;
}

#pragma mark - AKBaseTableViewController

@synthesize sections = _sections;

- (NSArray *)sections
{
  if (! _sections) {
    NSMutableArray *mSections = [NSMutableArray array];
    
    __weak typeof(self) weakSelf = self;
    
    // ----- Current password -----
    AMKSection *currentSection = [[AMKSection alloc] init];
    
    AKTextFieldItem *currentItem = [AKTextFieldItem new];
    currentItem.primaryText = @"Current password";
    currentItem.secondaryText = _current;
    currentItem.secureEntry = YES;
    currentItem.clearsOnBeginningEditing = YES;
    currentItem.didEndEditingBlock = ^(UITextField *textField) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (! strongSelf) return;
      strongSelf.current = textField.text;
    };
    
    [currentSection addItem:currentItem];
    [mSections addObject:currentSection];

    // ----- New password -----
    AMKSection *newSection = [[AMKSection alloc] init];
    
    AKTextFieldItem *newItem = [AKTextFieldItem new];
    newItem.primaryText = @"New password";
    newItem.secondaryText = _next;
    newItem.secureEntry = YES;
    newItem.clearsOnBeginningEditing = YES;
    newItem.returnKeyType = UIReturnKeyNext;
    
    __weak typeof(newItem) weakNewItem = newItem;
    newItem.shouldReturnBlock = ^BOOL (UITextField *textField) {
#pragma unused(textField)
      __strong typeof(weakSelf) strongSelf = weakSelf;
      __strong typeof(weakNewItem) strongNewItem = weakNewItem;
      if (strongSelf) {
        [strongSelf moveToTextFieldNextToItem:strongNewItem];
      }
      return YES;
    };
    
    newItem.didEndEditingBlock = ^(UITextField *textField) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (! strongSelf) return;
      strongSelf.next = textField.text;
      strongSelf.confirmed = nil;
    };

    AKTextFieldItem *confirmedItem = [AKTextFieldItem new];
    confirmedItem.primaryText = @"Confirm password";
    confirmedItem.secondaryText = _confirmed;
    confirmedItem.secureEntry = YES;
    confirmedItem.clearsOnBeginningEditing = YES;
    confirmedItem.returnKeyType = UIReturnKeyGo;
    confirmedItem.didEndEditingBlock = ^(UITextField *textField) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (! strongSelf) return;
      strongSelf.confirmed = textField.text;
      [strongSelf changePassword];
    };
    
    [newSection addItem:newItem];
    [newSection addItem:confirmedItem];
    [mSections addObject:newSection];
    
    // ----- Reset password -----
//    AMKSection *resetSection = [[AMKSection alloc] init];
//    
//    AMKItem *resetItem = [AMKItem new];
//    resetItem.primaryText = @"Reset password";
//    resetItem.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//    resetItem.selectedBlock = ^{
//      SGKPrepareStrongSelf();
//      [SGKStrongSelf resetPassword];
//    };
//    
//    [resetSection addItem:resetItem];
//    [mSections addObject:resetSection];
    
    _sections = mSections;
  }
  
  return _sections;
}


@end
