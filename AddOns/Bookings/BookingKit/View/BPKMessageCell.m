//
//  BPKMessageCell.m
//  TripGo
//
//  Created by Kuan Lun Huang on 16/03/2015.
//
//

#import "BPKMessageCell.h"

#import "BPKSection.h"

@implementation BPKMessageCell

@synthesize didChangeValueHandler;

#pragma mark - BPKFormCell

- (void)configureForItem:(BPKSectionItem *)item
{
  self.readOnly = item.isReadOnly;
  
  self.label.text = item.value;
  self.separatorInset = UIEdgeInsetsMake(0.0f, self.bounds.size.width, 0.0f, 0.0f);
}

#pragma mark - Overrides

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  [self.contentView setNeedsLayout];
  [self.contentView layoutIfNeeded];
  
  [self.label setPreferredMaxLayoutWidth:CGRectGetWidth(self.label.frame)];
}

@end
