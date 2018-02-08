//
//  BPKTableHeader.m
//  TripKit
//
//  Created by Kuan Lun Huang on 10/02/2015.
//
//

#import "BPKTableHeader.h"

@interface BPKTableHeader ()

@end

@implementation BPKTableHeader

- (void)layoutSubviews
{
  // Both title and subtitle labels may have multiple lines, so set
  // there preferred width here.
  _title.preferredMaxLayoutWidth = CGRectGetWidth(_title.frame);
  _subtitle.preferredMaxLayoutWidth = CGRectGetWidth(_subtitle.frame);
  
  [super layoutSubviews];
}

#pragma mark - Public methods

- (instancetype)initWithTitle:(NSString *)title subtitle:(NSString *)subtitle tableView:(UITableView *)tableView
{
  UINib *nib = [UINib nibWithNibName:NSStringFromClass([self class])
                              bundle:[NSBundle bundleForClass:[self class]]];
  NSArray *nibViews = [nib instantiateWithOwner:self options:nil];
  
  self = nibViews[0];
  if (self) {
    _title.text = title;
    _subtitle.text = subtitle;
    [self adjustFrameToFitTableView:tableView];
  }
  
  return self;
}

#pragma mark - Private methods

- (void)adjustFrameToFitTableView:(UITableView *)tableView
{
  CGRect frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.frame), CGRectGetHeight(self.frame));
  self.frame = frame;

  // Do a layout pass.
  [self setNeedsLayout];
  [self layoutIfNeeded];
  
  // use autolayout to determine the height
  CGFloat height = [self systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
  
  // update the frame
  frame.size.height = height;
  self.frame = frame;
}

@end
