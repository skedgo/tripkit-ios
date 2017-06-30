//
//  SGPayLabelCell.m
//  TripGo
//
//  Created by Kuan Lun Huang on 28/01/2015.
//
//

#import "BPKLabelCell.h"

#import "BPKSection.h"

#import "BPKConstants.h"

#import "SGStyleManager.h"

@import AFNetworking;

@interface BPKLabelCell ()

@property (nonatomic, strong) NSURL *imageURL;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *subtitleToSidetitleSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleToSidetitleSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleToImageSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *subtitleToImageSpaceConstraint;

@end

@implementation BPKLabelCell

@synthesize didChangeValueHandler;

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  [self.contentView setNeedsLayout];
  [self.contentView layoutIfNeeded];
  
  // Autolayout doesn't seem to play nicely when cell with multi-line labels has accessory
  // view; it seems to ignore the extra space taken up by the accessory view. To work
  // around this, we reduce the label's preferred maximum layout width by the amount taken
  // up by the accessory view.
  CGFloat cellWidth = CGRectGetWidth(self.frame);
  CGFloat contentViewWidth = CGRectGetWidth(self.contentView.frame);
  CGFloat adjustment = cellWidth - contentViewWidth;
  
  // Note that, when the cell has no accessory type set, the adjustment will be zero.
  self.titleLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.titleLabel.frame) - adjustment;
  self.subtitleLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.subtitleLabel.frame) - adjustment;
  self.sidetitleLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.sidetitleLabel.frame) - adjustment;
}

- (void)updateConstraints
{
  if (self.sidetitleLabel.text.length == 0) {
    self.titleToSidetitleSpaceConstraint.constant = 0.0f;
    self.subtitleToSidetitleSpaceConstraint.constant = 0.0f;
  } else {
    self.titleToSidetitleSpaceConstraint.constant = 8.0f;
    self.subtitleToSidetitleSpaceConstraint.constant = 8.0f;
  }
  
  if (self.imageURL != nil) {
    self.imageHeightConstraint.constant = 40.0f;
    self.titleToImageSpaceConstraint.constant = 8.0f;
    self.subtitleToImageSpaceConstraint.constant = 8.0f;
  } else {
    self.imageHeightConstraint.constant = 0.0f;
    self.titleToImageSpaceConstraint.constant = 0.0f;
    self.subtitleToImageSpaceConstraint.constant = 0.0f;
  }
  
  [super updateConstraints];
}

#pragma mark - Pubic methods

- (void)configureForMainTitle:(NSString *)mainTitle subTitle:(NSString *)subtitle sideTitle:(NSString *)sidetitle image:(NSURL *)imageURL
{  
  // strings
  self.titleLabel.text = mainTitle;
  self.subtitleLabel.text = subtitle;
  self.sidetitleLabel.text = sidetitle;
  
  // image
  self.imageURL = imageURL;
  [self.image setImageWithURL:imageURL];
}

#pragma mark - Overrides

- (UITableViewCellAccessoryType)accessoryTypeForItem:(BPKSectionItem *)item
{
  if (([item isAddressItem] || [item isOptionItem] || [item isFormItem] || [item isTermsLinkItem]) && ! item.isReadOnly) {
    return UITableViewCellAccessoryDisclosureIndicator;
  } else {
    return UITableViewCellAccessoryNone;
  }
}

#pragma mark - BPKFormCell

- (void)configureForItem:(BPKSectionItem *)item
{
  // strings
  NSString *title = [self titleForItem:item];
  NSString *subtitle = [self subtitleForItem:item];
  NSString *sidetitle = [self sideTitleForItem:item];
  
  // image
  NSURL *imageURL;
  NSString *urlString = [item.json objectForKey:@"image"];
  if (urlString.length != 0) {
    imageURL = [NSURL URLWithString:urlString];
  }
  
  [self configureForMainTitle:title subTitle:subtitle sideTitle:sidetitle image:imageURL];
  
  self.readOnly = item.isReadOnly;
  self.accessoryType = [self accessoryTypeForItem:item];
}

#pragma mark - Private: Layout margins

