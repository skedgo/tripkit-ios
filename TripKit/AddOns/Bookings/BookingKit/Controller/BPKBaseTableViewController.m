//
//  SGBPBaseTableViewController.m
//  TripKit
//
//  Created by Kuan Lun Huang on 4/02/2015.
//
//

#import "BPKBaseTableViewController.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#endif

#import "UIView+Keyboard.h"

@interface BPKBaseTableViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, assign) BOOL extraRowInserted;
@property (nonatomic, strong) NSIndexPath *insertedIndexPath;

@property (nonatomic, strong) UITapGestureRecognizer *tapAnywhereGesture;

// These are the off-screen cells that are used to calculate heights.
@property (nonatomic, strong) BPKTextCell *sizingTextCell;
@property (nonatomic, strong) BPKLabelCell *sizingLabelCell;
@property (nonatomic, strong) BPKSwitchCell *sizingSwitchCell;
@property (nonatomic, strong) BPKStepperCell *sizingStepperCell;
@property (nonatomic, strong) BPKMessageCell *sizingMessageCell;
@property (nonatomic, strong) BPKTextFieldCell *sizingTextfieldCell;
@property (nonatomic, strong) BPKDatePickerCell *sizingDatePickerCell;

@end

@implementation BPKBaseTableViewController

- (instancetype)init
{
  self = [super init];
  
  if (self) {
    _enableDynamicType = YES;
  }
  
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.edgesForExtendedLayout = UIRectEdgeNone;
  
  [self insertTableView];
  
//  if (_enableDynamicType) {
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(respondToChangeInContentSizeCategory:)
//                                                 name:UIContentSizeCategoryDidChangeNotification
//                                               object:nil];
//  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
  // Hide any active HUD
  [KVNProgress dismiss];
  
  if (self.extraRowInserted) {
    self.extraRowInserted = NO;
    [self deleteExtraRow];
  }
}

- (void)dealloc
{
  [TKLog verbose:NSStringFromClass([self class]) block:^NSString * _Nonnull{
    return [NSString stringWithFormat:@"%@ is dealloc'ed", NSStringFromClass([self class])];
  }];
}

#pragma mark - Custom accessors

