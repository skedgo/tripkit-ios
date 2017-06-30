//
//  SGTableViewCell.m
//  WotGo
//
//  Created by Brian Huang on 13/07/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

#import "SGTableViewCell.h"

@interface SGTableViewCell ()

// Wrapper constraints
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *wrapperTopMarginConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *wrapperLeadingMarginConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *wrapperTrailingMarginConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *wrapperBottomMarginConstraint;

// Container constraints
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *topContainerHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *middleContainerHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *bottomContainerHeightConstraint;

// Middle container subview constraints
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *middleLeftViewWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *middleRightViewWidthConstraint;

// Contents that are to be added subviews of container view above.
@property (nonatomic, weak) id<SGTableViewCellContentView>topContent;
@property (nonatomic, weak) id<SGTableViewCellContentView>middleLeftContent;
@property (nonatomic, weak) id<SGTableViewCellContentView>middleCenterContent;
@property (nonatomic, weak) id<SGTableViewCellContentView>middleRightContent;
@property (nonatomic, weak) id<SGTableViewCellContentView>bottomContent;

@end

@implementation SGTableViewCell

+ (UINib *)nib
{
  return [UINib nibWithNibName:NSStringFromClass([self class])
                        bundle:[NSBundle bundleForClass:[self class]]];
}

+ (NSString *)reuseId
{
  return NSStringFromClass([self class]);
}

+ (CGFloat)cellHeightWithTop:(id<SGTableViewCellContentView>)top
                  middleLeft:(id<SGTableViewCellContentView>)middleLeft
                middleCenter:(id<SGTableViewCellContentView>)middleCenter
                 middleRight:(id<SGTableViewCellContentView>)middleRight
                      bottom:(id<SGTableViewCellContentView>)bottom
{
  CGFloat base = 0.0f;
  
  if (top != nil) {
    base += [top preferredContentSize].height;
  }
  
  if (bottom != nil) {
    base += [bottom preferredContentSize].height;
  }
  
  NSMutableArray *heights = [NSMutableArray arrayWithCapacity:3];
  if (middleLeft != nil) {
    [heights addObject:@([middleLeft preferredContentSize].height)];
  }
  if (middleCenter != nil) {
    [heights addObject:@([middleCenter preferredContentSize].height)];
  }
  if (middleRight != nil) {
    [heights addObject:@([middleRight preferredContentSize].height)];
  }
  
  if ([heights count] > 0) {
    base += [[heights valueForKeyPath:@"@max.self"] floatValue];
  }
  
  return base;
}

- (void)configureCellWithTop:(id<SGTableViewCellContentView>)top
                  middleLeft:(id<SGTableViewCellContentView>)middleLeft
                middleCenter:(id<SGTableViewCellContentView>)middleCenter
                 middleRight:(id<SGTableViewCellContentView>)middleRight
                      bottom:(id<SGTableViewCellContentView>)bottom
{
  if (! middleCenter) {
    ZAssert(false, @"Middle center view cannot be nil");
  }
  
  [self resetContainers];
  
  _topContent = top;
  _middleLeftContent = middleLeft;
  _middleCenterContent = middleCenter;
  _middleRightContent = middleRight;
  _bottomContent = bottom;
  
  [_middleCenterView addSubview:(UIView *)middleCenter];
  
  if (top != nil) {
    [_topContainer addSubview:(UIView *)top];
  }
  
  if (middleLeft != nil) {
    [_middleLeftView addSubview:(UIView *)middleLeft];
  }
  
  if (middleRight != nil) {
    [_middleRightView addSubview:(UIView *)middleRight];
  }
  
  if (bottom) {
    [_bottomContainer addSubview:(UIView *)bottom];
  }
  
  [self setNeedsUpdateConstraints];
}

