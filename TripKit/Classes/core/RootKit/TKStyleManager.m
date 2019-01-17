//
//  TKStyleManager.m
//  TripKit
//
//  Created by Adrian Schoenig on 24/10/2013.
//
//

#import "TKStyleManager.h"

#import "TKRootKit.h"

@implementation TKStyleManager

+ (TKColor *)darkTextColor
{
  return [TKColor blackColor];
  //  return [TKColor blueColor];
}

+ (TKColor *)lightTextColor
{
  return [TKColor colorWithWhite:148.f/255 alpha:1];
  //  return [TKColor redColor];
}

+ (NSLocale *)applicationLocale
{
  return [NSLocale currentLocale];
}

#if TARGET_OS_IPHONE
+ (UIButton *)cellAccessoryButtonWithImage:(TKImage *)image
                                    target:(id)target
                                    action:(SEL)selector
{
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
  button.frame = CGRectMake(0, 0, 44, 44);
  imageView.frame = CGRectMake((CGRectGetMaxX(button.frame) - CGRectGetWidth(imageView.frame)) / 2, (CGRectGetMaxY(button.frame) - CGRectGetHeight(imageView.frame)) / 2, CGRectGetWidth(imageView.frame), CGRectGetHeight(imageView.frame));
  [button addSubview:imageView];
  [button addTarget:target
             action:selector
   forControlEvents:UIControlEventTouchUpInside];
  
  return button;
}
#endif

+ (TKImage *)activityImage:(NSString *)partial
{
#if TARGET_OS_IPHONE
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return [self imageNamed:[NSString stringWithFormat:@"icon-actionBar-%@-30", partial]];
  } else {
    return [self imageNamed:[NSString stringWithFormat:@"icon-actionBar-%@-38", partial]];
  }
#else
  return [self imageNamed:[NSString stringWithFormat:@"icon-actionBar-%@-38", partial]];
#endif
}

+ (TKImage *)imageNamed:(NSString *)name
{
  TKImage *image = [self optionalImageNamed:name];
  ZAssert(image, @"Image named '%@' not found", name);
  return image;
}

