//
//  SGTableViewCell.h
//  TripKit
//
//  Created by Kuan Lun Huang on 30/03/2015.
//
//

#import <UIKit/UIKit.h>

@interface SGTableCell : UITableViewCell

+ (UINib *)nib;

+ (NSString *)reuseId;

- (CGFloat)heightForWidth:(CGFloat)width;

@end
