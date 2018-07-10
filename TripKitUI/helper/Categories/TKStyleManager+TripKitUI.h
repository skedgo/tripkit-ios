//
//  TKStyleManager+TripKitUI.h
//  TripKit
//
//  Created by Adrian Schoenig on 6/07/2016.
//
//

#ifdef TK_NO_MODULE
#import "TripKit.h"
#else
@import TripKit;
#endif

@interface TKStyleManager (TripKitUI)

#pragma mark - Default styles

+ (void)addLightStatusBarGradientLayerToView:(UIView *)view height:(CGFloat)height;

+ (void)addLightStatusBarGradientLayerToView:(UIView *)view belowView:(UIView *)anotherView height:(CGFloat)height;

+ (void)removeGradientLayerFromView:(UIView *)view;

+ (void)addDefaultShadow:(UIView *)view;

+ (void)addDefaultOutline:(UIView *)view;

+ (void)addDefaultButtonOutline:(UIButton *)button cornerRadius:(CGFloat)radius;

+ (void)addDefaultButtonOutline:(UIButton *)button outlineColor:(UIColor *)color cornerRadius:(CGFloat)radius;

+ (UIColor *)backgroundColorForTileList;

+ (UIColor *)cellSelectionBackgroundColor;

+ (void)styleTableViewForTileList:(UITableView *)tableView;

+ (void)styleNavigationControllerAsDark:(UINavigationController *)navigationController;
  
+ (void)styleSearchBar:(UISearchBar *)searchBar
   includingBackground:(BOOL)includeBackground;

@end

@interface TKStyleManager (Buttons)

+ (UIButton *)mapCheckmarkButton:(BOOL)selected;
+ (UIButton *)roundedFloatingButtonWithTitle:(NSString *)title;

@end

@interface TKStyleManager (Fonts)

+ (UIFont *)systemFontWithSize:(CGFloat)size;
+ (UIFont *)boldSystemFontWithSize:(CGFloat)size;
+ (UIFont *)systemFontWithTextStyle:(NSString *)style;

@end
