//
//  AMKSimpleSignUpViewController.m
//  TripKit
//
//  Created by Kuan Lun Huang on 26/02/2015.
//
//

#import "AKSignUpViewController.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
#endif

#import "AMKAccountKit.h"

// Model
#import "AMKUser.h"
#import "AMKManager.h"
#import "AMKSection.h"
#import "AKTextFieldItem.h"

// Helper
#import "UIView+Keyboard.h"
#import "NSString+ValidateEmailAddress.h"

@interface AKSignUpViewController ()

@property (nonatomic, assign) BOOL isSigningIn;

// Local data
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *password;


@end

@implementation AKSignUpViewController

- (instancetype)init
{
  self = [super init];
  
  if (self) {
    _isSigningIn = [[AMKUser sharedUser] hasSignedUp];
  }
  
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  if ([self isModal]) {
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithSelector:@selector(cancelButtonPressed:) forController:self];
  }

  self.tableView.tableFooterView = [self footer];
  
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
  tap.cancelsTouchesInView = NO;
  [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self updateTitle];
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
#pragma unused (tableView)
  return section == 1 ? 5 : 0;
}

#pragma mark - Private: Others

- (void)updateTitle
{
  self.title = self.isSigningIn ? Loc.SignIn : Loc.NewAccount;
}

- (void)resetLocalData
{
  self.name = nil;
  self.email = nil;
  self.password = nil;
}

#pragma mark - Private: Textfield

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

#pragma mark - Private: Table footer

- (UIButton *)footer
{
  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  [button setFrame:CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.frame), 44.0f)];
  [button setTitle:[self footerText] forState:UIControlStateNormal];
  [button addTarget:self action:@selector(footerPressed:) forControlEvents:UIControlEventTouchUpInside];
  return button;
}

- (NSString *)footerText
{
  return self.isSigningIn ? Loc.DontHaveAnAccount : Loc.AlreadyHaveAnAccount;
}