+ (TKImage *)optionalImageNamed:(NSString *)name
{
  NSBundle *bundle = [self bundle];
#if TARGET_OS_IPHONE
  return [TKImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
#else
  return [bundle imageForResource:name];
#endif
}

+ (NSBundle *)bundle
{
  return [NSBundle bundleForClass:[TKStyleManager class]];
}


#pragma mark - Date formatting

NSString * const kTimeOnlyDateFormatterKey = @"TimeOnlyDateFormatterKey";

+ (NSString *)timeString:(NSDate *)time
             forTimeZone:(NSTimeZone *)timeZone
{
  return [self timeString:time forTimeZone:timeZone relativeToTimeZone:nil];
}

+ (NSString *)timeString:(NSDate *)time
             forTimeZone:(NSTimeZone *)timeZone
      relativeToTimeZone:(NSTimeZone *)relativeTimeZone
{
	NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
	NSDateFormatter *timeOnlyFormatter = [threadDictionary objectForKey:kTimeOnlyDateFormatterKey];
	
	if (!timeOnlyFormatter) {
		timeOnlyFormatter = [[NSDateFormatter alloc] init];
		timeOnlyFormatter.dateStyle = NSDateFormatterNoStyle;
		timeOnlyFormatter.timeStyle = NSDateFormatterShortStyle;
		timeOnlyFormatter.locale    = [TKStyleManager applicationLocale];
    [threadDictionary setObject:timeOnlyFormatter forKey:kTimeOnlyDateFormatterKey];
	}
	
	if (timeZone) {
		timeOnlyFormatter.timeZone = timeZone;
	}
  NSString *string = [timeOnlyFormatter stringFromDate:time];
  NSString *compact = [[string stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
  
  if (relativeTimeZone && timeZone && ![[relativeTimeZone abbreviationForDate:time] isEqualToString:[timeZone abbreviationForDate:time]]) {
    return [NSString stringWithFormat:@"%@ (%@)", compact, [timeZone abbreviationForDate:time]];
  } else {
    return compact;
  }
}

NSString * const kDateOnlyDateFormatterKey = @"DateOnlyDateFormatterKey";

+ (NSString *)dateString:(NSDate *)time
						 forTimeZone:(NSTimeZone *)timeZone
{
	NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
	NSDateFormatter *dateOnlyFormatter = [threadDictionary objectForKey:kDateOnlyDateFormatterKey];
	
	if (nil == dateOnlyFormatter) {
		dateOnlyFormatter = [[NSDateFormatter alloc] init];
		dateOnlyFormatter.dateStyle = NSDateFormatterFullStyle;
		dateOnlyFormatter.timeStyle = NSDateFormatterNoStyle;
		dateOnlyFormatter.doesRelativeDateFormatting = YES;
		dateOnlyFormatter.locale    = [TKStyleManager applicationLocale];
		[threadDictionary setObject:dateOnlyFormatter forKey:kDateOnlyDateFormatterKey];
	}
	
	if (nil != timeZone) {
		dateOnlyFormatter.timeZone = timeZone;
	}
  
	return [[dateOnlyFormatter stringFromDate:time] capitalizedStringWithLocale:dateOnlyFormatter.locale];
}

NSString * const kDateTimeDateFormatterKey = @"DateTimeDateFormatterKey";

+ (NSString *)stringForDate:(NSDate *)date
                forTimeZone:(NSTimeZone *)timeZone
                   showDate:(BOOL)showDate
                   showTime:(BOOL)showTime
{
  NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
	NSDateFormatter *formatter = [threadDictionary objectForKey:kDateTimeDateFormatterKey];
	
	if (nil == formatter) {
		formatter = [[NSDateFormatter alloc] init];
		[threadDictionary setObject:formatter forKey:kDateTimeDateFormatterKey];
	}
  
  formatter.timeStyle = showTime ? NSDateFormatterShortStyle : NSDateFormatterNoStyle;
  formatter.dateStyle = showDate ? NSDateFormatterMediumStyle : NSDateFormatterNoStyle;
  formatter.locale    = [TKStyleManager applicationLocale];
	
	if (nil != timeZone) {
		formatter.timeZone = timeZone;
	}
	
	return [formatter stringFromDate:date];
}

+ (NSString *)stringForDate:(NSDate *)date
                forTimeZone:(NSTimeZone *)timeZone
                forceFormat:(NSString *)format
{
  return [self stringForDate:date forTimeZone:timeZone forceFormat:format orStyle:NSDateFormatterNoStyle];
}

+ (NSString *)stringForDate:(NSDate *)date
                forTimeZone:(NSTimeZone *)timeZone
                 forceStyle:(NSDateFormatterStyle)style
{
  return [self stringForDate:date forTimeZone:timeZone forceFormat:nil orStyle:style];
}

+ (NSString *)stringForDate:(NSDate *)date
                forTimeZone:(NSTimeZone *)timeZone
                forceFormat:(NSString *)format
                    orStyle:(NSDateFormatterStyle)style
{
  NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
	NSDateFormatter *formatter = [threadDictionary objectForKey:kDateTimeDateFormatterKey];
	
	if (nil == formatter) {
		formatter = [[NSDateFormatter alloc] init];
		[threadDictionary setObject:formatter forKey:kDateTimeDateFormatterKey];
	}
  
  formatter.locale    = [TKStyleManager applicationLocale];
  if (format) {
    formatter.dateFormat = format;
  } else {
    formatter.dateFormat = nil;
    formatter.dateStyle = style;
  }
  
	if (nil != timeZone) {
		formatter.timeZone = timeZone;
	}
	
	return [formatter stringFromDate:date];
}

@end

@implementation TKStyleManager (Color)

+ (TKColor *)globalTintColor
{
  NSDictionary *RGBs = [[TKConfig sharedInstance] globalTintColor];
  return [TKColor colorWithRed:[self redComponent:RGBs] green:[self greenComponent:RGBs] blue:[self blueComponent:RGBs] alpha:1];
}

+ (TKColor *)globalBarTintColor
{
  NSDictionary *RGBs = [[TKConfig sharedInstance] globalBarTintColor];
  return [TKColor colorWithRed:[self redComponent:RGBs] green:[self greenComponent:RGBs] blue:[self blueComponent:RGBs] alpha:1];
  
}

+ (TKColor *)globalSecondaryBarTintColor
{
  NSDictionary *RGBs = [[TKConfig sharedInstance] globalSecondaryBarTintColor];
  return [TKColor colorWithRed:[self redComponent:RGBs] green:[self greenComponent:RGBs] blue:[self blueComponent:RGBs] alpha:1];
}

+ (TKColor *)globalAccentColor
{
  NSDictionary *RGBs = [[TKConfig sharedInstance] globalAccentColor];
  return [TKColor colorWithRed:[self redComponent:RGBs] green:[self greenComponent:RGBs] blue:[self blueComponent:RGBs] alpha:1];
}

+ (TKColor *)globalViewBackgroundColor
{
  NSDictionary *RGBs = [[TKConfig sharedInstance] globalViewBackgroundColor];
  if (RGBs != nil) {
    return [TKColor colorWithRed:[self redComponent:RGBs] green:[self greenComponent:RGBs] blue:[self blueComponent:RGBs] alpha:1];
  } else {
    // This is the color used in TripGo.
    return [TKColor colorWithRed:237/255.0f green:238/255.0f blue:242/255.0f alpha:1];
  }
}

+ (BOOL)globalTranslucency
{
  return [[TKConfig sharedInstance] globalTranslucency];
}

#pragma mark - Private

+ (CGFloat)redComponent:(NSDictionary *)RGB
{
  NSUInteger red = [RGB[@"Red"] integerValue];
  return red/255.0f;
}

+ (CGFloat)greenComponent:(NSDictionary *)RGB
{
  NSUInteger green = [RGB[@"Green"] integerValue];
  return green/255.0f;
}

+ (CGFloat)blueComponent:(NSDictionary *)RGB
{
  NSUInteger blue = [RGB[@"Blue"] integerValue];
  return blue/255.0f;
}

@end
