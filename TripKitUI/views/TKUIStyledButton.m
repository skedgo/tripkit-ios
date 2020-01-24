//
//  TKUIStyledButton.m
//  TripKit
//
//  Created by Kuan Lun Huang on 30/03/2015.
//
//

#import "TKUIStyledButton.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
#import "TripKitUI/TripKitUI-Swift.h"
#endif

#import "TKStyleManager+TripKitUI.h"

@implementation TKUIStyledButton

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
    self.titleLabel.font = [TKStyleManager systemFontWithSize:point];
  } else {
    self.titleLabel.font = [TKStyleManager customFontForTextStyle:style];
  }
}

@end