- (BOOL)canSetLayoutMargin
{
  return [self respondsToSelector:@selector(setLayoutMargins:)];
}

#pragma mark - Private: Items

- (NSString *)titleForItem:(BPKSectionItem *)item
{
  if ([item isOptionItem]) {
    return [item title];
  } else if ([item isAddressItem]) {
    NSString *title = [item.json objectForKey:@"title"];
    if (! title) {
      return [self addressInfoForItem:item];
    }
  }
  
  return [item.json objectForKey:@"title"];
}

- (NSString *)subtitleForItem:(BPKSectionItem *)item
{
  if ([item isAddressItem]) {
    NSString *subtitle = [self addressInfoForItem:item];
    if ([subtitle isEqualToString:[self titleForItem:item]]) {
      return nil;
    } else {
      return subtitle;
    }
  } else if ([item isTimeItem]) {
    return [self timeInfoForItem:item];
  } else if ([item isFormItem]) {
    return [self subtitleForFormItem:item];
  } else if ([item isOptionItem]) {
    return [self subtitleForOptionItem:item];
  } else if ([item isStringItem]) {
    return [item.json objectForKey:@"subtitle"];
  } else {
    return nil;
  }
}

- (NSString *)sideTitleForItem:(BPKSectionItem *)item
{
  if ([item isOptionItem]) {
    return [self sideTitleForOptionItem:item];
  } else if ([item isDateItem]) {
    return [self sideTitleForDateItem:item];
  } else if ([item isStringItem]) {
    return [item.json objectForKey:@"sidetitle"];
  } else {
    return nil;
  }
}

#pragma mark - Private: Subtitle

- (NSString *)subtitleForFormItem:(BPKSectionItem *)item
{
  return [item.json objectForKey:@"subtitle"];
}

- (NSString *)subtitleForOptionItem:(BPKSectionItem *)item
{
  id value = [item.json objectForKey:kBPKFormValue];
  if (! value) {
    return nil;
  }
  
  if ([value isKindOfClass:[NSDictionary class]]) {
    return value[@"subtitle"];
  }
  
  return nil;
}

- (NSString *)addressInfoForItem:(BPKSectionItem *)item
{
  NSDictionary *value = [item.json objectForKey:kBPKFormValue];
  if (! value) {
    return @"unavailable";
  }
  
  NSString *address = [value objectForKey:kBPKFormAddress];
  NSString *name = [value objectForKey:kBPKFormName];
  NSNumber *lat = [value objectForKey:kBPKFormLat];
  NSNumber *lng = [value objectForKey:kBPKFormLng];
  
  if (name != nil) {
    return name;
  } else if (address != nil) {
    return address;
  } else if (lat != nil && lng != nil) {
    return [NSString stringWithFormat:@"%.3f, %.3f", lat.doubleValue, lng.doubleValue];
  } else {
    return @"address info unavailable";
  }
}

- (NSString *)timeInfoForItem:(BPKSectionItem *)item
{
  NSNumber *time = [item.json objectForKey:kBPKFormValue];
  if (! time) {
    return @"TBA";
  }
  
  return [NSString stringWithFormat:@"%@", time];
}

#pragma mark - Private: Sidetitle

- (NSString *)sideTitleForOptionItem:(BPKSectionItem *)item
{
  id value = [item.json objectForKey:kBPKFormValue];
  if (! value) {
    return nil;
  }
  
  if ([value isKindOfClass:[NSDictionary class]]) {
    return value[@"sidetitle"];
  }
  
  return nil;
}

- (NSString *)sideTitleForFormItem:(BPKSectionItem *)item
{
  return [item.json objectForKey:@"value"];
}

- (NSString *)sideTitleForDateItem:(BPKSectionItem *)item
{
  if (! [item isDateItem]) {
    return nil;
  }
  
  NSNumber *epochTime = [item.json objectForKey:kBPKFormValue];
  if (! epochTime) {
    return @"unavailable";
  }
  
  NSDate *date = [NSDate dateWithTimeIntervalSince1970:epochTime.doubleValue];
  return [SGStyleManager stringForDate:date forTimeZone:[NSTimeZone localTimeZone] showDate:YES showTime:YES];
}

@end
