//
//  SGWebViewController.m
//  TripKit
//
//  Created by Adrian Schoenig on 16/01/2014.
//
//

#import "SGWebViewController.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
#endif

#import <SafariServices/SafariServices.h>

#import "SGActions.h"
#import "SGStylemanager.h"

@interface SGWebViewController () <UIWebViewDelegate>

@property (nonatomic, strong) NSURL *startURL;
@property (nonatomic, strong) NSURL *trackURL;
@property (nonatomic, strong) NSURLRequest *currentRequest;

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIBarButtonItem *backBarItem;
@property (nonatomic, strong) UIBarButtonItem *forwardBarItem;
@property (nonatomic, strong) NSLayoutConstraint *toolbarBottomConstraint;

@end

@implementation SGWebViewController

- (instancetype)initWithURL:(NSURL *)url
{
  return [self initWithTitle:nil URL:url];
}

- (instancetype)initWithTitle:(nullable NSString *)title URL:(NSURL *)url
{
  return [self initWithTitle:title startURL:url trackURL:nil];
}

- (instancetype)initWithStartURL:(NSURL *)url trackURL:(NSURL *)trackURL
{
  return [self initWithTitle:nil startURL:url trackURL:trackURL];
}

- (instancetype)initWithTitle:(nullable NSString *)title startURL:(NSURL *)url trackURL:(NSURL *)trackURL
{
  self = [super init];
  if (self) {
    self.navigationItem.title = title;
    self.startURL = url;
    self.trackURL = trackURL;
  }
  return self;
  
}

- (void)viewDidLoad
{
	[super viewDidLoad];
  
  [self prepareWebview];
  [self showToolbar:NO];
  
	if (nil != self.startURL) {
		NSURLRequest *request = [[NSURLRequest alloc] initWithURL:self.startURL];
		[self.webView loadRequest:request];
	}
  
  if (self.navigationController.childViewControllers.firstObject == self) {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:Loc.Close style:UIBarButtonItemStyleDone target:self action:@selector(closeButtonPressed:)];
  }
  
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonPressed:)];
}

- (void)dealloc
{
  self.webView.delegate = self;
}

#pragma mark - Public methods

- (void)didLoadURL:(NSURL *)url
{
#pragma unused(url)
  // default implementation does nothing;
}

#pragma mark - User interaction

- (IBAction)actionButtonPressed:(id)sender
{
  SGActions *actions = [[SGActions alloc] init];
  NSURL *URL = [self.webView request].URL;
  if (URL.absoluteString.length == 0) {
    URL = self.startURL;
  }
  
  [actions addAction:Loc.OpenInSafari
             handler:
   ^{
     [[UIApplication sharedApplication] openURL:URL];
   }];
  
  [actions showForSender:sender inController:self];
}

- (IBAction)closeButtonPressed:(id)sender
{
#pragma unused(sender)
  if ([self.delegate respondsToSelector:@selector(webViewControllerDidDismiss:)]) {
    [self.delegate webViewControllerDidDismiss:self];
  }
  
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Webview + Toolbar

- (void)prepareWebview
{
  // A webview
  UIWebView *webview = [[UIWebView alloc] init];
  webview.scalesPageToFit = YES;
  webview.delegate = self;
  webview.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view insertSubview:webview atIndex:0];
  self.webView = webview;
  
  // A toolbar
  UIToolbar *toolbar = [[UIToolbar alloc] init];
  toolbar.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:toolbar];
  self.toolbar = toolbar;
  
  // Add buttons to toolbar
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  UIImage *backImage = [UIImage imageNamed:@"icon-arrow-left-black" inBundle:bundle compatibleWithTraitCollection:nil];
  UIImage *forwardImage = [UIImage imageNamed:@"icon-arrow-right-black" inBundle:bundle compatibleWithTraitCollection:nil];
  UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithImage:backImage style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
  UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  UIBarButtonItem *forward = [[UIBarButtonItem alloc] initWithImage:forwardImage style:UIBarButtonItemStylePlain target:self action:@selector(goForward)];
  [toolbar setItems:@[back, space, forward]];
  self.backBarItem = back;
  self.forwardBarItem = forward;
  
  // Layout webview.
  [webview.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
  [webview.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
  [self.view.trailingAnchor constraintEqualToAnchor:webview.trailingAnchor].active = YES;
  
  // Layout tool bar.
  [toolbar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
  [toolbar.topAnchor constraintEqualToAnchor:webview.bottomAnchor].active = YES;
  [self.view.trailingAnchor constraintEqualToAnchor:toolbar.trailingAnchor].active = YES;
  
  // We keep a reference to the bottom constraint so we can adjust it to achieve show/hide effect
  self.toolbarBottomConstraint = [self.view.bottomAnchor constraintEqualToAnchor:toolbar.bottomAnchor];
  self.toolbarBottomConstraint.active = YES;
}

- (void)showToolbar:(BOOL)show
{
  self.toolbarBottomConstraint.constant = show ? 0.0 : -44.0;
  
  [UIView animateWithDuration:0.2
                   animations:
   ^{
     [self.view setNeedsLayout];
     [self.view layoutIfNeeded];
   }
                   completion:
   ^(BOOL finished) {
     self.backBarItem.enabled = [self.webView canGoBack];
     self.forwardBarItem.enabled = [self.webView canGoForward];
   }];
}

- (void)goBack
{
  if ([self.webView canGoBack]) {
    [self.webView goBack];
  }
}

- (void)goForward
{
  if ([self.webView canGoForward]) {
    [self.webView goForward];
  }
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
#pragma unused (webView, navigationType)
  self.currentRequest = request;
  return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
#pragma unused(webView)
  DLog(@"Opening: %@", self.currentRequest.URL.absoluteString);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
  NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
  self.title = title;
  
  [self didLoadURL:self.currentRequest.URL];
  [self showToolbar:[webView canGoBack] || [webView canGoForward]];
  DLog(@"Finished loading: %@", self.currentRequest.URL.absoluteString);
  
  if (self.trackURL
      && [self.delegate respondsToSelector:@selector(webViewController:capturedTrackURL:)]
      && [webView.request.URL.absoluteString containsString:self.trackURL.absoluteString]) {
    [self.delegate webViewController:self capturedTrackURL:self.trackURL];
  }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
#pragma unused(webView, error)
  
  DLog(@"Failed with error: %@", error);
  
  SGActions *actions = [[SGActions alloc] initWithTitle:@"An unexpected error occurred. Please try again later."];
  actions.type = UIAlertControllerStyleAlert;
  [actions showForSender:nil inController:self];
}

@end


@implementation UIViewController (PresentWeb)

- (void)presentWebViewControllerWithURL:(NSURL *)url
                                  title:(NSString *)title
{
  UIViewController *controller = nil;
  if ([SFSafariViewController class]) {
    SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:url];
    safari.delegate = (id<SFSafariViewControllerDelegate>)self;
    controller = safari;
  } else {
    SGWebViewController *webController = [[SGWebViewController alloc] initWithTitle:title URL:url];
    UINavigationController *navigator = [[UINavigationController alloc] initWithRootViewController:webController];
    controller = navigator;
  }
  
  controller.modalPresentationStyle = UIModalPresentationFullScreen;
  [self presentViewController:controller animated:YES completion:nil];
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
#pragma unused(controller)
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
