//
//  SGUserAccountBaseViewController.h
//  TripKit
//
//  Created by Kuan Lun Huang on 12/12/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

@import UIKit;

// Model
#import "AMKManager.h"

// Item
#import "AMKItem.h"
#import "AKTextFieldItem.h"
#import "AMKSection.h"

// View
#import "AKLabelCell.h"
#import "AKTextFieldCell.h"

@interface AKBaseTableViewController : UITableViewController

@property (nonatomic, strong) NSIndexPath *lastSelectedIndexPath;
@property (nonatomic, copy) NSArray *sections;
@property (nonatomic, strong, readonly) UIBarButtonItem *saveButton;

- (void)configureTableView;
- (void)configureController;
- (void)showSaveButton:(BOOL)show animated:(BOOL)animated handler:(void (^)())handler;

@end
