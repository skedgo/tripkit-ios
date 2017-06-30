//
//  BPKWebViewController.h
//  TripGo
//
//  Created by Kuan Lun Huang on 18/03/2015.
//
//

#ifndef TK_NO_FRAMEWORKS
@import SGUIKit;
#else
#import "SGWebViewController.h"
#endif

@protocol BPKWebViewControllerDelegate <SGWebViewControllerDelegate>

- (void)webControllerDidFinishOauthWithSuccess:(BOOL)success;

@end

@interface BPKWebViewController : SGWebViewController

@property (nonatomic, weak) id<BPKWebViewControllerDelegate> delegate;

@property (nonatomic, assign) BOOL isForOAuth;

@end

