//
//  SGButton.m
//  TripKit
//
//  Created by Kuan Lun Huang on 30/03/2015.
//
//

#import "SGButton.h"

#ifndef TK_NO_FRAMEWORKS

#endif

#import "SGStyleManager+SGCoreUI.h"

@implementation SGButton

- (instancetype)init
{
  self = [super init];
  
  if (self) {
    [self commonInit];
  }
  
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  
  if (self) {
    [self commonInit];
  }
  
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  
  if (self) {
    [self commonInit];
  }
  
  return self;
}

#pragma mark - Private methods

- (void)commonInit
{
  NSString *style = [[self.titleLabel.font fontDescriptor] fontAttributes][UIFontDescriptorTextStyleAttribute];
  
  if (! style) {
    CGFloat point = self.titleLabel.font.pointSize;
    self.titleLabel.font = [SGStyleManager systemFontWithSize:point];
  } else {
    self.titleLabel.font = [SGStyleManager systemFontWithTextStyle:style];
  }
}

@end
