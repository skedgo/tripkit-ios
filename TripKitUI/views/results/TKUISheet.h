//
//  TKUISheet.h
//  TripKit
//
//  Created by Adrian Schoenig on 10/04/2014.
//
//

@import UIKit;

@interface TKUISheet : UIView

@property (nonatomic, strong) UIButton *floatingButton;

- (void)showWithOverlayInView:(UIView *)inView;

- (void)showWithOverlayInView:(UIView *)inView
                    belowView:(UIView *)belowView
                       hiding:(NSArray *)additionalViews;

- (void)removeOverlay:(BOOL)animated;

- (BOOL)isBeingOverlaid;

- (IBAction)tappedOverlay:(id)sender;

- (IBAction)doneButtonPressed:(id)sender;

@end
