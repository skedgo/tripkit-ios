//
//  TKUISheet.m
//  TripGo
//
//  Created by Adrian Schoenig on 10/04/2014.
//
//

#import "TKUISheet.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#endif

#import "TripKit/TripKit-Swift.h"

@interface TKUISheet ()

@property (nonatomic, strong) NSArray *overlays;

@end

@implementation TKUISheet

- (void)removeOverlay:(BOOL)animated
{
	if (! self.overlays) {
		return;
	}
	
	if (animated) {
		[UIView animateWithDuration:0.25f animations:^{
      for (UIView *overlay in self.overlays) {
        overlay.alpha = 0.0;
      }
			CGRect endFrame = self.frame;
			endFrame.origin.y += endFrame.size.height;
			self.frame = endFrame;
      
      if (self.floatingButton) {
        CGRect floatyEndFrame = self.floatingButton.frame;
        floatyEndFrame.origin.y = CGRectGetMaxY(endFrame);
        self.floatingButton.frame = floatyEndFrame;
      }
      
		} completion:^(BOOL finished) {
      if (finished) {
        for (UIView *overlay in self.overlays) {
          [overlay removeFromSuperview];
        }
        self.overlays = nil;
        [self removeFromSuperview];
      }
		}];
		
	} else {
    for (UIView *overlay in self.overlays) {
      [overlay removeFromSuperview];
    }
    self.overlays = nil;
		[self removeFromSuperview];
	}
}

- (void)showWithOverlayInView:(UIView *)inView
{
  [self showWithOverlayInView:inView belowView:nil hiding:nil];
}

- (void)showWithOverlayInView:(UIView *)inView
                    belowView:(UIView *)belowView
                       hiding:(NSArray *)additionalViews
{
  for (UIView *overlay in self.overlays) {
    [overlay removeFromSuperview];
  }
	
  NSMutableArray *overlays = [NSMutableArray arrayWithCapacity:additionalViews.count + 1];
  
  // add a background
	CGRect overlayFrame = inView.bounds;
  UIView *overlay = [self makeOverlay:overlayFrame];
  [overlays addObject:overlay];
  
  // optional overlays
  for (UIView *viewToHide in additionalViews) {
    CGRect frame;
    if ([viewToHide isKindOfClass:[UINavigationBar class]]) {
      frame = CGRectMake(0, -20, CGRectGetWidth(viewToHide.frame), CGRectGetMaxY(viewToHide.frame));
    } else {
      frame = [viewToHide.superview convertRect:viewToHide.frame toView:inView];
    }
    UIView *additionalOverlay = [self makeOverlay:frame];
    [overlays addObject:additionalOverlay];
    [viewToHide addSubview:additionalOverlay];
  }
  self.overlays = overlays;
  
  // determine start and end positions for sheet
	CGRect startFrame = self.frame;
  startFrame.size.width = CGRectGetWidth(inView.frame);
	startFrame.origin.y = CGRectGetMaxY(inView.frame) - CGRectGetMinY(inView.frame);
	self.frame = startFrame;
	CGRect endFrame = startFrame;
	endFrame.origin.y -= CGRectGetHeight(startFrame);
  
	self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
  if (belowView) {
    endFrame.origin.y -= CGRectGetHeight(belowView.frame);
    [inView insertSubview:self belowSubview:belowView];
  } else {
    [inView addSubview:self];
  }
  [inView insertSubview:overlay belowSubview:self];

  // optional floating button
  CGRect floatyEndFrame = CGRectNull;
  if (self.floatingButton) {
    floatyEndFrame = self.floatingButton.frame;
    floatyEndFrame.origin.y = CGRectGetMinY(endFrame) - CGRectGetHeight(floatyEndFrame) - 5; // padding
    floatyEndFrame.origin.x = (CGRectGetWidth(endFrame) - CGRectGetWidth(floatyEndFrame)) / 2;
    
    CGRect floatyStartFrame = floatyEndFrame;
    floatyStartFrame.origin.y = CGRectGetMaxY(inView.frame);
    self.floatingButton.frame = floatyStartFrame;
    [inView insertSubview:self.floatingButton belowSubview:self];
  }

  // animate it in
	[UIView animateWithDuration:0.25f animations:^{
    // fade in overlay and move up time picker
    for (UIView *overlayView in self.overlays) {
      overlayView.alpha = 1;
    }
		if (! CGRectIsNull(endFrame)) {
			self.frame = endFrame;
    }
    if (! CGRectIsNull(floatyEndFrame)) {
      self.floatingButton.frame = floatyEndFrame;
    }
  }];
}

- (BOOL)isBeingOverlaid
{
	return nil != self.overlays;
}

#pragma mark - User Interaction

- (IBAction)doneButtonPressed:(id)sender
{
  [self tappedOverlay:sender];
}

- (IBAction)tappedOverlay:(id)sender
{
#pragma unused(sender)
  [self removeOverlay:YES];
}

#pragma mark - UIView

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code
  }
  return self;
}

#pragma mark - Private helpers

- (UIView *)makeOverlay:(CGRect)frame
{
  UIView *overlay = [[UIView alloc] initWithFrame:frame];
	overlay.autoresizingMask = UIViewAutoresizingFlexibleHeight;
  overlay.backgroundColor = [UIColor colorWithRed:54/255.f green:78/255.f blue:108/255.f alpha:0.8f];
  overlay.alpha = 0.0;
  UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOverlay:)];
  [overlay addGestureRecognizer:tapGesture];
  
  // allow accessibility interaction with overlay
  overlay.isAccessibilityElement = YES;
  overlay.accessibilityTraits = UIAccessibilityTraitButton;
  overlay.accessibilityLabel = Loc.Dismiss;

  return overlay;
}

@end
