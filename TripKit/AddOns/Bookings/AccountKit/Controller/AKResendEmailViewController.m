//
//  SGEmailReminderViewController.m
//  TripKit
//
//  Created by Kuan Lun Huang on 12/12/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

#import "AKResendEmailViewController.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#endif

#import "SGKConstants.h"

#import "AMKAccountKit.h"

#import "AKLabelCell.h"

@interface AKResendEmailViewController ()

@property (nonatomic, strong) NSIndexPath *lastSelectedIndexPath;

@end

@implementation AKResendEmailViewController

- (instancetype)init
{
  self = [self initWithStyle:UITableViewStyleGrouped];
  
  if (self) {
    KVNProgressConfiguration *config = [[KVNProgressConfiguration alloc] init];
    [KVNProgress setConfiguration:config];
  }
  
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  ZAssert(_email != nil, @"Missing email address");
  
  self.navigationItem.title = @"Options";
  
  [self.tableView registerNib:[AKLabelCell nib] forCellReuseIdentifier:[AKLabelCell reuseId]];
}

- (void)dealloc
{
  [TKLog verbose:NSStringFromClass([self class]) block:^NSString * _Nonnull{
    return [NSString stringWithFormat:@"%@ is dealloc'ed", NSStringFromClass([self class])];
  }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#pragma unused(tableView)
  NSArray *emails = [[AMKUser sharedUser] emails];
  return emails.count == 1 ? 1 : 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#pragma unused(tableView, section)
  return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  AKLabelCell *cell = [tableView dequeueReusableCellWithIdentifier:[AKLabelCell reuseId] forIndexPath:indexPath];
  
  if (indexPath.section == 0) {
    [cell configureWithTitle:@"Resend verification email" subtitle:@""];
  } else {
    [cell configureWithTitle:@"Remove this email" subtitle:@""];
    cell.primaryLabel.textColor = [UIColor redColor];
  }
  
  cell.primaryLabel.textAlignment = NSTextAlignmentCenter;
  cell.accessoryType = UITableViewCellAccessoryNone;
  
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
#pragma unused(tableView)
  if (indexPath.section == 0) {
    [self resendVerificationEmail];
  } else {
    [self removeEmail];
  }
  
  _lastSelectedIndexPath = indexPath;
}

#pragma mark - Private methods

- (void)popSelfFromStack
{
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)resendVerificationEmail
{
  AMKManager *amkManager = [AMKManager sharedInstance];
  
  SGKPrepareWeakSelf();
  [amkManager sendVerificationToEmail:_email
                           completion:
   ^(NSString *email, NSError *error) {
#pragma unused(email)
     SGKPrepareStrongSelf();
     
     [SGKStrongSelf.tableView deselectRowAtIndexPath:SGKStrongSelf.lastSelectedIndexPath animated:YES];
     
     if (! error) {
       [KVNProgress showSuccessWithStatus:@"Sent" completion:^{
         [SGKStrongSelf popSelfFromStack];
       }];
     } else {
       [KVNProgress showErrorWithStatus:@"Not sent"];
     }
   }];
}

- (void)removeEmail
{
  AMKManager *amkManager = [AMKManager sharedInstance];
  
  SGKPrepareWeakSelf();
  [amkManager removeEmail:_email
                 password:nil
               completion:
   ^(NSString *email, NSError *error) {
#pragma unused(email)
     SGKPrepareStrongSelf();
    
     if (! error) {
       [KVNProgress showSuccessWithStatus:@"Removed" completion:^{
         [SGKStrongSelf.delegate resendEmailViewControllerDidRemoveEmail];
         [SGKStrongSelf popSelfFromStack];
       }];
     } else {
       [TKAlertController showWithText:error.localizedDescription inController:SGKStrongSelf];
     }
     
     [SGKStrongSelf.tableView deselectRowAtIndexPath:SGKStrongSelf.lastSelectedIndexPath animated:YES];
  }];
}

@end
