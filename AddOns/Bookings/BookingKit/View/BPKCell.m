//
//  SGPaymentBaseCell.m
//  TripGo
//
//  Created by Kuan Lun Huang on 27/01/2015.
//
//

#import "BPKCell.h"

#import "BPKSection.h"

@implementation BPKCell

#pragma mark - Public methods

- (UITableViewCellAccessoryType)accessoryTypeForItem:(BPKSectionItem *)item
{
#pragma unused (item)
  return UITableViewCellAccessoryNone;
}

#pragma mark - Custom accessors

- (void)setReadOnly:(BOOL)readOnly
{
  _readOnly = readOnly;
  
  if (readOnly) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
  } else {
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
  }
}

@end
