//
//  BPKWebViewController.m
//  TripGo
//
//  Created by Kuan Lun Huang on 18/03/2015.
//
//

#import "BPKWebViewController.h"

#ifdef TK_NO_FRAMEWORKS
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#endif


@interface BPKWebViewController ()

@end

@implementation BPKWebViewController

@dynamic delegate;

#pragma mark - Overrides

- (void)didLoadURL:(NSURL *)url
{
  [self autoZoom];
  
  if (url != nil && self.isForOAuth) {
    BOOL isSkedGo = [url.host rangeOfString:@"skedgo.com"].location != NSNotFound;
    if (isSkedGo) {
      BOOL isOAuth = url.query && [url.query rangeOfString:@"oauth_token"].location != NSNotFound;
      if (isOAuth) {
        [self.delegate webControllerDidFinishOauthWithSuccess:YES];
      } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"An unexpected error occurred. Please try again later." delegate:nil cancelButtonTitle:Loc.OK otherButtonTitles:nil];
        [alertView show];
      }
    }
  }
  
}

#pragma mark - Private methods

- (void)autoZoom
{
  NSString *js =
  @"var meta = document.createElement('meta'); " \
  "meta.setAttribute( 'name', 'viewport' ); " \
  "meta.setAttribute( 'content', 'width = device-width, initial-scale=1.0, minimum-scale=0.2, maximum-scale=5.0; user-scalable=1;' ); " \
  "document.getElementsByTagName('head')[0].appendChild(meta)";
  
  [self.webView stringByEvaluatingJavaScriptFromString:js];
}

@end
