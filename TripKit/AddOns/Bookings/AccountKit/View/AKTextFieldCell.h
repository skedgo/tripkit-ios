//
//  AKTextFieldCell.h
//  TripKit
//
//  Created by Kuan Lun Huang on 12/12/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

@import UIKit;

#ifdef TK_NO_MODULE
#import "TKUIStyledLabel.h"
#else
@import TripKitUI;
#endif

#import "AKItemCell.h"

typedef BOOL (^TextFieldShouldReturnHandler)(UITextField *textField);
typedef void (^TextFieldDidEndEditingHandler)(UITextField *textField);

@interface AKTextFieldCell : SGTableCell <AKItemCell>

@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet TKUIStyledLabel *promptLabel;

@property (nonatomic, copy) TextFieldShouldReturnHandler shouldReturnHandler;
@property (nonatomic, copy) TextFieldDidEndEditingHandler didEndEditingHandler;

+ (AKTextFieldCell *)sharedInstance;

- (void)configureForPrompt:(NSString *)prompt placeholder:(NSString *)placeholder text:(NSString *)text;
- (void)makeActive:(BOOL)active;

@end
