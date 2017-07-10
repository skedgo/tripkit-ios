//
//  UISearchBar+Customizable.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 5/02/13.
//
//

#import <UIKit/UIKit.h>

@interface UISearchBar (Customizable)

- (void)styleTextField:(void (^)(UITextField *textField))block;

- (void)setClearButtonNormalImage:(UIImage *)normalImage HighlightedImage:(UIImage *)highlightedImage TintColor:(UIColor *)tintColor;
- (void)setTextFieldBackgroundImage:(UIImage *)image;
- (void)setTextFieldLeftImage:(UIImage *)image;
- (void)setTextFieldBackgroundImage:(UIImage *)backgroundImage
											 andLeftImage:(UIImage *)leftImage;

@end
