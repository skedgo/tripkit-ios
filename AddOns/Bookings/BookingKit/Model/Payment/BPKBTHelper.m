//
//  BPKBTHelper.m
//  TripGo
//
//  Created by Kuan Lun Huang on 12/11/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "BPKBTHelper.h"

#ifdef BRAINTREE
#import <Braintree/Braintree.h>

#import "BPKServerUtil.h"

@interface BPKBTHelper () <BTDropInViewControllerDelegate>

@property (nonatomic, strong) Braintree *client;
@property (nonatomic, strong) NSURL *initiatingURL;
@property (nonatomic, weak) UIViewController *dropInFormPresentingController;
@property (nonatomic, copy) void(^paymentCompletionHandler)(BPKForm *, NSError *);

@end

@implementation BPKBTHelper

- (instancetype)initWithURL:(NSURL *)url
{
  self = [super init];
  
  if (self) {
    self.initiatingURL = url;
  }
  
  return self;
}

- (void)makePaymentOverController:(UIViewController *)controller
                       completion:(void (^)(BPKForm *, NSError *))completion
{
  if (! self.initiatingURL) {
    return;
  }
  
  self.paymentCompletionHandler = completion;
  
  __weak typeof(controller) weakCtr = controller;
  
  // First, we get client token
  [BPKServerUtil requestFormForBookingURL:self.initiatingURL
                                 postData:nil
                               completion:
   ^(NSDictionary *responseObject, NSError *error) {
     if (error != nil) {
       if (completion) {
         completion(nil, error);
       }
     } else {
       if ([self.delegate respondsToSelector:@selector(btHelperWillLoadPaymentForm:)]) {
         [self.delegate btHelperWillLoadPaymentForm:self];
       }
       
       NSString *token = [self tokenFromResponse:responseObject];
       if (token.length > 0) {
         // We have a valid token, initialise BT client.
         self.client = [Braintree braintreeWithClientToken:token];
         
         __strong typeof(weakCtr) strongCtr = weakCtr;
         // Present the Braintree drop in payment UI.
         [self showDropInFormOverController:strongCtr];
         
       } else {
         
       }
     }
   }];
}

#pragma mark - Private

- (nullable NSString *)tokenFromResponse:(NSDictionary *)response
{
  return [response objectForKey:@"token"];
}

- (void)showDropInFormOverController:(UIViewController *)controller
{
  if (! controller) {
    return;
  }
  
  self.dropInFormPresentingController = controller;
  
  BTDropInViewController *dropInForm = [self.client dropInViewControllerWithDelegate:self];
  dropInForm.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                 target:self
                                                 action:@selector(terminateBraintreePaymentProcess:)];
  
  UINavigationController *dropInFormWrapper = [[UINavigationController alloc] initWithRootViewController:dropInForm];
  [controller presentViewController:dropInFormWrapper animated:YES completion:nil];
}

#pragma mark - User interactions

- (void)terminateBraintreePaymentProcess:(id)sender
{
#pragma unused (sender)
  if (self.dropInFormPresentingController) {
    [self.dropInFormPresentingController dismissViewControllerAnimated:YES completion:nil];
  }
}

#pragma mark - BTDropInViewControllerDelegate

- (void)dropInViewController:(BTDropInViewController *)viewController didSucceedWithPaymentMethod:(BTPaymentMethod *)paymentMethod
{
#pragma unused (viewController)
  NSString *nonce = paymentMethod.nonce;
  if (nonce.length > 0) {
    NSDictionary *postData = @{@"nonce": nonce};
    [BPKServerUtil requestFormForBookingURL:self.initiatingURL
                                   postData:postData
                                 completion:
     ^(NSDictionary *responseObject, NSError *error) {
       [self.dropInFormPresentingController dismissViewControllerAnimated:YES completion:nil];
       if (error != nil) {
         if (self.paymentCompletionHandler) {
           self.paymentCompletionHandler(nil, error);
         }
       } else {
         BPKForm *statusForm = [[BPKForm alloc] initWithJSON:responseObject];
         if (self.paymentCompletionHandler) {
           self.paymentCompletionHandler(statusForm, nil);
         }
       }
     }];
  }
}

- (void)dropInViewControllerDidCancel:(BTDropInViewController *)viewController
{
#pragma unused (viewController)
  [self.dropInFormPresentingController dismissViewControllerAnimated:YES completion:nil];
}

@end

#endif
