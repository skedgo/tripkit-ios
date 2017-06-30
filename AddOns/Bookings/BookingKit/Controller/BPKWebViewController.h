//
//  BPKWebViewController.h
//  TripGo
//
//  Created by Kuan Lun Huang on 18/03/2015.
//
//

#import "SGWebViewController.h"

@protocol BPKWebViewControllerDelegate <SGWebViewControllerDelegate>

- (void)webControllerDidFinishOauthWithSuccess:(BOOL)success;

@end

@interface BPKWebViewController : SGWebViewController

@property (nonatomic, weak) id<BPKWebViewControllerDelegate> delegate;

@property (nonatomic, assign) BOOL isForOAuth;

@end

