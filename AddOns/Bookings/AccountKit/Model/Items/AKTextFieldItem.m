//
//  AMKTextFieldItem.m
//  TripKit
//
//  Created by Kuan Lun Huang on 16/02/2015.
//
//

#import "AKTextFieldItem.h"

@implementation AKTextFieldItem

- (instancetype)init
{
  self = [super init];
  
  if (self) {
    self.secureEntry = NO;
    self.enabled = YES;
    self.clearsOnBeginningEditing = NO;
    self.keyboardType = UIKeyboardTypeAlphabet;
    self.returnKeyType = UIReturnKeyDefault;
  }
  
  return self;
}

@end
