//
//  SGMapButtonView.m
//  TripKit
//
//  Created by Adrian Schoenig on 26/09/13.
//
//

#import "SGMapButtonView.h"

#import "UIView+Helpers.h"
#import "MKMapView+AttributionView.h"

static const CGFloat ExtraPadding = 5;

@interface SGMapButtonView ()

@property (nonatomic, assign) CGFloat lastWidth;
@property (nonatomic, weak) MKMapView *mapView;

@property (nonatomic, assign) UIEdgeInsets defaultMapLayoutMargins;

@end

@implementation SGMapButtonView

+ (CGRect)mapButtonFrameForViewController:(UIViewController *)viewController
                          withExtraOffset:(CGFloat)extraOffset
{  
  UIView *view = viewController.view;
  CGRect viewFrame = CGRectMake(ExtraPadding, 0, CGRectGetWidth(view.frame) - ExtraPadding * 2, 44 + ExtraPadding * 1.5);
  viewFrame.origin.y = CGRectGetHeight(view.frame) - CGRectGetHeight(viewFrame) - extraOffset;
  viewFrame.origin.y -= [[viewController bottomLayoutGuide] length];
  return viewFrame;
}


- (id)initWithFrame:(CGRect)frame forMapView:(MKMapView *)mapView
{
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code
    self.lastWidth = -1;
    self.mapView = mapView;
    
    self.compensateHorizontalOffset = NO;
    self.mapViewBottomLayoutMarginOffset = 0.0f;
    self.defaultMapLayoutMargins = self.mapView.layoutMargins;
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  [self setItems:self.items];
}

- (void)setItems:(NSArray *)items
{
  [self setItems:items animated:NO];
}

- (void)setItems:(NSArray *)items animated:(BOOL)animated
{
#pragma unused(animated)
  CGFloat availableWidth = CGRectGetWidth(self.frame);
  if ([_items isEqualToArray:items] && fabs(self.lastWidth - availableWidth) < 1)
    return;
  
  _items = items; // don't call setter!
  self.lastWidth = availableWidth;
  
  [self removeAllSubviews];
  
  // calculate the widths
  NSMutableArray *groupWidths = [NSMutableArray arrayWithCapacity:items.count];
  CGFloat currentWidth = 0;
  CGFloat totalWidth   = 0;
  for (id object in items) {
    if ([object isKindOfClass:[UIView class]]) {
      UIView *view = (UIView *)object;
      currentWidth += CGRectGetWidth(view.frame);
    } else if ([object isKindOfClass:[NSNumber class]]) {
      NSNumber *number = (NSNumber *)object;
      currentWidth += number.floatValue;
    } else {
      [groupWidths addObject:@(currentWidth)];
      totalWidth += currentWidth;
      currentWidth = 0;
    }
  }
  if (groupWidths.count > 3) {
    // boo fucking hoo.
    return;
  }
  [groupWidths addObject:@(currentWidth)];
  totalWidth += currentWidth;

  // calculate the spaces
  CGFloat totalSpace = availableWidth - totalWidth;
  NSArray *spaces;
  if (groupWidths.count == 1) {
    // space on right => nothing to do
    spaces = @[];
    
  } else if (groupWidths.count == 2) {
    // space in the middle
    spaces = @[ @(totalSpace) ];
  
  } else if (groupWidths.count == 3) {
    // one left, one right
    CGFloat leftSpace  = 0;
    CGFloat rightSpace = 0;
    
    CGFloat leftWidth  = [groupWidths[0] floatValue];
    CGFloat rightWidth = [groupWidths[2] floatValue];
    if (leftWidth > rightWidth) {
      CGFloat leftDiff = (leftWidth - rightWidth);
      rightSpace += leftDiff;
      totalSpace -= leftDiff;
      leftSpace  += totalSpace / 2;
      rightSpace += totalSpace / 2;
    } else {
      CGFloat rightDiff = (rightWidth - leftWidth);
      leftSpace  += rightDiff;
      totalSpace -= rightDiff;
      leftSpace  += totalSpace / 2;
      rightSpace += totalSpace / 2;
    }
    spaces = @[ @(leftSpace), @(rightSpace) ];
  }
  
  // For some reason, even though the buttons were added to the view starting with
  // x = 0, there always seems to be a leading space of length 2 * extra padding.
  // This causes the right button, e.g., exit full screen, to go off screen. To
  // correct it, we offset the origin in the x-asix here.
  CGFloat x = 0;
  if (self.compensateHorizontalOffset) {
    x = -2 * ExtraPadding;
  }
  
  // now place stuff
  int spaceI = 0;
  for (id object in items) {
    if ([object isKindOfClass:[UIView class]]) {
      UIView *view = (UIView *)object;
      CGRect rect = [view frame];
      rect.origin.x = x;
      rect.origin.y = (CGRectGetHeight(self.frame) - CGRectGetHeight(rect)) / 2;
      
      view.frame = rect;
      [self addSubview:view];
      
      x += CGRectGetWidth(rect);
    } else if ([object isKindOfClass:[NSNumber class]]) {
      NSNumber *number = (NSNumber *)object;
      x += number.floatValue;
    } else {
      NSNumber *space = spaces[spaceI++];
      x += [space floatValue];
    }
  }
  
  [self adjustAttributionLabel];
}

#pragma mark - Private helpers

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
#pragma unused(event)
  for (UIView *subview in self.subviews) {
    if (CGRectContainsPoint(subview.frame, point)) {
      return YES;
    }
  }
  return NO;
}

- (void)adjustAttributionLabel
{
  UIView *attributionLabel = [self.mapView attributionView];
  if (! attributionLabel)
    return;
  
  self.mapView.layoutMargins = self.defaultMapLayoutMargins;
  
  // We want the attribution label to appear on the right of the
  // leftmost button.
  UIView *leftmostItem = [self.items firstObject];
  CGFloat leftMargin = 0.0f;
  if (leftmostItem) {
    leftMargin = leftmostItem.frame.origin.x + leftmostItem.frame.size.width;
    leftMargin += 8.0f; // for horizontal spacing.
    UIEdgeInsets mapLayoutMargins = self.mapView.layoutMargins;
    mapLayoutMargins.left = leftMargin;
    mapLayoutMargins.bottom += self.mapViewBottomLayoutMarginOffset;
    self.mapView.layoutMargins = mapLayoutMargins;
  }
}

@end
