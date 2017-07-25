//
//  SGPaymentTextFieldCell.h
//  TripKit
//
//  Created by Kuan Lun Huang on 27/01/2015.
//
//

@import UIKit;

#ifndef TK_NO_FRAMEWORKS

#endif

#import "BPKCell.h"
#import "BPKTextFieldBlock.h"

@interface BPKTextFieldCell : BPKCell <BPKFormCell, BPKTextFieldBlock>

@property (weak, nonatomic) IBOutlet UITextField *textField;

// Configuration
- (void)configureForPrompt:(NSString *)prompt placeholder:(NSString *)placeHolder text:(NSString *)text;

// UI Updates
- (void)updateText:(NSString *)newText withAttributes:(NSDictionary *)attributes;
- (void)updatePlaceholder:(NSString *)newText withAttributes:(NSDictionary *)attributes;
- (void)highlightPlaceholder:(BOOL)highlight;

// Input accessory view
- (void)insertNextKbToolBar;
- (void)insertDoneKbToolBar;

@end
