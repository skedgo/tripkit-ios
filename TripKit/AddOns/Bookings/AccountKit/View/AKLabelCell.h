//
//  SGUserAccountStandardCell.h
//  TripKit
//
//  Created by Kuan Lun Huang on 12/12/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

@import UIKit;

#import "AKItemCell.h"
#import "SGTableCell.h"

@class TKUIStyledLabel;

@interface AKLabelCell : SGTableCell <AKItemCell>

@property (nonatomic, weak) IBOutlet TKUIStyledLabel *primaryLabel;
@property (nonatomic, weak) IBOutlet TKUIStyledLabel *secondaryLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *primaryToSecondarySpacing;

+ (AKLabelCell *)sharedInstance;

- (void)configureWithTitle:(NSString *)title subtitle:(NSString *)subtitle;

@end
