//
//  AKTextFieldItem.h
//  TripKit
//
//  Created by Kuan Lun Huang on 16/02/2015.
//
//

@import UIKit;

#import "AMKItem.h"

@interface AKTextFieldItem : AMKItem

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL secureEntry;
@property (nonatomic, assign) BOOL clearsOnBeginningEditing;
@property (nonatomic, assign) UIKeyboardType keyboardType;
@property (nonatomic, assign) UIReturnKeyType returnKeyType;

@property (nonatomic, copy) void (^didEndEditingBlock)(UITextField *);
@property (nonatomic, copy) BOOL (^shouldReturnBlock)(UITextField *);

@end