- (void)setContentInsets:(UIEdgeInsets)contentInsets
{
  _wrapperTopMarginConstraint.constant = contentInsets.top;
  _wrapperLeadingMarginConstraint.constant = contentInsets.left;
  _wrapperBottomMarginConstraint.constant = contentInsets.bottom;
  _wrapperTrailingMarginConstraint.constant = contentInsets.right;
}

#pragma mark - Table view cell

- (void)prepareForReuse
{
  [self resetContainers];
  
  [super prepareForReuse];
}

- (void)updateConstraints
{
  [self adjustConstraints];
  
//  [_middleCenterView addSubview:(UIView *)_middleCenterContent];
  if (_middleCenterContent != nil) {
    [self snapSubviewToSuperView:(UIView *)_middleCenterContent];
  }  
  
  if (_topContent != nil) {
//    [_topContainer addSubview:(UIView *)_topContent];
    [self snapSubviewToSuperView:(UIView *)_topContent];
  }
  
  if (_middleLeftContent != nil) {
//    [_middleLeftView addSubview:(UIView *)_middleLeftContent];
    [self snapSubviewToSuperView:(UIView *)_middleLeftContent];
  }
  
  if (_middleRightContent != nil) {
//    [_middleRightView addSubview:(UIView *)_middleRightContent];
    [self snapSubviewToSuperView:(UIView *)_middleRightContent];
  }
  
  if (_bottomContent != nil) {
//    [_bottomContainer addSubview:(UIView *)_bottomContent];
    [self snapSubviewToSuperView:(UIView *)_bottomContent];
  }
  
  [super updateConstraints];
}

#pragma mark - Private methods

- (void)resetContainers
{
  [self removeAllSubviewsFromSuperview:_topContainer];
  [self removeAllSubviewsFromSuperview:_bottomContainer];
  [self removeAllSubviewsFromSuperview:_middleLeftView];
  [self removeAllSubviewsFromSuperview:_middleCenterView];
  [self removeAllSubviewsFromSuperview:_middleRightView];
}

- (void)snapSubviewToSuperView:(UIView *)subview
{
  [subview setTranslatesAutoresizingMaskIntoConstraints:NO];
  
  NSDictionary *viewDict = NSDictionaryOfVariableBindings(subview);
  NSArray *hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[subview]-0-|" options:kNilOptions metrics:nil views:viewDict];
  NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[subview]-0-|" options:kNilOptions metrics:nil views:viewDict];
  [subview.superview addConstraints:hConstraints];
  [subview.superview addConstraints:vConstraints];
}

- (void)removeAllSubviewsFromSuperview:(UIView *)view
{
  for (UIView *subview in view.subviews) {
    [subview removeFromSuperview];
  }
}

- (void)adjustConstraints
{
  if (! _topContent) {
    _topContainerHeightConstraint.constant = 0;
  } else {
    _topContainerHeightConstraint.constant = [_topContent preferredContentSize].height;
  }
  
  if (! _bottomContent) {
    _bottomContainerHeightConstraint.constant = 0;
  } else {
    _bottomContainerHeightConstraint.constant = [_bottomContent preferredContentSize].height;
  }
  
  // Middle container constraints.
  NSMutableArray *heigts = [NSMutableArray arrayWithCapacity:3];
  [heigts addObject:@([_middleCenterContent preferredContentSize].height)];
  
  if (_middleLeftContent != nil) {
    _middleLeftViewWidthConstraint.constant = [_middleLeftContent preferredContentSize].width;
    [heigts addObject:@([_middleLeftContent preferredContentSize].height)];
  } else {
    _middleLeftViewWidthConstraint.constant = 0;
  }
  
  if (_middleRightContent != nil) {
    _middleRightViewWidthConstraint.constant = [_middleRightContent preferredContentSize].width;
    [heigts addObject:@([_middleRightContent preferredContentSize].height)];
  } else {
    _middleRightViewWidthConstraint.constant = 0;
  }
  
  _middleContainerHeightConstraint.constant = [[heigts valueForKeyPath:@"@max.self"] floatValue];
}

@end
