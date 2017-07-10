//
//  BPKPaymentTestViewController.m
//  TripGo
//
//  Created by Kuan Lun Huang on 2/11/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "BPKPaymentTestViewController.h"

#ifdef BRAINTREE
#import <Braintree/Braintree.h>

@interface BPKPaymentTestViewController () <BTDropInViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *button;

@property (nonatomic, strong) Braintree *braintree;

@property (nonatomic, assign) BOOL hasReceivedClientToken;
@property (nonatomic, assign) BOOL hasReceivedPaymentNonce;
@property (nonatomic, assign) BOOL hasSentPaymentNonce;

@property (nonatomic, copy) NSString *paymentNonce;

@end
#endif

@implementation BPKPaymentTestViewController

#ifdef BRAINTREE
- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.button.alpha = 0;
  
  NSURL *clientTokenURL = [NSURL URLWithString:@"https://braintree-sample-merchant.herokuapp.com/client_token"];
  NSMutableURLRequest *clientTokenRequest = [NSMutableURLRequest requestWithURL:clientTokenURL];
  [clientTokenRequest setValue:@"text/plain" forHTTPHeaderField:@"Accept"];
  
  [[[NSURLSession sharedSession] dataTaskWithRequest:clientTokenRequest
                                   completionHandler:
    ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
      // TODO: Handle errors
      NSString *clientToken = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      
      // Initialize `Braintree` once per checkout session
      self.braintree = [Braintree braintreeWithClientToken:clientToken];
      self.hasReceivedClientToken = YES;
      
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.button setAlpha:1.0f];
        [self.button setTitle:@"Get payment nonce" forState:UIControlStateNormal];
      });
      
      // As an example, you may wish to present our Drop-In UI at this point.
      // Continue to the next section to learn more...
  }] resume];
}

- (IBAction)paymentButtonPressed:(id)sender
{
#pragma unused(sender)
  if (self.hasReceivedClientToken) {
    if (self.hasReceivedPaymentNonce == NO) {
      [self presentBraintreeDropInUI];
    } else {
      if (self.hasSentPaymentNonce == NO) {
        [self sendPaymentNonce:self.paymentNonce];
      }
    }
  }
}

#pragma mark - Drop in UI

- (void)presentBraintreeDropInUI
{
  if (self.hasReceivedClientToken == NO) {
    return;
  }
  
  BTDropInViewController *dropInVC = [self.braintree dropInViewControllerWithDelegate:self];
  dropInVC.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                               initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                               target:self
                                               action:@selector(dismissDropInUI:)];
  
  UINavigationController *navCtr = [[UINavigationController alloc] initWithRootViewController:dropInVC];
  [self presentViewController:navCtr animated:YES completion:nil];
}

#pragma mark - BTDropInViewControllerDelegate

- (void)dropInViewController:(BTDropInViewController *)viewController didSucceedWithPaymentMethod:(BTPaymentMethod *)paymentMethod
{
#pragma unused(viewController)
  [self dismissViewControllerAnimated:YES completion:^{
    [self.button setTitle:@"Send payment nonce" forState:UIControlStateNormal];
    self.hasReceivedPaymentNonce = YES;
    self.paymentNonce = paymentMethod.nonce;
  }];
}

- (void)dropInViewControllerDidCancel:(BTDropInViewController *)viewController
{
#pragma unused(viewController)
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - User interactions

- (void)dismissDropInUI:(id)sender
{
#pragma unused(sender)
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)sendPaymentNonce:(NSString *)nonce
{
  DLog(@"Sending %@", nonce);
  self.hasSentPaymentNonce = YES;
  [self.button setTitle:@"Sent" forState:UIControlStateNormal];
}
#endif

@end
