//
//  UISearchBar+Customizable.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 5/02/13.
//
//

#import "UISearchBar+Customizable.h"

@implementation UISearchBar (Customizable)

- (void)styleTextField:(void (^)(UITextField *textField))block
{
	UITextField *textField = [self textField];
	if (nil != textField) {
		block(textField);
	}
}

- (void)setClearButtonNormalImage:(UIImage *)normalImage HighlightedImage:(UIImage *)highlightedImage TintColor:(UIColor *)tintColor{
  NSArray *subView = [self subviews];
  NSArray *subsubView = [[subView objectAtIndex:0] subviews];
  
  @try {
    UIButton *clearButton = [[subsubView objectAtIndex:1] valueForKey:@"_clearButton"];
    if (normalImage != nil) {
      [clearButton setImage:[normalImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    if (highlightedImage != nil) {
      [clearButton setImage:[highlightedImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateHighlighted];
    }
    clearButton.tintColor = tintColor;
  }
  @catch (NSException *exception) {
    // valueForKey:@"_clearButton"] crashes on iOS 13 with NSUndefinedKeyException
    // we should use the proper search bar customisation on iOS 13.
    return;
  }
}

- (void)setTextFieldBackgroundImage:(UIImage *)image
{
	[self styleTextField:^(UITextField *textField) {
		textField.borderStyle = UITextBorderStyleNone;
		textField.background = image;
	}];
}

- (void)setTextFieldLeftImage:(UIImage *)image
{
	[self styleTextField:^(UITextField *textField) {
		textField.leftView = [[UIImageView alloc] initWithImage:image];
	}];
}

- (void)setTextFieldBackgroundImage:(UIImage *)backgroundImage
											 andLeftImage:(UIImage *)leftImage
{
	[self styleTextField:^(UITextField *textField) {
		textField.borderStyle = UITextBorderStyleNone;
		textField.background = backgroundImage;
		textField.leftView = [[UIImageView alloc] initWithImage:leftImage];
	}];
}

#pragma mark - Private methods

- (UITextField *)textField
{
	for (UIView *view in self.subviews) {
    if ([view isKindOfClass:[UITextField class]]) {
			return (UITextField *)view;
    }
	}
  // look one-level deep
	for (UIView *view in [[self.subviews firstObject] subviews]) {
    if ([view isKindOfClass:[UITextField class]]) {
			return (UITextField *)view;
    }
	}
	return nil;
}

@end