- (void)footerPressed:(id)sender
{
#pragma unused (sender)
  [self.view dismissKeyboard];
  
  self.isSigningIn = ! self.isSigningIn;
  _sections = nil;
  [self updateFooterText];
  [self updateTitle];
  [self resetLocalData];
  [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)updateFooterText
{
  if ([self.tableView.tableFooterView isKindOfClass:[UIButton class]]) {
    UIButton *footer = (UIButton *)self.tableView.tableFooterView;
    [footer setTitle:[self footerText] forState:UIControlStateNormal];
  }
}

#pragma mark - User interactions

- (void)cancelButtonPressed:(id)sender
{
#pragma unused(sender)
  
  // Keyboard must be dismissed before dismissing the view or crash
  // occurs.
  [self.view dismissKeyboard];
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissKeyboard:(UITapGestureRecognizer *)tap
{
#pragma unused (tap)
  [self.view dismissKeyboard];
}

#pragma mark - Sign up / Sign in

- (void)trySigninOrSignup
{
  [self validateMandatoryFields:^(BOOL success) {
    if (success) {
      if (self.isSigningIn) {
        [self initiateSignIn];
      } else {
        [self initiateSignUp];
      }
    }
  }];
}

- (void)validateMandatoryFields:(void(^)(BOOL))completion
{
  BOOL success = YES;
  
  // Email.
  if (self.email.length == 0 || ! [self.email isValidEmail]) {
    [self _showAlertForError:nil orWithMessage:Loc.CannotProceedWithoutMail];
    success = NO;
    
  } else if (self.password.length == 0) {
    [self _showAlertForError:nil orWithMessage:Loc.CannotProceedWithoutPassword];
    success = NO;
  }
  
  if (completion) {
    completion(success);
  }
}

- (void)initiateSignIn
{
  [KVNProgress showWithStatus:Loc.SigningIn];
  
  AMKManager *amkManager = [AMKManager sharedInstance];
  
  __weak typeof(self) weakSelf = self;
  [amkManager signinWithEmail:self.email
                     password:self.password
                   completion:
   ^(id object, NSError *error) {
     typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     dispatch_async(dispatch_get_main_queue(), ^{
       [strongSelf parseResponse:object withError:error forExistingAccount:YES];
     });
   }];
}

- (void)initiateSignUp
{
  [KVNProgress showWithStatus:Loc.CreatingAccount];
  
  AMKManager *amkManager = [AMKManager sharedInstance];
  
  __weak typeof(self) weakSelf = self;
  [amkManager signupWithName:self.name
                       email:self.email
                    password:self.password
                  completion:
   ^(id object, NSError *error) {
     typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     dispatch_async(dispatch_get_main_queue(), ^{
       [strongSelf parseResponse:object withError:error forExistingAccount:NO];
     });
   }];
}

- (void)parseResponse:(id)response withError:(NSError *)error forExistingAccount:(BOOL)exisingAccount
{
  if (error != nil) {
    [KVNProgress dismiss];
    [self _showAlertForError:error orWithMessage:nil];
    
  } else if ([response isKindOfClass:[NSString class]]) {
    if ([(NSString *)response isEqualToString:self.email]) {
      [KVNProgress dismiss];
      [self _showAlertForError:nil orWithMessage:Loc.UnknownError];
      
    } else {
      NSString *userToken = (NSString *)response;
      [KVNProgress showSuccessWithCompletion:^{
        AMKUser *user = [AMKUser sharedUser];
        user.token = userToken;
        
        AMKEmail *akEmail;
        if (! exisingAccount) {
          user.name = self.name;
          akEmail = [[AMKEmail alloc] initWithAddress:self.email isPrimary:YES isVerified:NO];
        } else {
          akEmail = [[AMKEmail alloc] initWithAddress:self.email isPrimary:YES isVerified:YES];
        }
        
        if (akEmail != nil) {
          [user setEmails:@[ akEmail ]];
        }
        
        [self.delegate signUpViewController:self didSignUpUser:user];
      }];
    }
  }
}

#pragma mark - Error handling

- (BOOL)_shouldOpenSettingsFromError:(NSError *)error
{
  return error.code == 6;
}

- (void)_showAlertForError:(NSError *)error orWithMessage:(NSString *)message
{
  ZAssert(error != nil || message != nil, @"Need either an error object of a message");
  
  SGActions *alert = [[SGActions alloc] init];
  alert.hasCancel = NO;
  alert.type = UIAlertControllerStyleAlert;
  alert.message = error ? error.localizedDescription : message;
  
  // All alert has "OK" button
  [alert addAction:Loc.OK handler:nil];
  
  // Add a Settings button if needed.
  if (error != nil && [self _shouldOpenSettingsFromError:error]) {
    [alert addAction:Loc.OpenSettings handler:^{
      NSURL *appSettings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
      [[UIApplication sharedApplication] openURL:appSettings options:@{} completionHandler:nil];
    }];
  }
  
  [alert showForSender:nil inController:self];
}

#pragma mark - Overrides

@synthesize sections = _sections;

- (NSArray *)sections
{
  if (! _sections) {
    NSMutableArray *mSections = [NSMutableArray array];
    
    __weak typeof(self) weakSelf = self;
    
    // ------ Personal info section ------
    AMKSection *infoSection = [[AMKSection alloc] init];
    
    AKTextFieldItem *nameItem = [AKTextFieldItem new];
    nameItem.primaryText = Loc.Name;
    nameItem.returnKeyType = UIReturnKeyNext;
    
    __weak typeof(nameItem) weakNameItem = nameItem;
    
    nameItem.didEndEditingBlock = ^(UITextField *textField) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf != nil) {
        strongSelf.name = textField.text;
      }
    };
    
    nameItem.shouldReturnBlock = ^BOOL (UITextField *textField) {
#pragma unused(textField)
      typeof(weakSelf) strongSelf = weakSelf;
      typeof(weakNameItem) strongNameItem = weakNameItem;
      if (strongSelf != nil) {
        [strongSelf moveToTextFieldNextToItem:strongNameItem];
      }
      return YES;
    };
    
    // Email
    AKTextFieldItem *emailItem = [AKTextFieldItem new];
    emailItem.primaryText = Loc.Mail;
    emailItem.keyboardType = UIKeyboardTypeEmailAddress;
    emailItem.returnKeyType = UIReturnKeyNext;
    
    __weak typeof(emailItem) weakEmailItem = emailItem;
    emailItem.didEndEditingBlock = ^(UITextField *textField) {
      typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf != nil) {
        strongSelf.email = textField.text;
      }
    };
    
    emailItem.shouldReturnBlock = ^BOOL (UITextField *textField) {
#pragma unused(textField)
      typeof(weakSelf) strongSelf = weakSelf;
      typeof(weakEmailItem) strongEmailItem = weakEmailItem;
      if (strongSelf != nil) {
        [strongSelf moveToTextFieldNextToItem:strongEmailItem];
      }
      return YES;
    };

    // Password
    AKTextFieldItem *passwordItem = [AKTextFieldItem new];
    passwordItem.primaryText = Loc.Password;
    passwordItem.secureEntry = YES;
    passwordItem.returnKeyType = UIReturnKeyGo;
    
    passwordItem.didEndEditingBlock = ^(UITextField *textField) {
      typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf != nil) {
        strongSelf.password = textField.text;
        [strongSelf trySigninOrSignup];
      }
    };
    
    passwordItem.shouldReturnBlock = ^BOOL (UITextField *textField) {
#pragma unused(textField)
      typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf != nil) {
        strongSelf.password = textField.text;
        [strongSelf.view dismissKeyboard];
      }
      return YES;
    };
    
    if (! self.isSigningIn) { // new account
      [infoSection addItem:nameItem];
      [infoSection addItem:emailItem];
      [infoSection addItem:passwordItem];
    } else { // sign in
      [infoSection addItem:emailItem];
      [infoSection addItem:passwordItem];
    }
    
    [mSections addObject:infoSection];
    
    // ------ Action section ------
    AMKSection *actionSection = [AMKSection new];
    
    AMKItem *actionItem = [AMKItem new];
    actionItem.primaryText = self.isSigningIn ? Loc.SignIn : Loc.SignUp;
    [actionItem addDidSelectHandler:^{
      typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf) {
        [strongSelf.view dismissKeyboard];
        [strongSelf trySigninOrSignup];
        [strongSelf.tableView deselectRowAtIndexPath:strongSelf.lastSelectedIndexPath animated:YES];
      }
    } forActionType:AMKItemActionType_Standard];    
    
    [actionSection addItem:actionItem];
    [mSections addObject:actionSection];
    
    // ---- We have accounted all sections at this point ----
    _sections = mSections;
  }
  
  return _sections;
}

@end
