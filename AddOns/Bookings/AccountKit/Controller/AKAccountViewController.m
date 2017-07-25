//
//  AMKSimpleAccountViewController.m
//  TripKit
//
//  Created by Kuan Lun Huang on 27/02/2015.
//
//

#import "AKAccountViewController.h"

#ifdef TK_NO_FRAMEWORKS
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#endif


#import "AMKAccountKit.h"

#import "AMKItem.h"
#import "AMKSection.h"

#import "AKPasswordEditViewController.h"

@interface AKAccountViewController ()

@property (nonatomic, strong) AMKManager *accountManager;
@property (nonatomic, assign) BOOL shouldFetchAccount;

// Tmp data holders
@property (nonatomic, copy) NSString *name;

@end

@implementation AKAccountViewController

- (void)viewDidLoad
{
  ZAssert(self.user != nil, @"Need a user");
  
  [super viewDidLoad];
  
  self.shouldFetchAccount = YES;
  self.accountManager = [AMKManager sharedInstance];
  
  self.title = NSLocalizedStringFromTableInBundle(@"My account", @"Shared", [SGStyleManager bundle], @"Title for view that shows the summary of a user's account information");
  
  self.refreshControl = [[UIRefreshControl alloc] init];
  [self.refreshControl addTarget:self action:@selector(refetchAccount) forControlEvents:UIControlEventValueChanged];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(signoutOnFailedRenewalNotification:)
                                               name:AMKRenewalFailureNotification
                                             object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  [self validateSignin];
  
  if (self.shouldFetchAccount) {
    [self fetchAccount];
    self.shouldFetchAccount = NO;
  }
}

