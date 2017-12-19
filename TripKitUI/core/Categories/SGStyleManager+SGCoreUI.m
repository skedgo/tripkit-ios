//
//  SGStyleManager+SkedGoUI.m
//  TripKit
//
//  Created by Adrian Schoenig on 6/07/2016.
//
//

#import "SGStyleManager+SGCoreUI.h"

#import "UISearchBar+Customizable.h"

#import "UIFont+CustomFonts.h"

@interface UIViewController (PopoverHelpers)
  
- (BOOL)isLikelyInPopover;
  
@end

@implementation UIViewController (PopoverHelpers)
  
- (BOOL)isLikelyInPopover
{
  return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && [self splitViewController] == nil;
}

@end


@implementation SGStyleManager (TripKitUI)

+ (void)addLightStatusBarGradientLayerToView:(UIView *)view height:(CGFloat)height
{
  CAGradientLayer *gradient = [CAGradientLayer layer];
  
  CGFloat width = MAX(CGRectGetWidth(view.frame), CGRectGetHeight(view.frame)) * 1.5f; // bigger to account for resizes
  gradient.frame = CGRectMake(0, 0, width, height);
  
  UIColor *c1 = [UIColor colorWithRed:52/255.0f green:78/255.0f blue:109/255.0f alpha:0.7f];
  gradient.colors = @[(id)c1.CGColor, (id)c1.CGColor];
  
  [view.layer addSublayer:gradient];
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
  CGColorRef color = [UIColor colorWithWhite:204.f/255 alpha:1].CGColor;
  
  view.layer.borderColor = color;
  view.layer.borderWidth = width;
  
  //  CALayer *topBorder = [CALayer layer];
  //  topBorder.frame = CGRectMake(0, 0, CGRectGetWidth(view.frame), width);
  //  topBorder.backgroundColor = color;
  //  [view.layer addSublayer:topBorder];
  //
  //  CALayer *bottomBorder = [CALayer layer];
  //  bottomBorder.frame = CGRectMake(0, CGRectGetMaxY(view.frame) - width, CGRectGetWidth(view.frame), width);
  //  bottomBorder.backgroundColor = color;
  //  [view.layer addSublayer:bottomBorder];
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
  tableView.backgroundColor = [self backgroundColorForTileList];
  tableView.contentInset = UIEdgeInsetsMake(5, 0, 5, 0); // more padding around tiles
  tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

+ (UIColor *)backgroundColorForTileList
{
  return [UIColor colorWithRed:237/255.0f green:238/255.0f blue:242/255.0f alpha:1];
}

+ (UIColor *)cellSelectionBackgroundColor
{
  //  return [UIColor colorWithWhite:250/255.f alpha:1];
  return [UIColor colorWithWhite:247/255.f alpha:1];
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
  

+ (void)styleSearchBar:(UISearchBar *)searchBar
   includingBackground:(BOOL)includeBackground
{
  // style the searchbar
  UIImage *navBarBg    = [UIImage imageNamed:@"bg-nav-secondary"];
  if (!includeBackground) {
    navBarBg = [[UIImage alloc] init]; // blank
  }
  searchBar.tintColor = [self globalAccentColor];
  searchBar.backgroundImage = navBarBg;
  
  // style the text field
  [searchBar styleTextField:^(UITextField *textField) {
    textField.font = [self systemFontWithSize:15];
    textField.textColor = [SGStyleManager darkTextColor];
    textField.backgroundColor = [UIColor clearColor];
  }];
}

@end

@implementation SGStyleManager (Buttons)

+ (UIButton *)mapCheckmarkButton:(BOOL)selected
{
  UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
  UIImage *image = selected ? [self imageNamed:@"icon-callout-tick-filled"] : [self imageNamed:@"icon-callout-tick"];
  [button setImage:image forState:UIControlStateNormal];
  button.accessibilityLabel = NSLocalizedStringFromTableInBundle(@"Checkmark", @"Shared", [SGStyleManager bundle], "Accessibility title for a checkmark/tick button");
  button.tintColor = [self globalTintColor];
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

@implementation SGStyleManager (Fonts)

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

+ (UIFont *)systemFontWithTextStyle:(NSString *)style
{
  NSString *fontName = [UIFont preferredFontName];
  if (fontName) {
    UIFont *font = [UIFont preferredFontForTextStyle:style];
    if (font) {
      return [UIFont fontWithName:fontName size:font.pointSize];
    }
  }
  return [UIFont preferredFontForTextStyle:style];
}

@end