- (void)setAllowTapAnywhereToDismissKeyboard:(BOOL)allow
{
  _allowTapAnywhereToDismissKeyboard = allow;
  
  if (allow) {
    if (! _tapAnywhereGesture) {
      UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboardOnTap:)];
      tap.cancelsTouchesInView = NO;
      tap.numberOfTapsRequired = 1;
      tap.delegate = self;
      [self.view addGestureRecognizer:tap];
    }
  } else {
    if (_tapAnywhereGesture) {
      [self.view removeGestureRecognizer:_tapAnywhereGesture];
      _tapAnywhereGesture = nil;
    }
  }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#pragma unused (tableView)
  return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#pragma unused (tableView)
  
  BPKSection *aSection = self.sections[section];
  NSInteger base = aSection.visibleItems.count;
  
  if ([self isLastSelectedSection:section]) {
    BPKSectionItem *item = [self itemForIndexPath:self.lastSelectedIndexPath];
    if (item != nil && item.extraRowOnSelect) {
      return self.extraRowInserted ? base + 1 : base;
    } else {
      return base;
    }
  } else {
    return base;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell;
  
  NSString *reuseId = @"bookingCell";
  
  if ([self isIndexPathForDatePicker:indexPath]) {
    BPKDatePickerCell *datePickerCell = [tableView dequeueReusableCellWithIdentifier:[BPKDatePickerCell reuseId] forIndexPath:indexPath];
    BPKSectionItem *associatedDateItem = [self itemForIndexPath:[NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section]];
    [self configureDatePickerCell:datePickerCell
                      atIndexPath:indexPath
                          forItem:associatedDateItem];
    cell = datePickerCell;
    
  } else {
    BPKSectionItem *item = [self itemForIndexPath:indexPath];
    
    if ([item requiresLabelCell]) {
      BPKLabelCell *labelCell = [tableView dequeueReusableCellWithIdentifier:[BPKLabelCell reuseId] forIndexPath:indexPath];
      [self configureLabelCell:labelCell atIndexPath:indexPath forItem:item];
      cell = labelCell;
      
    } else if ([item requiresStepperCell]) {
      BPKStepperCell *stepperCell = [tableView dequeueReusableCellWithIdentifier:[BPKStepperCell reuseId] forIndexPath:indexPath];
      [self configureStepperCell:stepperCell atIndexPath:indexPath forItem:item];
      cell = stepperCell;
      
    } else if ([item requiresTextfieldCell]) {
      BPKTextFieldCell *textfieldCell = [tableView dequeueReusableCellWithIdentifier:[BPKTextFieldCell reuseId] forIndexPath:indexPath];
      [self configureTextfieldCell:textfieldCell atIndexPath:indexPath forItem:item];
      cell = textfieldCell;
      
    } else if ([item requiresSwitchCell]) {
      BPKSwitchCell *switchCell = [tableView dequeueReusableCellWithIdentifier:[BPKSwitchCell reuseId] forIndexPath:indexPath];
      [self configureSwitchCell:switchCell atIndexPath:indexPath forItem:item];
      cell = switchCell;
      
    } else if ([item requiresMessageCell]) {
      BPKMessageCell *messageCell = [tableView dequeueReusableCellWithIdentifier:[BPKMessageCell reuseId] forIndexPath:indexPath];
      [self configureMessageCell:messageCell atIndexPath:indexPath forItem:item];
      cell = messageCell;
      
    } else if ([item requiresTextCell]) {
      BPKTextCell *textCell = [tableView dequeueReusableCellWithIdentifier:[BPKTextCell reuseId] forIndexPath:indexPath];
      [self configureTextCell:textCell atIndexPath:indexPath forItem:item];
      cell = textCell;
      
    } else {
      cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
      if (! cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
      }
      NSString *title = [item.json objectForKey:kBPKFormTitle];
      NSString *type = [item.json objectForKey:kBPKFormType];
      cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", title, type];
      cell.textLabel.font = [UIFont systemFontOfSize:14];
    }
  }
  
  [cell setNeedsUpdateConstraints];
  [cell updateConstraintsIfNeeded];
  
  return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
#pragma unused(tableView)
  if (self.sections.count == 0) {
    return nil;
  }
  
  return [self.sections[section] title];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
#pragma unused(tableView)
  if (self.sections.count == 0) {
    return nil;
  }
  
  return [self.sections[section] footer];
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *sizingCell = [self sizingCellForIndexPath:indexPath];
  
  if (sizingCell) {
    [sizingCell setNeedsUpdateConstraints];
    [sizingCell updateConstraintsIfNeeded];
    
    sizingCell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(sizingCell.bounds));
    
    [sizingCell setNeedsLayout];
    [sizingCell layoutIfNeeded];
    
    CGFloat height = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    return height + 1;
    
  } else {
    return 44.0f;
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView beginUpdates];
  
  if (! [self isLastSelectedIndexPath:indexPath]) {
    if (self.extraRowInserted) {
      self.extraRowInserted = NO;
      [self deleteExtraRow];
    }
  }
  
  self.lastSelectedIndexPath = indexPath;
  
  BPKCell *cell = (BPKCell *)[tableView cellForRowAtIndexPath:indexPath];
  [self performActionOnSelectedCell:cell];
  
  [tableView endUpdates];
  
  // We need this to fix the issue of disappearing separator.
  [tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Public methods

- (void)insertTableView
{
  _tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
  _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _tableView.dataSource = self;
  _tableView.delegate = self;
  [self.view addSubview:_tableView];
  
  [self.tableView registerNib:[BPKLabelCell nib]
       forCellReuseIdentifier:[BPKLabelCell reuseId]];
  
  [self.tableView registerNib:[BPKStepperCell nib]
       forCellReuseIdentifier:[BPKStepperCell reuseId]];
  
  [self.tableView registerNib:[BPKDatePickerCell nib]
       forCellReuseIdentifier:[BPKDatePickerCell reuseId]];
  
  [self.tableView registerNib:[BPKTextFieldCell nib]
       forCellReuseIdentifier:[BPKTextFieldCell reuseId]];
  
  [self.tableView registerNib:[BPKSwitchCell nib]
       forCellReuseIdentifier:[BPKSwitchCell reuseId]];
  
  [self.tableView registerNib:[BPKMessageCell nib]
       forCellReuseIdentifier:[BPKMessageCell reuseId]];
  
  [self.tableView registerNib:[BPKTextCell nib]
       forCellReuseIdentifier:[BPKTextCell reuseId]];
}

- (BPKSectionItem *)itemForIndexPath:(NSIndexPath *)indexPath
{
  if (self.insertedIndexPath != nil && self.insertedIndexPath.section == indexPath.section) {
    if (indexPath.row > self.insertedIndexPath.row) {
      return [self.sections[indexPath.section] visibleItems][indexPath.row - 1];
    }
  }
  
  if ((NSUInteger)indexPath.row >= [self.sections[indexPath.section] visibleItems].count) {
    return nil;
  } else {
    return [self.sections[indexPath.section] visibleItems][indexPath.row];
  }
}

- (void)insertOrDeleteExtraRow
{
  self.extraRowInserted = ! self.extraRowInserted;
  
  if (self.extraRowInserted) {
    [self insertExtraRow];
  } else {
    [self deleteExtraRow];
  }
}

- (void)dismissKeyboardOnTap:(UITapGestureRecognizer *)sender
{
#pragma unused (sender)
  [self.view dismissKeyboard];
}

- (void)insertHeaderWithTitle:(NSString *)title subtitle:(NSString *)subtitle
{
  BPKTableHeader *header = [[BPKTableHeader alloc] initWithTitle:title subtitle:subtitle tableView:self.tableView];
  header.backgroundColor = [TKStyleManager globalTintColor];
  self.tableView.tableHeaderView = header;
}

- (void)configureLabelCell:(BPKLabelCell *)cell atIndexPath:(NSIndexPath *)indexPath forItem:(BPKSectionItem *)item
{
#pragma unused (indexPath)
  [cell configureForItem:item];
}

- (void)configureStepperCell:(BPKStepperCell *)cell atIndexPath:(NSIndexPath *)indexPath forItem:(BPKSectionItem *)item
{
#pragma unused (indexPath)
  [cell configureForItem:item];
}

- (void)configureDatePickerCell:(BPKDatePickerCell *)cell atIndexPath:(NSIndexPath *)indexPath forItem:(BPKSectionItem *)item
{
#pragma unused (indexPath)
  [cell configureForItem:item];
}

- (void)configureTextfieldCell:(BPKTextFieldCell *)cell atIndexPath:(NSIndexPath *)indexPath forItem:(BPKSectionItem *)item
{
#pragma unused (indexPath)
  [cell configureForItem:item];
}

- (void)configureSwitchCell:(BPKSwitchCell *)cell atIndexPath:(NSIndexPath *)indexPath forItem:(BPKSectionItem *)item
{
#pragma unused (indexPath)
  [cell configureForItem:item];
}

- (void)configureMessageCell:(BPKMessageCell *)cell atIndexPath:(NSIndexPath *)indexPath forItem:(BPKSectionItem *)item
{
#pragma unused (indexPath)  
  [cell configureForItem:item];
}

- (void)configureTextCell:(BPKTextCell *)cell atIndexPath:(NSIndexPath *)indexPath forItem:(BPKSectionItem *)item
{
#pragma unused (indexPath)
  [cell configureForItem:item];
}

#pragma mark - Private methods

- (void)performActionOnSelectedCell:(BPKCell *)cell
{
  if ([cell isKindOfClass:[BPKLabelCell class]]) {
    NSIndexPath *ip = [self.tableView indexPathForCell:cell];
    BPKSectionItem *item = [self itemForIndexPath:ip];
    
    BPKLabelCell *labelCell = (BPKLabelCell *)cell;
    if (labelCell.didSelectHandler) {
      labelCell.didSelectHandler(item);
    }
  }
}

#pragma mark - Private: notifications

- (void)respondToChangeInContentSizeCategory:(NSNotification *)notification
{
#pragma unused (notification)
  [self.view setNeedsLayout];
  [self.view layoutIfNeeded];
  
  [self.tableView reloadData];
}

#pragma mark - Sizing cell

- (BPKCell *)sizingCellForIndexPath:(NSIndexPath *)indexPath
{
  if ([self isIndexPathForDatePicker:indexPath]) {
    return self.sizingDatePickerCell;
    
  } else {
    BPKSectionItem *item = [self itemForIndexPath:indexPath];
    
    if ([item requiresLabelCell]) {
      [self configureLabelCell:self.sizingLabelCell atIndexPath:indexPath forItem:item];
      return self.sizingLabelCell;
      
    } else if ([item requiresStepperCell]) {
      [self configureStepperCell:self.sizingStepperCell atIndexPath:indexPath forItem:item];
      return self.sizingStepperCell;
      
    } else if ([item requiresSwitchCell]) {
      [self configureSwitchCell:self.sizingSwitchCell atIndexPath:indexPath forItem:item];
      return self.sizingSwitchCell;
      
    } else if ([item requiresTextfieldCell]) {
      [self configureTextfieldCell:self.sizingTextfieldCell atIndexPath:indexPath forItem:item];
      return self.sizingTextfieldCell;
      
    } else if ([item requiresTextCell]) {
      [self configureTextCell:self.sizingTextCell atIndexPath:indexPath forItem:item];
      return self.sizingTextCell;
      
    } else if ([item requiresMessageCell]) {
      [self configureMessageCell:self.sizingMessageCell atIndexPath:indexPath forItem:item];
      return self.sizingMessageCell;
      
    } else {
      return nil;
    }
  }
}

- (BPKLabelCell *)sizingLabelCell
{
  if (! _sizingLabelCell) {
    _sizingLabelCell = (BPKLabelCell *)[self loadCellFromClass:[BPKLabelCell class]];
  }
  
  return _sizingLabelCell;
}

- (BPKStepperCell *)sizingStepperCell
{
  if (! _sizingStepperCell) {
    _sizingStepperCell = (BPKStepperCell *)[self loadCellFromClass:[BPKStepperCell class]];
  }
  return _sizingStepperCell;
}

- (BPKSwitchCell *)sizingSwitchCell
{
  if (! _sizingSwitchCell) {
    _sizingSwitchCell = (BPKSwitchCell *)[self loadCellFromClass:[BPKSwitchCell class]];
  }
  return _sizingSwitchCell;
}

- (BPKTextFieldCell *)sizingTextfieldCell
{
  if (! _sizingTextfieldCell) {
    _sizingTextfieldCell = (BPKTextFieldCell *)[self loadCellFromClass:[BPKTextFieldCell class]];
  }
  return _sizingTextfieldCell;
}

- (BPKTextCell *)sizingTextCell
{
  if (! _sizingTextCell) {
    _sizingTextCell = (BPKTextCell *)[self loadCellFromClass:[BPKTextCell class]];
  }
  return _sizingTextCell;
}

- (BPKMessageCell *)sizingMessageCell
{
  if (! _sizingMessageCell) {
    _sizingMessageCell = (BPKMessageCell *)[self loadCellFromClass:[BPKMessageCell class]];
  }
  return _sizingMessageCell;
}

- (BPKDatePickerCell *)sizingDatePickerCell
{
  if (! _sizingDatePickerCell) {
    _sizingDatePickerCell = (BPKDatePickerCell *)[self loadCellFromClass:[BPKDatePickerCell class]];
  }
  return _sizingDatePickerCell;
}

- (UITableViewCell *)loadCellFromClass:(Class)aClass
{
  return [[NSBundle bundleForClass:aClass] loadNibNamed:NSStringFromClass(aClass) owner:nil options:nil].firstObject;
}

#pragma mark - Lazy accessors

- (KVNProgressConfiguration *)HUD
{
  if (! _HUD) {
    _HUD = [[KVNProgressConfiguration alloc] init];
    [KVNProgress setConfiguration:_HUD];
  }
  
  return _HUD;
}

#pragma mark - Dynamic loading/unloading date picker

- (BOOL)isIndexPathForDatePicker:(NSIndexPath *)indexPath
{
  if (! self.lastSelectedIndexPath) {
    return NO;
  }

  BOOL isUsedForExtraRow = NO;
  if (self.insertedIndexPath != nil) {
    isUsedForExtraRow = indexPath.row == self.lastSelectedIndexPath.row + 1;
  }
  
  BPKSectionItem *lastSelectedItem = [self itemForIndexPath:self.lastSelectedIndexPath];
  BOOL isLastSelectedItemForDate = [lastSelectedItem isDateItem];
  
  return isUsedForExtraRow && isLastSelectedItemForDate;
}

- (BOOL)isLastSelectedSection:(NSInteger)section
{
  return self.lastSelectedIndexPath != nil && self.lastSelectedIndexPath.section == section;
}

- (BOOL)isLastSelectedIndexPath:(NSIndexPath *)indexPath
{
  return [self.lastSelectedIndexPath compare:indexPath] == NSOrderedSame;
}

- (NSIndexPath *)indexPathForExtraRow
{
  NSInteger section = self.lastSelectedIndexPath.section;
  NSInteger row = self.lastSelectedIndexPath.row + 1;
  NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
  return newIndexPath;
}

- (NSIndexPath *)insertExtraRow
{
  NSIndexPath *newIndexPath = [self indexPathForExtraRow];
  self.insertedIndexPath = newIndexPath;
  [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ] withRowAnimation:UITableViewRowAnimationFade];
  return newIndexPath;
}

- (NSIndexPath *)deleteExtraRow
{
  NSIndexPath *newIndexPath = [self indexPathForExtraRow];
  self.insertedIndexPath = nil;
  [self.tableView deleteRowsAtIndexPaths:@[ newIndexPath ] withRowAnimation:UITableViewRowAnimationFade];
  return newIndexPath;
}

@end