- (void)dealloc
{
  [SGKLog verbose:NSStringFromClass([self class]) block:^NSString * _Nonnull{
    return [NSString stringWithFormat:@"%@ is dealloc'ed", NSStringFromClass([self class])];
  }];

  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private: Notifications

- (void)signoutOnFailedRenewalNotification:(NSNotification *)notification
{
  NSDictionary *userInfo = notification.userInfo;
  NSError *error = userInfo[AMKAccountErrorKey];
  
  if (error) {
    NSString *message = [error.localizedDescription stringByAppendingString:@" "];
    message = [message stringByAppendingString:NSLocalizedStringFromTableInBundle(@"The app will now sign out", @"Shared", [SGStyleManager bundle], @"")];
    [self presentAlertWithTitle:NSLocalizedStringFromTableInBundle(@"Invalid account", @"Shared", [SGStyleManager bundle], @"")
                        message:message
                      onDismiss:
     ^{
       [self signout];
     }];
  }
}

#pragma mark - Private: Account management

- (void)fetchAccount
{
  [self fetchName];
  [self fetchEmailList];
}

- (void)signout
{
  [KVNProgress showWithStatus:NSLocalizedStringFromTableInBundle(@"Signing out", @"Shared", [SGStyleManager bundle], @"Message that indicates the app is signing users out of their accounts")];
  
  __weak typeof(self) weakSelf = self;
  [self.accountManager signout:^(NSError *error) {
    typeof(weakSelf) strongSelf = weakSelf;
    if (! strongSelf) return;
    
    // Sign out even, if there was an error
    if (error) {
      [SGKLog warn:@"AKAccountVC" format:@"Error during signout: %@", error];
    }
    
    [KVNProgress showSuccessWithStatus:NSLocalizedStringFromTableInBundle(@"Signing out", @"Shared", [SGStyleManager bundle], @"Message that indicates the app has successfully completed signing out")
                            completion:
     ^{
       if ([strongSelf.delegate respondsToSelector:@selector(accountViewControllerDidCompleteSignOut)]) {
         [strongSelf.delegate accountViewControllerDidCompleteSignOut];
       } else {
         [strongSelf.navigationController popViewControllerAnimated:YES];
       }
     }];
  }];
}

- (void)validateSignin
{
  AMKManager *accountManager = [AMKManager sharedInstance];
  
  [accountManager validateSigninWithAutoRenew:YES
                                   completion:
   ^(NSError *error) {
     dispatch_async(dispatch_get_main_queue(), ^{
       if (error) {
         NSString *message = [error.localizedDescription stringByAppendingString:@" "];
         message = [message stringByAppendingString:NSLocalizedStringFromTableInBundle(@"The app will now sign out", @"Shared", [SGStyleManager bundle], @"Message that indicates the app is about to sign users out of their user accounts")];
         [self presentAlertWithTitle:NSLocalizedStringFromTableInBundle(@"Invalid account", @"Shared", [SGStyleManager bundle], @"Title for alert that indicates the user account has become invalid")
                             message:message
                           onDismiss:
          ^{
            [self signout];
          }];
       }
    });
  }];
}

- (void)fetchName
{
  [self.accountManager fetchName:^(id object, NSError *error) {
    if (error) {
      [self presentAlertWithTitle:nil message:error.localizedDescription onDismiss:^{
        if (error.code == 401) {
          // Let's log the user out if the user token is no longer valid.
          [self signout];
        }
      }];
    } else {
      if ([object isKindOfClass:[NSString class]]) {
        self.user.name = object;
        [self setSections:nil];
        [self.tableView reloadData];
      }
    }
  }];
}

- (void)fetchEmailList
{
  [self.accountManager fetchListOfEmails:^(NSArray *emails, NSError *error) {
    if (self.refreshControl.isRefreshing) {
      [self.refreshControl endRefreshing];
    }
    
    if (error != nil) {
      [SGAlert showWithText:error.localizedDescription inController:self];
      
    } else {
      NSMutableArray *akEmails = [NSMutableArray arrayWithCapacity:emails.count];
      for (NSDictionary *email in emails) {
        [akEmails addObject:[[AMKEmail alloc] initWithDictionary:email]];
      }
      
      [self.user setEmails:akEmails];
      [self setSections:nil];
      [self.tableView reloadData];
    }
  }];
}

- (void)updateName
{
  if (! [self isValidString:self.name]) {
    return;
  }
  
  [self.accountManager updateName:self.name
                       completion:
   ^(id object, NSError *error) {
#pragma unused (object)
     if (error) {
       [self presentAlertWithTitle:nil message:error.localizedDescription onDismiss:nil];
     }
   }];
}

#pragma mark - Private: Alerts

- (void)presentAlertWithTitle:(NSString *)title message:(NSString *)message onDismiss:(void(^)())dismiss
{
  SGAlert *alert = [[SGAlert alloc] init];
  [alert showWithTitle:title message:message inController:self dismiss:dismiss];
}

#pragma mark - Private: App flow

- (void)loadPasswordEditor
{
  AKPasswordEditViewController *editor = [[AKPasswordEditViewController alloc] init];
  [self.navigationController pushViewController:editor animated:YES];
}

#pragma mark - Private: Others

- (BOOL)isValidString:(NSString *)string
{
  return string != nil && string.length > 0;
}

#pragma mark - User interactions

- (void)refetchAccount
{
  [self.refreshControl beginRefreshing];
  [self fetchAccount];
}

#pragma mark - Private: Sections

- (nonnull NSArray *)sectionsForSkedGoProfile
{
  __weak typeof(self) weakSelf = self;
  
  NSMutableArray *mSections = [NSMutableArray array];
  
  // ------ Name section ------
  AMKSection *nameSection = [AMKSection new];
  
  AKTextFieldItem *nameItem = [AKTextFieldItem new];
  nameItem.primaryText = NSLocalizedStringFromTableInBundle(@"Name", @"Shared", [SGStyleManager bundle], @"");
  nameItem.secondaryText = self.user.name;
  nameItem.didEndEditingBlock = ^(UITextField *textField) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (! strongSelf) return;
    strongSelf.name = textField.text;
    [strongSelf updateName];
  };
  [nameSection addItem:nameItem];
  
  [mSections addObject:nameSection];
  
  // ------ Email section ------
  AMKSection *emailSection = [AMKSection new];

  AMKEmail *primaryEmail = [self.user primaryEmail];
  
  AMKItem *addressItem = [AMKItem new];
  addressItem.primaryText = NSLocalizedStringFromTableInBundle(@"Email", @"Shared", [SGStyleManager bundle], @"");
  addressItem.secondaryText = primaryEmail.address;
  addressItem.readOnly = YES;
  [emailSection addItem:addressItem];
  
  if (primaryEmail.isVerified) {
    AMKItem *passwordItem = [AMKItem new];
    passwordItem.primaryText = NSLocalizedStringFromTableInBundle(@"Password", @"Shared", [SGStyleManager bundle], @"");
    passwordItem.secondaryText = NSLocalizedStringFromTableInBundle(@"Change", @"Shared", [SGStyleManager bundle], @"Instruction for changing password");
    [passwordItem addDidSelectHandler:^{
      typeof(weakSelf) strongSelf = weakSelf;
      if (! strongSelf) return;
      [strongSelf loadPasswordEditor];
    } forActionType:AMKItemActionType_Standard];
    [emailSection addItem:passwordItem];
  }
 
  if (emailSection.items.count > 0) {
    [mSections addObject:emailSection];
  }
  
  // ----- Action section ------
  [mSections addObject:[self logoutSection]];
  
  return mSections;
}

