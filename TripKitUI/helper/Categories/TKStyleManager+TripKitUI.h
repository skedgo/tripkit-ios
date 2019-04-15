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

NS_ASSUME_NONNULL_BEGIN

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

/// This method returns a regular font with custom font face for a given font size.
/// If there's no custom font face specified in the plist, system font face is used.
/// This method is recommended to use with system controls such as `UIButton`
///
/// - Parameter size: Font size desired
/// - Returns: A semibold font with custom font face.
+ (UIFont *)systemFontWithSize:(CGFloat)size NS_SWIFT_NAME(systemFont(size:));

/// This method returns a bold font with custom font face for a given font size.
/// If there's no custom font face specified in the plist, system font face is used.
/// This method is recommended to use with system controls such as `UIButton`
///
/// - Parameter size: Font size desired
/// - Returns: A bold font with custom font face.
+ (UIFont *)boldSystemFontWithSize:(CGFloat)size NS_SWIFT_NAME(boldSystemFont(size:));

/// This method returns a semibold font with custom font face for a given font size.
/// If there's no custom font face specified in the plist, system font face is used.
/// This method is recommended to use with system controls such as `UIButton`
///
/// - Parameter size: Font size desired
/// - Returns: A semibold font with custom font face.
+ (UIFont *)semiboldSystemFontWithSize:(CGFloat)size NS_SWIFT_NAME(semiboldSystemFont(size:));

/// This method returns a medium font with custom font face for a given font size.
/// If there's no custom font face specified in the plist, system font face is used.
/// This method is recommended to use with system controls such as `UIButton`
///
/// - Parameter size: Font size desired
/// - Returns: A semibold font with custom font face.
+ (UIFont *)mediumSystemFontWithSize:(CGFloat)size NS_SWIFT_NAME(mediumSystemFont(size:));

+ (UIFont *)systemFontWithTextStyle:(NSString *)style __attribute__((deprecated("Use `customFontWithTextStyle` instead"))) NS_SWIFT_NAME(systemFont(textStyle:));

@end

NS_ASSUME_NONNULL_END
