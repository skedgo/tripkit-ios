//
//  UIView+Keyboard.m
//  TripKit
//
//  Created by Kuan Lun Huang on 16/02/2015.
//
//

#import "UIView+Keyboard.h"

#import "UIView+FindFirstResponder.h"

@implementation UIView (Keyboard)

- (void)dismissKeyboard
{
  UIView *firstResponder = [self findFirstResponder];
  
  if (firstResponder != nil && [firstResponder isKindOfClass:[UITextField class]]) {
    [firstResponder resignFirstResponder];
  }
}

@end
