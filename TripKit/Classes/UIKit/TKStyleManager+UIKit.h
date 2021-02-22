//
//  TKStyleManager+TripKitUI.h
//  TripKit
//
//  Created by Adrian Schoenig on 6/07/2016.
//
//

#import <TargetConditionals.h>

#if TARGET_OS_IPHONE

@import UIKit;

#import "TKStyleManager.h"

NS_ASSUME_NONNULL_BEGIN

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

@end

NS_ASSUME_NONNULL_END

#endif
