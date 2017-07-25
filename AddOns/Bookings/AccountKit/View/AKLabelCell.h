//
//  SGUserAccountStandardCell.h
//  TripKit
//
//  Created by Kuan Lun Huang on 12/12/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

@import UIKit;

#ifndef TK_NO_FRAMEWORKS
@import TripKitUI;
#else
#import "SGTableCell.h"
#endif

#import "AKItemCell.h"

@class SGLabel;

@interface AKLabelCell : SGTableCell <AKItemCell>

@property (nonatomic, weak) IBOutlet SGLabel *primaryLabel;
@property (nonatomic, weak) IBOutlet SGLabel *secondaryLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *primaryToSecondarySpacing;

+ (AKLabelCell *)sharedInstance;

- (void)configureWithTitle:(NSString *)title subtitle:(NSString *)subtitle;

@end
