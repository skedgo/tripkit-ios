//
//  BPKManager.m
//  TripKit
//
//  Created by Brian Huang on 30/01/2015.
//
//

#import "BPKManager.h"

#import "BPKHelpers.h"

// Contacting server
//#import "BPKServerUtil.h"

// Showing HUD
#import <KVNProgress/KVNProgress.h>

// payment
#import "BPKUser.h"
#import "BPKCost.h"
#import "BPKBTHelper.h"
#import "BPKCreditCard.h"
//#import <Stripe/Stripe.h>

#ifdef BRAINTREE
@interface BPKManager () <BPKBTHelperDelegate>

@property (nonatomic, strong) BPKBTHelper *btHelper;

@end
#endif

@implementation BPKManager

- (instancetype)init
{
  self = [super init];
  
  if (self) {
    _wantsReminder = NO;
    _reminderHeadway = 3;
  }
  
  return self;
}

#ifdef BRAINTREE

#pragma mark - Request payment

+ (void)requestPaymentFromUser:(BPKUser *)user
                       forCost:(BPKCost *)cost
                        hitURL:(NSURL *)url
                    completion:(SVKServerCompletionBlock)completion
{
  BPKCreditCard *card = user.selectedCard;
  
  NSError *cardError;
  STPCard *stpCard = [self stripeCardFromBpkCard:card];
  if (! [stpCard validateCardReturningError:&cardError]) {
    if (completion) {
      completion(nil, cardError);
    }
  } else {
    [KVNProgress show];
    
    STPAPIClient *cardClient = [[STPAPIClient alloc] init];
    [cardClient createTokenWithCard:stpCard
                         completion:
     ^(STPToken *token, NSError *error) {
       [KVNProgress dismiss];
       
       if (token != nil) {
         [self usingStripeToken:token toPayForCost:cost hitURL:url completion:completion];
       } else {
         if (completion) {
           completion(nil, error);
         }
       }
     }];
  }
}

#pragma mark - Braintree

- (void)requestPaymentWithInitiatingURL:(NSURL *)url
                         fromController:(UIViewController *)controller
                             completion:(void (^)(BPKForm *, NSError *))completion
{
  [KVNProgress show];
  
  BPKBTHelper *helper = [[BPKBTHelper alloc] initWithURL:url];
  helper.delegate = self;
  [helper makePaymentOverController:controller
                         completion:
   ^(BPKForm *statusForm, NSError *error) {
    if (error != nil) {
      if (completion) {
        completion(nil, error);
      }
    } else {
      if (completion) {
        completion(statusForm, nil);
      }
    }
   }];
  
  // retain helper
  self.btHelper = helper;
}

#pragma mark - BPKBTHelperDelegate

- (void)btHelperWillLoadPaymentForm:(BPKBTHelper *)helper
{
#pragma unused (helper)
  
  // Dismiss any progress indicator before loading the payment form.
  [KVNProgress dismiss];
}

#pragma mark - Private: credit card payment

+ (STPCard *)stripeCardFromBpkCard:(BPKCreditCard *)card
{
  STPCard *stpCard = [[STPCard alloc] init];
  stpCard.number = card.cardNo;
  stpCard.expMonth = card.expiryMonth;
  stpCard.expYear = card.expiryYear;
  stpCard.cvc = card.cvc;
  return stpCard;
}

+ (void)usingStripeToken:(STPToken *)token
            toPayForCost:(BPKCost *)cost
                  hitURL:(NSURL *)url
              completion:(SVKServerCompletionBlock)completion
{
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  [params setObject:@(cost.cost) forKey:@"amount"];
  [params setObject:token.tokenId forKey:@"token"];
  
  [KVNProgress showWithStatus:NSLocalizedStringFromTableInBundle(@"Making payment", @"Shared", [SGStyleManager bundle], @"Indicating a payment is in progress")];
  
  [BPKServer requestFormForBookingURL:url
                             postData:params
                           completion:
   ^(NSDictionary *response, NSError *error) {
     [KVNProgress showSuccessWithStatus:NSLocalizedStringFromTableInBundle(@"Payment successful", @"Shared", [SGStyleManager bundle], @"Indicating a payment is successful")];
     
     if (completion) {
       completion(response, error);
     }
   }];
}

#endif

@end
