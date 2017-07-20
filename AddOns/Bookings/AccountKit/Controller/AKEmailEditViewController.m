//
//  SGUserAccountNewEmailViewController.m
//  WotGo
//
//  Created by Kuan Lun Huang on 15/12/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

#import "AKEmailEditViewController.h"

#ifdef TK_NO_FRAMEWORKS
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#endif

#import "AMKAccountKit.h"

// Configure table view
#import "AMKSection.h"

// Validate email address
#import "NSString+ValidateEmailAddress.h"

typedef NS_ENUM(NSInteger, EmailEditingTypes) {
  EmailEditingTypeAdd = 0,
  EmailEditingTypeRemove,
  EmailEditingTypeMarkPrimary
};

@interface AKEmailEditViewController () <UIAlertViewDelegate>

@property (nonatomic, copy) NSString *address;
@property (nonatomic, copy) NSString *confirmedAddress;

@property (nonatomic, assign) BOOL isNewEmail;

@end

@implementation AKEmailEditViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  if ([self isPresentedModally]) {
    _isNewEmail = YES;
    self.title = @"New email";
    self.navigationItem.leftBarButtonItem = [self cancelButton];
    
    SGKPrepareWeakSelf();
    [self showSaveButton:YES
                animated:NO 
                 handler:
     ^{
       SGKPrepareStrongSelf();
       if ([SGKStrongSelf validateEmailAddress] == NO) {
         return;
       }
      
       AMKUser *user = [AMKUser sharedUser];
       if (! [user primaryEmail].isVerified) {
         [SGKStrongSelf addEmailWithPassword:nil];
       } else {
         [SGKStrongSelf showPasswordAlertForEditingType:EmailEditingTypeAdd];
       }
     }];
  } else {
    self.title = @"Options";
  }
}

#pragma mark - Custom accessors

- (void)setEditedEmail:(NSString *)editedEmail
{
  _editedEmail = editedEmail;
  
  _address = editedEmail;
  _confirmedAddress = _address;
}

#pragma mark - Private methods

- (BOOL)isPresentedModally
{
  return self.navigationController.viewControllers[0] == self;
}

- (UIBarButtonItem *)cancelButton
{
  return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
}

- (BOOL)validateEmailAddress
{
  if (! [_address isValidEmail]) {
    [SGAlert showWithText:@"Invalid email address" inController:self];
    return NO;
    
  } else if (! [_address isEqualToString:_confirmedAddress]) {
    [SGAlert showWithText:@"Email addresses do not match" inController:self];
    return NO;
  }
  
  return YES;
}

- (void)addEmailWithPassword:(NSString *)password
{
  AMKManager *amkManager = [AMKManager sharedInstance];
  
  SGKPrepareWeakSelf();
  [amkManager addEmail:_address
              password:password
            completion:
   ^(NSString *email, NSError *error) {
#pragma unused(email)
     SGKPrepareStrongSelf();
     
     if (! error) {
       [KVNProgress showSuccessWithStatus:@"Email added"
                               completion:
        ^{
          [SGKStrongSelf.delegate emailEditViewControllerDidAddEmail:SGKStrongSelf.address];
          [SGKStrongSelf dismissViewControllerAnimated:YES completion:nil];
        }];
     } else {
       [SGAlert showWithText:error.localizedDescription inController:SGKStrongSelf];
     }
   }];
}

- (void)removeEmailWithPassword:(NSString *)password
{
  AMKManager *amkManager = [AMKManager sharedInstance];
  
  SGKPrepareWeakSelf();
  [amkManager removeEmail:_editedEmail
                 password:password
               completion:
   ^(NSString *email, NSError *error) {
#pragma unused(email)
     SGKPrepareStrongSelf();
     
     if (error != nil) {
       [SGAlert showWithText:error.localizedDescription inController:SGKStrongSelf];
     } else {
       [KVNProgress showSuccessWithStatus:@"Email removed"
                               completion:
        ^{
          if ([SGKStrongSelf.delegate respondsToSelector:@selector(emailEditViewControllerDidRemoveEmail:)]) {
            [SGKStrongSelf.delegate emailEditViewControllerDidRemoveEmail:SGKStrongSelf.editedEmail];
          }
          [SGKStrongSelf.navigationController popViewControllerAnimated:YES];
        }];
     }
   }];
}

- (void)markEmailAsPrimaryWithPassword:(NSString *)password
{
  AMKManager *amkManager = [AMKManager sharedInstance];
  
  SGKPrepareWeakSelf();
  [amkManager markEmailAsPrimary:_editedEmail
                        password:password
                      completion:
   ^(NSString *email, NSError *error) {
#pragma unused(email)
     SGKPrepareStrongSelf();
     
     if (error != nil) {
       [SGAlert showWithText:error.localizedDescription inController:SGKStrongSelf];
     } else {
       [KVNProgress showSuccessWithStatus:@"Primary email updated"
                               completion:
        ^{
          if ([SGKStrongSelf.delegate respondsToSelector:@selector(emailEditViewControllerDidMarkAsPrimary:)]) {
            [SGKStrongSelf.delegate emailEditViewControllerDidMarkAsPrimary:SGKStrongSelf.editedEmail];
          }
          [SGKStrongSelf.navigationController popViewControllerAnimated:YES];
        }];
     }
   }];
}

