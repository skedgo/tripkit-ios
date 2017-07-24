//
//  NSNumber+Formatter.m
//  TripKit
//
//  Created by Adrian Schönig on 18/01/12.
//  Copyright (c) 2012 SkedGo. All rights reserved.
//

#import "NSNumber+Formatter.h"

#import "SGStylemanager.h"

@implementation NSNumber (Formatter)

- (NSString *)toMoneyString:(NSString *)currencySymbol
{
  double dollars = ceil([self floatValue]);
  if (dollars < 1) {
    return NSLocalizedStringFromTableInBundle(@"Free", @"Shared", [SGStyleManager bundle], "Free as in beer");
  } else {
    if (! currencySymbol) {
      currencySymbol = @"$";
    }
    
    NSNumberFormatter *formatter = [[self class] numberFormatter];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    formatter.currencySymbol = currencySymbol;
    formatter.roundingIncrement = @(1);
    return [formatter stringFromNumber:self];
  }
}

- (NSString *)toCarbonString
{
//TODO: Use NSMassFormatter in iOS 8 - http://nshipster.com/nsformatter/
  
  if ([self floatValue] == 0.0) {
    return NSLocalizedStringFromTableInBundle(@"No CO₂", @"Shared", [SGStyleManager bundle], nil);
  } else {
    NSNumberFormatter *formatter = [[self class] numberFormatter];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.currencySymbol = nil;
    formatter.roundingIncrement = @(0.1);
    return [NSString stringWithFormat:@"%@kg CO₂", [formatter stringFromNumber:self]];
  }
}

#pragma mark - Helpers

+ (NSNumberFormatter *)numberFormatter {
  static NSNumberFormatter *_numberFormatter = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _numberFormatter = [[NSNumberFormatter alloc] init];
    _numberFormatter.locale = [NSLocale currentLocale];
    _numberFormatter.maximumSignificantDigits = 2;
    _numberFormatter.usesSignificantDigits = YES;
    _numberFormatter.roundingMode = NSNumberFormatterRoundUp;
  });
  
  return _numberFormatter;
}

@end
