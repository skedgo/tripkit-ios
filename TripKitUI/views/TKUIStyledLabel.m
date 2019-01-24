//
//  TKUIStyledLabel.m
//  TripKit
//
//  Created by Kuan Lun Huang on 30/03/2015.
//
//

#import "TKUIStyledLabel.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
#import "TripKitUI/TripKitUI-Swift.h"
#endif

#import "TKStyleManager+TripKitUI.h"

@implementation TKUIStyledLabel

#pragma mark - Initializers

- (instancetype)init
{
  self = [super init];
  
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

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  
  if (self) {
    [self commonInit];
  }
  
  return self;
}

#pragma mark - Private methods

- (void)commonInit
{
  NSString *style = [[self.font fontDescriptor] fontAttributes][UIFontDescriptorTextStyleAttribute];
  
  if (! style) {
    CGFloat point = self.font.pointSize;
    self.font = [TKStyleManager systemFontWithSize:point];
  } else {
    self.font = [TKStyleManager customFontForTextStyle:style];
  }
}
  

@end
