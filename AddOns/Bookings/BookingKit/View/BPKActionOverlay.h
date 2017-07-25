//
//  BPKActionOverlay.h
//  TripKit
//
//  Created by Kuan Lun Huang on 16/03/2015.
//
//

@import UIKit;

#ifdef TK_NO_MODULE
#import "SGButton.h"
#else
@import TripKitUI;
#endif

@interface BPKActionOverlay : UIView

@property (weak, nonatomic) IBOutlet SGButton *button;

+ (void)showWithTitle:(NSString *)title inView:(UIView *)view onAction:(void(^)())actionBlock completion:(void(^)(BOOL))completion;

- (instancetype)initWithTitle:(NSString *)title actionBlock:(void(^)())actionBlock;
- (void)showInView:(UIView *)view completion:(void(^)(BOOL))completion;

@end
