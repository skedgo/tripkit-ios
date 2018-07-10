//
//  SGPayLabelCell.h
//  TripKit
//
//  Created by Kuan Lun Huang on 28/01/2015.
//
//

#import <UIKit/UIKit.h>

#ifdef TK_NO_MODULE
#import "TKUIStyledLabel.h"
#else
@import TripKitUI;
#endif


#import "BPKCell.h"

typedef void (^DidSelectLabelCellHandler)(BPKSectionItem *item);

@interface BPKLabelCell : BPKCell <BPKFormCell>

@property (weak, nonatomic) IBOutlet TKUIStyledLabel *titleLabel;
@property (weak, nonatomic) IBOutlet TKUIStyledLabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet TKUIStyledLabel *sidetitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *image;

@property (nonatomic, copy) DidSelectLabelCellHandler didSelectHandler;

- (void)configureForMainTitle:(NSString *)mainTitle subTitle:(NSString *)subtitle sideTitle:(NSString *)sidetitle image:(NSURL *)imageURL;

@end
