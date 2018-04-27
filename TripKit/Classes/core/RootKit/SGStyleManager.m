//
//  SGStyleManager.m
//  TripKit
//
//  Created by Adrian Schoenig on 24/10/2013.
//
//

#import "SGStyleManager.h"

#import "SGRootKit.h"

@implementation SGStyleManager

+ (SGKColor *)darkTextColor
{
  return [SGKColor blackColor];
  //  return [SGKColor blueColor];
}

+ (SGKColor *)lightTextColor
{
  return [SGKColor colorWithWhite:148.f/255 alpha:1];
  //  return [SGKColor redColor];
}

+ (NSLocale *)applicationLocale
{
  return [NSLocale currentLocale];
}

#if TARGET_OS_IPHONE
+ (UIButton *)cellAccessoryButtonWithImage:(SGKImage *)image
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

+ (SGKImage *)activityImage:(NSString *)partial
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

+ (SGKImage *)imageNamed:(NSString *)name
{
  SGKImage *image = [self optionalImageNamed:name];
  ZAssert(image, @"Image named '%@' not found", name);
  return image;
}

+ (SGKImage *)optionalImageNamed:(NSString *)name
{
  NSBundle *bundle = [self bundle];
#if TARGET_OS_IPHONE
  return [SGKImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
#else
  return [bundle imageForResource:name];
#endif
}

+ (NSBundle *)bundle
{
  return [NSBundle bundleForClass:[SGStyleManager class]];
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
		timeOnlyFormatter.locale    = [SGStyleManager applicationLocale];
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
		dateOnlyFormatter.locale    = [SGStyleManager applicationLocale];
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
  formatter.locale    = [SGStyleManager applicationLocale];
	
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
  
  formatter.locale    = [SGStyleManager applicationLocale];
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

@implementation SGStyleManager (Color)

+ (SGKColor *)globalTintColor
{
  NSDictionary *RGBs = [[SGKConfig sharedInstance] globalTintColor];
  return [SGKColor colorWithRed:[self redComponent:RGBs] green:[self greenComponent:RGBs] blue:[self blueComponent:RGBs] alpha:1];
}

+ (SGKColor *)globalBarTintColor
{
  NSDictionary *RGBs = [[SGKConfig sharedInstance] globalBarTintColor];
  return [SGKColor colorWithRed:[self redComponent:RGBs] green:[self greenComponent:RGBs] blue:[self blueComponent:RGBs] alpha:1];
  
}

+ (SGKColor *)globalSecondaryBarTintColor
{
  NSDictionary *RGBs = [[SGKConfig sharedInstance] globalSecondaryBarTintColor];
  return [SGKColor colorWithRed:[self redComponent:RGBs] green:[self greenComponent:RGBs] blue:[self blueComponent:RGBs] alpha:1];
}

+ (SGKColor *)globalAccentColor
{
  NSDictionary *RGBs = [[SGKConfig sharedInstance] globalAccentColor];
  return [SGKColor colorWithRed:[self redComponent:RGBs] green:[self greenComponent:RGBs] blue:[self blueComponent:RGBs] alpha:1];
}

+ (BOOL)globalTranslucency
{
  return [[SGKConfig sharedInstance] globalTranslucency];
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
