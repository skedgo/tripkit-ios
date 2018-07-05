//
//  SGStyleManager.h
//  TripKit
//
//  Created by Adrian Schoenig on 24/10/2013.
//
//

@import CoreLocation;
#import "SGKCrossPlatform.h"


typedef NS_ENUM(NSInteger, SGStyleModeIconType) {
	SGStyleModeIconTypeListMainMode,
  SGStyleModeIconTypeListMainModeOnDark,
  SGStyleModeIconTypeMapIcon,
  SGStyleModeIconTypeResolutionIndependent, // SVGs! You probably need SVGKit to handle these.
  SGStyleModeIconTypeResolutionIndependentOnDark, // SVGs! You probably need SVGKit to handle these.
  SGStyleModeIconTypeVehicle,
  SGStyleModeIconTypeAlert,
};

NS_ASSUME_NONNULL_BEGIN
@interface SGStyleManager : NSObject

+ (NSLocale *)applicationLocale;

+ (SGKColor *)darkTextColor;

+ (SGKColor *)lightTextColor;

#if TARGET_OS_IPHONE
+ (UIButton *)cellAccessoryButtonWithImage:(UIImage *)image
                                    target:(nullable id)target
                                    action:(nullable SEL)selector;
#endif

#pragma mark - Image names

+ (SGKImage *)activityImage:(NSString *)partial;

+ (SGKImage *)imageNamed:(NSString *)name;

+ (nullable SGKImage *)optionalImageNamed:(NSString *)name;

+ (NSBundle *)bundle;

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

@interface SGStyleManager (Color)

+ (SGKColor *)globalTintColor;
+ (SGKColor *)globalBarTintColor;
+ (SGKColor *)globalSecondaryBarTintColor;
+ (SGKColor *)globalAccentColor;
+ (BOOL)globalTranslucency;

@end


NS_ASSUME_NONNULL_END
