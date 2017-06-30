//
//  BPKWebViewController.h
//  TripGo
//
//  Created by Kuan Lun Huang on 18/03/2015.
//
//

#ifdef TK_NO_FRAMEWORKS
#import "SGWebViewController.h"
#else
@import TripKitUI;
#endif

@protocol BPKWebViewControllerDelegate <SGWebViewControllerDelegate>

- (void)webControllerDidFinishOauthWithSuccess:(BOOL)success;

@end

@interface BPKWebViewController : SGWebViewController

@property (nonatomic, weak) id<BPKWebViewControllerDelegate> delegate;

@property (nonatomic, assign) BOOL isForOAuth;

@end

