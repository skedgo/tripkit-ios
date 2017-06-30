//
//  SGWebViewController.h
//  TripGo
//
//  Created by Adrian Schoenig on 16/01/2014.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SGWebViewControllerDelegate;

@interface SGWebViewController : UIViewController

@property (nonatomic, weak) id<SGWebViewControllerDelegate> delegate;

- (instancetype)initWithURL:(NSURL *)url;

- (instancetype)initWithTitle:(nullable NSString *)title URL:(NSURL *)url;

- (instancetype)initWithTitle:(nullable NSString *)title startURL:(NSURL *)url trackURL:(nullable NSURL *)trackURL;

- (instancetype)initWithStartURL:(NSURL *)url trackURL:(NSURL *)trackURL;

// For sub classes

- (void)didLoadURL:(NSURL *)url;

- (UIWebView *)webView;

- (UIToolbar *)toolbar;

@end

@interface UIViewController (PresentWeb)

- (void)presentWebViewControllerWithURL:(NSURL *)url
                                  title:(nullable NSString *)title;

@end

@protocol SGWebViewControllerDelegate <NSObject>

@optional

- (void)webViewController:(SGWebViewController *)ctr capturedTrackURL:(NSURL *)url;

- (void)webViewControllerDidDismiss:(SGWebViewController *)ctr;


@end

NS_ASSUME_NONNULL_END
