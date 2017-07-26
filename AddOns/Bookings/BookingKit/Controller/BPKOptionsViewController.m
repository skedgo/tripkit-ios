//
//  SGBPOptionViewController.m
//  TripKit
//
//  Created by Kuan Lun Huang on 3/02/2015.
//
//

#import "BPKOptionsViewController.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#endif

#import "BPKBookingKit.h"

@interface BPKOptionsViewController ()

@property (nonatomic, strong) NSArray *options;
@property (nonatomic, strong) BPKSectionItem *item;
@property (nonatomic, assign) NSInteger selectedIndex;

@end

@implementation BPKOptionsViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.title = [self.item.json objectForKey:kBPKFormTitle];
  
  // pre-select
  self.selectedIndex = [self.item.values indexOfObject:self.item.value];

  self.tableView.rowHeight = UITableViewAutomaticDimension;
  self.tableView.estimatedRowHeight = 44.0f;
}

#pragma mark - Public methods

- (instancetype)initWithItem:(BPKSectionItem *)item
{
  self = [self initWithStyle:UITableViewStyleGrouped];
  
  if (self) {
    _item = item;
    _options = [item.json objectForKey:kBPKFormAllValues];
  }
  
  return self;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#pragma unused (tableView)
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#pragma unused (tableView, section)
  return self.options.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
#pragma unused (tableView)
  UITableViewCell *cell = [self standardCell];
  
  id option = self.options[indexPath.row];
  if (option != nil) {
    if ([option isKindOfClass:[NSDictionary class]]) {
      cell.textLabel.text = option[@"title"];
      cell.detailTextLabel.text = option[@"sidetitle"];
    }
    
    cell.accessoryType = indexPath.row == self.selectedIndex ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
  }
  
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  [self selectOptionAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
#pragma unused (tableView)
  if ([self detailsAvailableForOptionAtIndexPath:indexPath]) {
    [self loadDetailsForOptionAtIndexPath:indexPath];
  }
}

#pragma mark - Private methods

- (SGTableCell *)standardCell
{
  static NSString *reuseId = @"optionCell";
  
  SGTableCell *cell = [self.tableView dequeueReusableCellWithIdentifier:reuseId];
  
  if (! cell) {
    cell = [[SGTableCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseId];
  }
  
  cell.textLabel.textColor = [UIColor darkTextColor];
  cell.textLabel.font = [SGStyleManager systemFontWithTextStyle:UIFontTextStyleBody];
  
  cell.detailTextLabel.textColor = [UIColor lightGrayColor];
  cell.detailTextLabel.font = [SGStyleManager systemFontWithTextStyle:UIFontTextStyleCaption1];
  
  return cell;
}

#pragma mark - Private: Handle selection

- (BOOL)detailsAvailableForOptionAtIndexPath:(NSIndexPath *)indexPath
{
  if ((NSUInteger)indexPath.row >= self.options.count) {
    return NO;
  }
  
  id option = self.options[indexPath.row];
  return [self detailsAvailableForOption:option];
}

- (BOOL)detailsAvailableForOption:(NSDictionary *)option
{
  if (option != nil && [option isKindOfClass:[NSDictionary class]]) {
    return option[@"form"] != nil;
  } else {
    return NO;
  }
}

- (void)loadDetailsForOptionAtIndexPath:(NSIndexPath *)indexPath
{
  id option = self.options[indexPath.row];
  ZAssert([option isKindOfClass:[NSDictionary class]], @"Details for an option should be constructed as a dictionary");
  
  BPKBookingViewController *ctr = [[BPKBookingViewController alloc] initWithForm:option];
  [self.navigationController pushViewController:ctr animated:YES];
}

- (void)selectOptionAtIndexPath:(NSIndexPath *)indexPath
{
  NSArray *reload;
  
  if (self.selectedIndex < (NSInteger)self.options.count) {
    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:self.selectedIndex inSection:indexPath.section];
    
    if ([selectedIndexPath isEqual:indexPath]) {
      reload = @[indexPath];
    } else {
      reload = @[indexPath, selectedIndexPath];
    }
  } else {
    reload = @[indexPath];
  }
  
  self.selectedIndex = indexPath.row;
  
  // Reload to update checkmark
  [self.tableView reloadRowsAtIndexPaths:reload withRowAnimation:UITableViewRowAnimationAutomatic];
  
  // Notify delegate
  [self.delegate optionViewController:self didSelectItemAtIndex:self.selectedIndex];
}

@end
