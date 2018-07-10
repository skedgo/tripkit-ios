//
//  SGTableViewCell.m
//  TripKit
//
//  Created by Kuan Lun Huang on 30/03/2015.
//
//

#import "SGTableCell.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#endif

@implementation SGTableCell

+ (UINib *)nib
{
  return [UINib nibWithNibName:[self reuseId]
                        bundle:[NSBundle bundleForClass:[self class]]];
}

+ (NSString *)reuseId
{
  return NSStringFromClass([self class]);
}

- (CGFloat)heightForWidth:(CGFloat)width
{
  // Make sure constraints have been added to this cell, since it may have just been created from scratch
  [self setNeedsUpdateConstraints];
  [self updateConstraintsIfNeeded];
  
  self.bounds = CGRectMake(0.0f, 0.0f, width, CGRectGetHeight(self.bounds));
  
   // Do the layout pass on the cell, which will calculate the frames for all the views based on the constraints
  // (Note that the preferredMaxLayoutWidth is set on multi-line UILabels inside the -[layoutSubviews] method
  // in the UITableViewCell subclass
  [self setNeedsLayout];
  [self layoutIfNeeded];
  
  // Get the actual height required for the cell
  CGFloat height = [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
  
  // Add an extra point to the height to account for the cell separator, which is added between the bottom
  // of the cell's contentView and the bottom of the table view cell.
  height += 1;
  
  return height;
}

#pragma mark - Initializer

- (instancetype)init
{
  UINib *nib = [[self class] nib];
  NSArray *nibViews = [nib instantiateWithOwner:self options:nil];
  
  if (! nibViews.count) {
    return nil;
  }
  
  self = nibViews[0];
  
  if (self) {
    [self commonInit];
  }
  
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  
  if (self) {
    [self commonInit];
  }
  
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  
  if (self) {
    [self commonInit];
  }
  
  return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  
  if (self) {
    [self commonInit];
  }
  
  return self;
}

#pragma mark - Private methods

- (void)commonInit
{
  NSString *labelStyle = [[self.textLabel.font fontDescriptor] fontAttributes][UIFontDescriptorTextStyleAttribute];
  
  if (! labelStyle) {
    CGFloat point = self.textLabel.font.pointSize;
    self.textLabel.font = [SGStyleManager systemFontWithSize:point];
  } else {
    self.textLabel.font = [SGStyleManager systemFontWithTextStyle:labelStyle];
  }
  
  NSString *detailLabelStyle = [[self.detailTextLabel.font fontDescriptor] fontAttributes][UIFontDescriptorTextStyleAttribute];
  
  if (! detailLabelStyle) {
    CGFloat point = self.detailTextLabel.font.pointSize;
    self.detailTextLabel.font = [SGStyleManager systemFontWithSize:point];
  } else {
    self.detailTextLabel.font = [SGStyleManager systemFontWithTextStyle:detailLabelStyle];
  }
}

@end