#pragma mark - User interactions

- (void)cancelButtonPressed:(id)sender
{
#pragma unused(sender)
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Alert

- (void)showPasswordAlertForEditingType:(EmailEditingTypes)type
{
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                  message:@"Please enter your password to make the change"
                                                 delegate:self
                                        cancelButtonTitle:@"Cancel"
                                        otherButtonTitles:@"Done", nil];
  
  alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
  alert.tag = type;
  [alert show];
}

#pragma mark - Alert view delegate

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
  NSString *password = [[alertView textFieldAtIndex:0] text];
  return ! (password.length == 0);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (buttonIndex == 1) {
    if (alertView.tag == EmailEditingTypeAdd) {
      [self addEmailWithPassword:[[alertView textFieldAtIndex:0] text]];
    } else if (alertView.tag == EmailEditingTypeRemove) {
      [self removeEmailWithPassword:[[alertView textFieldAtIndex:0] text]];
    } else if (alertView.tag == EmailEditingTypeMarkPrimary) {
      [self markEmailAsPrimaryWithPassword:[[alertView textFieldAtIndex:0] text]];
    }
  }
}

#pragma mark - SGUserAccountBaseViewController

@synthesize sections = _sections;

- (NSArray *)sections
{
  if (! _sections) {
    NSMutableArray *mSections = [NSMutableArray array];
    
    SGKPrepareWeakSelf();
    
    // ----- Email section -----
    AMKSection *emailSection = [[AMKSection alloc] init];
    
    AKTextFieldItem *addressItem = [AKTextFieldItem new];
    addressItem.primaryText = @"Email";
    addressItem.secondaryText = _address;
    addressItem.enabled = _isNewEmail;
    addressItem.didEndEditingBlock = ^(UITextField *textField) {
      SGKPrepareStrongSelf();
      [SGKStrongSelf setAddress:textField.text];
      [SGKStrongSelf setConfirmedAddress:nil];
      [SGKStrongSelf setSections:nil];
      [SGKStrongSelf.tableView reloadData];
    };
    
    [emailSection addItem:addressItem];

    if (! [_address isEqualToString:_editedEmail]) {
      AKTextFieldItem *confirmedAddressItem = [AKTextFieldItem new];
      confirmedAddressItem.primaryText = @"Confirm Email";
      confirmedAddressItem.didEndEditingBlock = ^(UITextField *textField) {
        SGKPrepareStrongSelf();
        [SGKStrongSelf setConfirmedAddress:textField.text];
      };
      
      [emailSection addItem:confirmedAddressItem];
    }
    
    [mSections addObject:emailSection];
    
    // ----- Mark primary section -----
    AMKUser *user = [AMKUser sharedUser];
    BOOL isPrimary = [_editedEmail isEqualToString:[user primaryEmail].address];
    BOOL isChanged = ! [_editedEmail isEqualToString:_address];
    
    if (! isPrimary && ! _isNewEmail && ! isChanged) {
      AMKSection *markPrimarySection = [[AMKSection alloc] init];
      
      AMKItem *markPrimaryItem = [AMKItem new];
      markPrimaryItem.primaryText = @"Make as primary";
      markPrimaryItem.secondaryText = nil;
      [markPrimaryItem addDidSelectHandler:^{
        SGKPrepareStrongSelf();
        dispatch_async(dispatch_get_main_queue(), ^{
          [SGKStrongSelf showPasswordAlertForEditingType:EmailEditingTypeMarkPrimary];
          [SGKStrongSelf.tableView deselectRowAtIndexPath:SGKStrongSelf.lastSelectedIndexPath animated:YES];
        });
      } forActionType:AMKItemActionType_Standard];
      
      [markPrimarySection addItem:markPrimaryItem];
      [mSections addObject:markPrimarySection];
    }

    // ----- Remove alias section -----
    if (! isPrimary && ! _isNewEmail && ! isChanged) {
      AMKSection *removeEmailSection = [[AMKSection alloc] init];
      
      AMKItem *removeEmailItem = [AMKItem new];
      removeEmailItem.primaryText = @"Remove this email";
      removeEmailItem.secondaryText = nil;
      [removeEmailItem addDidSelectHandler:^{
        SGKPrepareStrongSelf();
        dispatch_async(dispatch_get_main_queue(), ^{
          [SGKStrongSelf showPasswordAlertForEditingType:EmailEditingTypeRemove];
          [SGKStrongSelf.tableView deselectRowAtIndexPath:SGKStrongSelf.lastSelectedIndexPath animated:YES];
        });
      } forActionType:AMKItemActionType_Destructive];
      
      [removeEmailSection addItem:removeEmailItem];      
      [mSections addObject:removeEmailSection];
    }
    
    _sections = mSections;
  }
  
  return _sections;
}


@end
