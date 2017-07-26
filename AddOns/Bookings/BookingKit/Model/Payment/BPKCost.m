//
//  BPKCostValidator.m
//  TripKit
//
//  Created by Kuan Lun Huang on 6/02/2015.
//
//

#import "BPKCost.h"

#import "BPKConstants.h"

typedef NS_ENUM(NSInteger, PaymentTypes) {
  PaymentTypePaypal,
  PaymentTypeCreditCard
};

@interface BPKCost ()

@property (nonatomic, strong) NSDictionary *json;
@property (nonatomic, strong) NSArray *paymentTypes;

@end

@implementation BPKCost

- (instancetype)initWithJSON:(NSDictionary *)json
{
  self = [super init];
  
  if (self) {
    _json = json;
    DLog(@"initialized with JSON; %@", json);
  }
  
  return self;
}

- (double)cost
{
  ZAssert([self isValidCost], @"Invalid cost JSON");
  
  return [[_json objectForKey:kBPKPaymentCost] doubleValue];
}

#pragma mark - Lazy accessors

- (NSArray *)paymentTypes
{
  ZAssert([self isValidCost], @"Invalid cost JSON");
  
  if (! _paymentTypes) {
    NSArray *acceptedTypes = [_json objectForKey:kBPKPaymentType];
    NSMutableArray *types = [NSMutableArray arrayWithCapacity:acceptedTypes.count];
    for (NSString *type in acceptedTypes) {
      if ([[self class] isCreditCardPaymentType:type]) {
        [types addObject:@(PaymentTypeCreditCard)];
        
      } else if ([[self class] isPaypalPaymentType:type]) {
        [types addObject:@(PaymentTypePaypal)];
      }
    }
    _paymentTypes = types;
  }
  
  return _paymentTypes;
}

- (BOOL)acceptCreditCard
{
  return [self.paymentTypes indexOfObject:@(PaymentTypeCreditCard)] != NSNotFound;
}

- (BOOL)acceptPaypal
{
  return [self.paymentTypes indexOfObject:@(PaymentTypePaypal)] != NSNotFound;
}

#pragma mark - Private methods

- (BOOL)isValidCost
{
  if (! _json) {
    return NO;
  }
  
  if (! [_json objectForKey:kBPKPaymentType]) {
    return NO;
  }
  
  if (! [_json objectForKey:kBPKPaymentCost]) {
    return NO;
  }
  
  return YES;
}

 + (BOOL)isCreditCardPaymentType:(NSString *)type
{
  return [type caseInsensitiveCompare:kBPKPaymentTypeCC] == NSOrderedSame;
}

+ (BOOL)isPaypalPaymentType:(NSString *)type
{
  return [type caseInsensitiveCompare:kBPKPaymentTypePaypal] == NSOrderedSame;
}

@end
