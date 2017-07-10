//
//  BPKTextCell.h
//  TripGo
//
//  Created by Kuan Lun Huang on 13/05/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BPKCell.h"

@interface BPKTextCell : BPKCell <BPKFormCell>

@property (weak, nonatomic) IBOutlet UITextView *textView;

- (void)configureWithText:(NSString *)text;

- (void)configureWithAttributedText:(NSString *)attributedText;

@end
