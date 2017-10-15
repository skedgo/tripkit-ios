//
//  BPKActionOverlay.m
//  TripKit
//
//  Created by Kuan Lun Huang on 16/03/2015.
//
//

#import "BPKActionOverlay.h"

#import "SGStyleManager.h"

#define DEFAULT_HEIGHT 50.0f

@interface BPKActionOverlay ()

@property (nonatomic, copy) void (^actionBlock)(void);

@end

@implementation BPKActionOverlay

+ (void)showWithTitle:(NSString *)title inView:(UIView *)view onAction:(void (^)(void))actionBlock completion:(void (^)(BOOL))completion
{
  BPKActionOverlay *overlay = [[self alloc] initWithTitle:title actionBlock:actionBlock];
  
  if (! overlay) {
    return;
  } else {
    [overlay showInView:view completion:completion];
  }
}

- (instancetype)initWithTitle:(NSString *)title actionBlock:(void(^)(void))actionBlock
{
  UINib *nib = [UINib nibWithNibName:NSStringFromClass([self class])
                              bundle:[NSBundle bundleForClass:[self class]]];
  NSArray *nibViews = [nib instantiateWithOwner:self options:nil];
  self = nibViews[0];
  
  if (self) {
    [self.button setTitle:title forState:UIControlStateNormal];
    [self.button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self setBackgroundColor:[SGStyleManager globalTintColor]];
    [self setActionBlock:actionBlock];
  }
  
  return self;
}

- (void)showInView:(UIView *)view completion:(void (^)(BOOL))completion
{
  for (UIView *subview in view.subviews) {
    if ([subview isKindOfClass:[self class]]) {
      DLog(@"Existing action overlay found. Remove it");
      [subview removeFromSuperview];
    }
  }
  
  [view addSubview:self];
  
  [self prepareForShowingInView:view];
  
  [UIView animateWithDuration:0.5f
                   animations:
   ^{
     CGRect frame = self.frame;
     frame.origin.y = CGRectGetHeight(view.frame) - self.frame.size.height;
     self.frame = frame;
   }
                   completion:
   ^(BOOL finished) {
     if (completion) {
       completion(finished);
     }
   }];
}

#pragma mark - Private methods

- (void)prepareForShowingInView:(UIView *)view
{
  CGRect initialFrame = CGRectMake(0.0f, CGRectGetHeight(view.frame), CGRectGetWidth(view.frame), CGRectGetHeight(self.frame));
  [self setFrame:initialFrame];
  
  [self setNeedsLayout];
  [self layoutIfNeeded];
  
  CGSize size = [self systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
  
  CGRect frame = self.frame;
  frame.size.height = size.height;
  self.frame = frame;
}

#pragma mark - User interactions

- (void)buttonPressed:(id)sender
{
#pragma unused (sender)
  if (_actionBlock != nil) {
    _actionBlock();
  }
}

@end
