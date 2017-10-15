//
//  SGUserAccountBaseViewController.m
//  TripKit
//
//  Created by Kuan Lun Huang on 12/12/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

#import "AKBaseTableViewController.h"

#ifdef TK_NO_MODULE
#import "SGKLog.h"
#import <TripKit/TripKit-Swift.h>
#else
@import TripKit;
#import <TripKitBookings/TripKitBookings-Swift.h>
#endif


#import "UIView+Keyboard.h"
#import "UIViewController+modalController.h"
#import "UIBarButtonItem+NavigationBar.h"

@interface AKBaseTableViewController ()

@property (nonatomic, copy) void (^saveButtonHandler)(void);
@property (nonatomic, strong) UIBarButtonItem *saveButton;

@end

@implementation AKBaseTableViewController

- (instancetype)init
{
  self = [self initWithStyle:UITableViewStyleGrouped];
  
  if (self) {
    
  }
  
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  if ([self isModal]) {
    self.navigationItem.leftBarButtonItem = [self closeButton];
  }
  
  [self configureTableView];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didChangePreferredContentSize:) 
                                               name:UIContentSizeCategoryDidChangeNotification
                                             object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  if (self.lastSelectedIndexPath != nil) {
    [self.tableView deselectRowAtIndexPath:self.lastSelectedIndexPath animated:YES];
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
  [self.view dismissKeyboard];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
 
  [SGKLog verbose:NSStringFromClass([self class]) block:^NSString * _Nonnull{
    return [NSString stringWithFormat:@"%@ is dealloc'ed", NSStringFromClass([self class])];
  }];
}

#pragma mark - Public methods

- (void)configureTableView
{
  // Keep previous selection
  self.clearsSelectionOnViewWillAppear = NO;
  
  // Register cells
  [self.tableView registerNib:[AKLabelCell nib]
       forCellReuseIdentifier:[AKLabelCell reuseId]];
  
  [self.tableView registerNib:[AKTextFieldCell nib]
       forCellReuseIdentifier:[AKTextFieldCell reuseId]];
  
  // Dynamic cell height
  self.tableView.rowHeight = UITableViewAutomaticDimension;
  self.tableView.estimatedRowHeight = 60.0f;
}

- (void)configureController
{
//  self.navigationItem.leftBarButtonItem = [self isPresentedModally] ? [self closeButton] : nil;
}

- (void)showSaveButton:(BOOL)show animated:(BOOL)animated handler:(void (^)(void))handler
{
  self.saveButton = show ? [UIBarButtonItem saveButtonWithSelector:@selector(saveButtonPressed:) forController:self] : nil;
  
  [self.navigationItem setRightBarButtonItem:self.saveButton animated:animated];
  
  if (show && handler != nil) {
    self.saveButtonHandler = handler;
  }
}

#pragma mark - Notifications

- (void)didChangePreferredContentSize:(NSNotification *)notification
{
#pragma unused (notification)
  _sections = nil;
  [self.tableView reloadData];
}

#pragma mark - Private helpers

- (UIBarButtonItem *)closeButton
{
  return [UIBarButtonItem closeButtonWithSelector:@selector(closeButtonPressed:) forController:self];
}

- (BOOL)isPresentedModally
{
  return self.navigationController.viewControllers[0] == self;
}

#pragma mark - User interactions

- (void)closeButtonPressed:(id)sender
{
#pragma unused(sender)
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveButtonPressed:(id)sender
{
#pragma unused(sender)
  if (self.saveButtonHandler != nil) {
    [self.view dismissKeyboard];
    self.saveButtonHandler();
  }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#pragma unused(tableView)
  return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#pragma unused(tableView)
  return [self.sections[section] items].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell;
  
  AMKItem *item = [self itemForIndexPath:indexPath];
  
  if ([item isKindOfClass:[AKTextFieldItem class]]) {
    AKTextFieldCell *textFieldCell = [tableView dequeueReusableCellWithIdentifier:[AKTextFieldCell reuseId]
                                                                      forIndexPath:indexPath];
    [self configureTextFieldCell:textFieldCell withItem:item];
    cell = textFieldCell;
    
  } else if ([item isKindOfClass:[AMKItem class]]) {
    AKLabelCell *labelCell = [tableView dequeueReusableCellWithIdentifier:[AKLabelCell reuseId]
                                                              forIndexPath:indexPath];
    [self configureLabelCell:labelCell withItem:item];
    cell = labelCell;
  }
  
  [cell setNeedsUpdateConstraints];
  [cell updateConstraintsIfNeeded];
  
  return cell;
}

#pragma mark - Table view delegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
#pragma unused(tableView)
  return [self.sections[section] headerText];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
#pragma unused(tableView)  
  return [self.sections[section] footerText];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  self.lastSelectedIndexPath = indexPath;
  
  AMKItem *item = [self itemForIndexPath:indexPath];
  
  if ([item isKindOfClass:[AMKItem class]]) {
    if (item.didSelectHandler != nil) {
      item.didSelectHandler();
    } else {
      [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
  } else {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
  }
}

- (AMKItem *)itemForIndexPath:(NSIndexPath *)indexPath
{
  return [self.sections[indexPath.section] items][indexPath.row];
}

@end
