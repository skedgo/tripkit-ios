//
//  TKStyleManager.h
//  TripKit
//
//  Created by Adrian Schoenig on 24/10/2013.
//
//

@import CoreLocation;

#import "TKCrossPlatform.h"

typedef NS_ENUM(NSInteger, TKStyleModeIconType) {
	TKStyleModeIconTypeListMainMode,
  TKStyleModeIconTypeMapIcon,
  TKStyleModeIconTypeResolutionIndependent, // SVGs! You probably need SVGKit to handle these.
  TKStyleModeIconTypeVehicle,
  TKStyleModeIconTypeAlert,
};

NS_ASSUME_NONNULL_BEGIN
@interface TKStyleManager : NSObject

+ (TKColor *)darkTextColor DEPRECATED_MSG_ATTRIBUTE("Use dynamic colors that are compatible with Dark Mode, e.g., from TripKitUI");

+ (TKColor *)lightTextColor DEPRECATED_MSG_ATTRIBUTE("Use dynamic colors that are compatible with Dark Mode, e.g., from TripKitUI");

#if TARGET_OS_IPHONE
+ (UIButton *)cellAccessoryButtonWithImage:(UIImage *)image
                                    target:(nullable id)target
                                    action:(nullable SEL)selector;
#endif

#pragma mark - Image names

+ (NSBundle *)bundle NS_REFINED_FOR_SWIFT; // Wrong bundle for Swift!

#pragma mark - Date formatting

+ (NSString *)timeString:(NSDate *)time
             forTimeZone:(nullable NSTimeZone *)timeZone;

+ (NSString *)timeString:(NSDate *)time
             forTimeZone:(nonnull NSTimeZone *)timeZone
      relativeToTimeZone:(nullable NSTimeZone *)relativeTimeZone;

+ (NSString *)dateString:(NSDate *)time
						 forTimeZone:(NSTimeZone *)timeZone;

+ (NSString *)stringForDate:(NSDate *)date
                forTimeZone:(NSTimeZone *)timeZone
                   showDate:(BOOL)showDate
                   showTime:(BOOL)showTime;

+ (NSString *)stringForDate:(NSDate *)date
                forTimeZone:(NSTimeZone *)timeZone
                forceFormat:(NSString *)format;

+ (NSString *)stringForDate:(NSDate *)date
                forTimeZone:(NSTimeZone *)timeZone
                 forceStyle:(NSDateFormatterStyle)style;

@end

@interface TKStyleManager (Color)

+ (TKColor *)globalTintColor;
+ (TKColor *)globalAccentColor;

+ (TKColor *)globalBarTintColor DEPRECATED_MSG_ATTRIBUTE("Use dynamic colors that are compatible with Dark Mode, e.g., from TripKitUI");
+ (TKColor *)globalSecondaryBarTintColor DEPRECATED_MSG_ATTRIBUTE("Use dynamic colors that are compatible with Dark Mode, e.g., from TripKitUI");
+ (TKColor *)globalViewBackgroundColor DEPRECATED_MSG_ATTRIBUTE("Use dynamic colors that are compatible with Dark Mode, e.g., from TripKitUI");

@end


NS_ASSUME_NONNULL_END