- (nonnull NSArray *)sectionsForFbkProfile
{
  NSMutableArray *mSections = [NSMutableArray array];
  
  AKFbkProfile *fbkProfile = self.user.facebookProfile;
  ZAssert(fbkProfile != nil, @"Linked with Facebook, but cannot find a valid Facebook profile");
  
  if (fbkProfile != nil) {
    // ------ Basic info section -----
    AMKSection *basicInfo = [AMKSection new];
    
    NSString *fullname = [fbkProfile fullname];
    if ([self isValidString:fullname]) {
      AMKItem *fullnameItem = [[AMKItem alloc] initForExternalAccount];
      fullnameItem.primaryText = NSLocalizedStringFromTableInBundle(@"Name", @"Shared", [SGStyleManager bundle], @"Name used in Facebook");
      fullnameItem.secondaryText = fullname;
      [basicInfo addItem:fullnameItem];
    }
    
    NSString *email = [fbkProfile username];
    if ([self isValidString:email]) {
      AMKItem *emailItem = [[AMKItem alloc] initForExternalAccount];
      emailItem.primaryText = NSLocalizedStringFromTableInBundle(@"Email", @"Shared", [SGStyleManager bundle], @"Email used as Facebook username");
      emailItem.secondaryText = email;
      [basicInfo addItem:emailItem];
    }
    
    AMKItem *sourceItem = [[AMKItem alloc] initForExternalAccount];
    sourceItem.primaryText = NSLocalizedStringFromTableInBundle(@"Authentication", @"Shared", [SGStyleManager bundle], @"Source where the account was derived, e.g., Facebook");
    sourceItem.secondaryText = @"Facebook";
    [basicInfo addItem:sourceItem];
    
    if (basicInfo.items.count > 0) {
      [mSections addObject:basicInfo];
    }
  }
  
  // ------ Action section ------
  [mSections addObject:[self logoutSection]];
  
  return mSections;
}

- (nonnull AMKSection *)logoutSection
{
  __weak typeof(self) weakSelf = self;
  
  AMKSection *signoutSection = [AMKSection new];
  
  AMKItem *signoutItem = [AMKItem new];
  signoutItem.primaryText = NSLocalizedStringFromTableInBundle(@"Sign out", @"Shared", [SGStyleManager bundle], @"Instruction for signing out user account");
  [signoutItem addDidSelectHandler:^{
    typeof(weakSelf) strongSelf = weakSelf;
    if (! strongSelf) return;
    [strongSelf signout];
    [strongSelf.tableView deselectRowAtIndexPath:strongSelf.lastSelectedIndexPath animated:YES];
  } forActionType:AMKItemActionType_Destructive];
  
  [signoutSection addItem:signoutItem];
  
  return signoutSection;
}

#pragma mark - Overrides

@synthesize sections = _sections;

- (NSArray *)sections
{  
  if (! _sections) {
    if (self.user.hasLinkedFacebook) {
      _sections = [self sectionsForFbkProfile];
    } else {
      _sections = [self sectionsForSkedGoProfile];
    }
  }
  
  return _sections;
}

@end
