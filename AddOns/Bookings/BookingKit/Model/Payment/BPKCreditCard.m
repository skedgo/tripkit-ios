//
//  SGBPCreditCard.m
//  TripGo
//
//  Created by Brian Huang on 5/02/2015.
//
//

#import "BPKCreditCard.h"

#import "BPKUser.h"

//#import <Stripe/Stripe.h>

@interface BPKCreditCard ()

@end

@implementation BPKCreditCard

#pragma mark - Public methods

- (instancetype)initWithUser:(BPKUser *)user
{
  return [self initWithCardNo:user.cardNo expiryDate:user.expiryDate cvc:user.cvc];
}

- (instancetype)initWithCardNo:(NSString *)cardNo expiryDate:(NSString *)expiryDate cvc:(NSString *)cvc
{
  self = [self init];
  
  if (self) {
    _cardNo = cardNo;
    _expiryDate = expiryDate;
    _cvc = cvc;
  }
  
  return self;
}

+ (BOOL)isValidCardNo:(NSString *)cardNo
{
#warning TODO: fix this up
  return YES;
//  return [STPCardValidator validationStateForNumber:cardNo validatingCardBrand:NO] == STPCardValidationStateValid;
}

+ (NSString *)formattedCardNo:(NSString *)cardNo
{
#warning TODO: fix this up
//  return [[PTKCardNumber cardNumberWithString:cardNo] formattedString];
  return cardNo;
}

+ (BOOL)isValidExpiryDate:(NSString *)expiryDate
{
#warning TODO: fix this up
  //  return [[PTKCardExpiry cardExpiryWithString:expiryDate] isValid];
  return YES;
}

+ (NSString *)formattedExpiryDate:(NSString *)expiryDate
{
#warning TODO: fix this up
  //  return [[PTKCardExpiry cardExpiryWithString:expiryDate] formattedString];
  return expiryDate;
}

+ (BOOL)isValidCVC:(NSString *)cvc
{
#warning TODO: fix this up
  return YES;
//return [STPCardValidator validationStateForCVC:cvc cardBrand:STPCardBrandUnknown];
    return YES;
}

- (NSUInteger)expiryYear
{
  if (! _expiryDate) {
    return 0;
  }

#warning TODO: fix this up
//  return [[PTKCardExpiry cardExpiryWithString:_expiryDate] year];
  return 0;
}

- (NSUInteger)expiryMonth
{
  if (! _expiryDate) {
    return 0;
  }
  
#warning TODO: fix this up
//  return [[PTKCardExpiry cardExpiryWithString:_expiryDate] month];
  return 0;
}

- (void)printCard
{
  DLog(@"card no: %@, expiry date: %@, cvc: %@", _cardNo, _expiryDate, _cvc);
}

#pragma mark - Custom accessors

- (void)setCardNo:(NSString *)cardNo
{
  _cardNo = [[self class] formattedCardNo:cardNo];
}

- (void)setExpiryDate:(NSString *)expiryDate
{
  _expiryDate = [[self class] formattedExpiryDate:expiryDate];
}

@end
