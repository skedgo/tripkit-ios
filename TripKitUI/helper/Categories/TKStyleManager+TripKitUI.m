//
//  TKStyleManager+SkedGoUI.m
//  TripKit
//
//  Created by Adrian Schoenig on 6/07/2016.
//
//

#import "TKStyleManager+TripKitUI.h"

#import <TripKitUI/TripKitUI-Swift.h>

#import "UIFont+CustomFonts.h"
#import "NSString+Sizing.h"

@interface UIViewController (PopoverHelpers)
  
- (BOOL)isLikelyInPopover;
  
@end

@implementation UIViewController (PopoverHelpers)
  
- (BOOL)isLikelyInPopover
{
  return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && [self splitViewController] == nil;
}

@end


@implementation TKStyleManager (TripKitUI)

+ (void)addLightStatusBarGradientLayerToView:(UIView *)view belowView:(UIView *)anotherView height:(CGFloat)height
{
  CGFloat width = MAX(CGRectGetWidth(view.frame), CGRectGetHeight(view.frame)) * 1.5f; // bigger to account for resizes
  
  CAGradientLayer *gradient = [self lightGradientLayerWithWidth:width height:height];
  
  if (anotherView != nil) {
    [view.layer insertSublayer:gradient below:anotherView.layer];
  } else {
    [view.layer addSublayer:gradient];
  }
}

+ (void)removeGradientLayerFromView:(UIView *)view
{
  CAGradientLayer *gradient = nil;
  for (CALayer *layer in view.layer.sublayers) {
    if ([layer isKindOfClass:[CAGradientLayer class]]) {
      gradient = (CAGradientLayer *) layer;
      break;
    }
  }
  [gradient removeFromSuperlayer];
}

+ (void)addDefaultShadow:(UIView *)view
{
  view.layer.shadowOpacity = 0.2f;
  view.layer.shadowOffset = CGSizeMake(0, 0);
  view.layer.shadowRadius = 1;
}

+ (void)addDefaultOutline:(UIView *)view
{
  CGFloat width = 0.5;
  CGColorRef color = UIColor.tkSeparator.CGColor;
  
  view.layer.borderColor = color;
  view.layer.borderWidth = width;
}

+ (void)addDefaultButtonOutline:(UIButton *)button cornerRadius:(CGFloat)radius
{
  [self addDefaultButtonOutline:button outlineColor:button.tintColor cornerRadius:radius];
}

+ (void)addDefaultButtonOutline:(UIButton *)button outlineColor:(UIColor *)color cornerRadius:(CGFloat)radius
{
  button.layer.borderColor = color.CGColor;
  button.layer.borderWidth = 1;
  button.layer.cornerRadius = radius;
}

+ (void)styleTableViewForTileList:(UITableView *)tableView
{
  tableView.backgroundColor = UIColor.tkBackgroundBelowTile;
  tableView.contentInset = UIEdgeInsetsMake(5, 0, 5, 0); // more padding around tiles
  tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

+ (UIColor *)backgroundColorForTileList
{
  return UIColor.tkBackgroundBelowTile;
}

+ (UIColor *)cellSelectionBackgroundColor
{
  return UIColor.tkBackgroundSelected;
}

#pragma mark - Helpers

+ (CAGradientLayer *)lightGradientLayerWithWidth:(CGFloat)width height:(CGFloat)height
{
  CAGradientLayer *gradient = [CAGradientLayer layer];
  gradient.frame = CGRectMake(0, 0, width, height);
  
  UIColor *c1 = UIColor.tkStatusBarOverlay;
  gradient.colors = @[(id)c1.CGColor, (id)c1.CGColor];
  
  return gradient;
}

#pragma mark - Styling bars

+ (void)styleNavigationControllerAsDark:(UINavigationController *)navigationController
  {
    UINavigationBar *navBar = navigationController.navigationBar;
    
    if (! [navigationController isLikelyInPopover]) {
      navBar.translucent = [self globalTranslucency];
    } else {
      navBar.translucent = YES;
    }
  }
  
@end

@implementation TKStyleManager (Buttons)

+ (UIButton *)mapCheckmarkButton:(BOOL)selected
{
  UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
  UIImage *image = selected ? [self imageNamed:@"icon-callout-tick-filled"] : [self imageNamed:@"icon-callout-tick"];
  [button setImage:image forState:UIControlStateNormal];
  button.accessibilityLabel = Loc.Checkmark;
  button.tintColor = UIColor.tkAppTintColor;
  return button;
}

+ (UIButton *)roundedFloatingButtonWithTitle:(NSString *)title
{
  UIFont *font = [self boldSystemFontWithSize:16];
  CGSize size = [title sizeWithFont:font maximumWidth:250];
  
  UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, size.width, 44)];
  [button.titleLabel setFont:font];
  [button setTitle:title forState:UIControlStateNormal];
  return button;
}


@end

@implementation TKStyleManager (Fonts)

+ (UIFont *)systemFontWithSize:(CGFloat)size
{
  NSString *name = [UIFont preferredFontName];
  if (name) {
    UIFont *preferredFont = [UIFont fontWithName:name size:size];
    if (preferredFont) {
      return preferredFont;
    }
  }
  return [UIFont systemFontOfSize:size];
}

+ (UIFont *)boldSystemFontWithSize:(CGFloat)size
{
  NSString *name = [UIFont preferredBoldFontName];
  if (name) {
    UIFont *preferredFont = [UIFont fontWithName:name size:size];
    if (preferredFont) {
      return preferredFont;
    }
  }
  return [UIFont boldSystemFontOfSize:size];
}

+ (UIFont *)semiboldSystemFontWithSize:(CGFloat)size
{
  NSString *name = [UIFont preferredSemiboldFontName];
  if (name) {
    UIFont *preferredFont = [UIFont fontWithName:name size:size];
    if (preferredFont) {
      return preferredFont;
    }
  }
  return [UIFont systemFontOfSize:size weight:UIFontWeightSemibold];
}

+ (UIFont *)mediumSystemFontWithSize:(CGFloat)size
{
  NSString *name = [UIFont preferredMediumFontName];
  if (name) {
    UIFont *preferredFont = [UIFont fontWithName:name size:size];
    if (preferredFont) {
      return preferredFont;
    }
  }
  return [UIFont systemFontOfSize:size weight:UIFontWeightMedium];
}

+ (UIFont *)systemFontWithTextStyle:(NSString *)style
{
  return [self customFontForTextStyle:style];
}

@end


