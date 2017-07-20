//
//  SGBPBaseTableViewController.h
//  TripGo
//
//  Created by Kuan Lun Huang on 4/02/2015.
//
//

#import <UIKit/UIKit.h>

#import "BPKSection.h"

#import "BPKConstants.h"

#import "BPKTableHeader.h"

#import "BPKTextCell.h"
#import "BPKLabelCell.h"
#import "BPKSwitchCell.h"
#import "BPKStepperCell.h"
#import "BPKMessageCell.h"
#import "BPKTextFieldCell.h"
#import "BPKDatePickerCell.h"

// HUD
#import <KVNProgress/KVNProgress.h>

@interface BPKBaseTableViewController : UIViewController <UIGestureRecognizerDelegate>

@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, copy) NSArray *sections;
@property (nonatomic, strong) NSIndexPath *lastSelectedIndexPath;

@property (nonatomic, assign) BOOL enableDynamicType;
@property (nonatomic, assign) BOOL allowTapAnywhereToDismissKeyboard;

@property (nonatomic, strong) KVNProgressConfiguration *HUD;

- (BPKSectionItem *)itemForIndexPath:(NSIndexPath *)indexPath;
- (void)insertOrDeleteExtraRow;

- (void)dismissKeyboardOnTap:(UITapGestureRecognizer *)sender;

- (void)insertHeaderWithTitle:(NSString *)title subtitle:(NSString *)subtitle;
- (void)configureLabelCell:(BPKLabelCell *)cell atIndexPath:(NSIndexPath *)indexPath forItem:(BPKSectionItem *)item;
- (void)configureStepperCell:(BPKStepperCell *)cell atIndexPath:(NSIndexPath *)indexPath forItem:(BPKSectionItem *)item;
- (void)configureDatePickerCell:(BPKDatePickerCell *)cell atIndexPath:(NSIndexPath *)indexPath forItem:(BPKSectionItem *)item;
- (void)configureTextfieldCell:(BPKTextFieldCell *)cell atIndexPath:(NSIndexPath *)indexPath forItem:(BPKSectionItem *)item;
- (void)configureSwitchCell:(BPKSwitchCell *)cell atIndexPath:(NSIndexPath *)indexPath forItem:(BPKSectionItem *)item;
- (void)configureMessageCell:(BPKMessageCell *)cell atIndexPath:(NSIndexPath *)indexPath forItem:(BPKSectionItem *)item;
- (void)configureTextCell:(BPKTextCell *)cell atIndexPath:(NSIndexPath *)indexPath forItem:(BPKSectionItem *)item;

@end
