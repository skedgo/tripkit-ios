//
//  SGLabel.m
//  TripGo
//
//  Created by Kuan Lun Huang on 30/03/2015.
//
//

#import "SGLabel.h"

#import "SGRootKit.h"
#import "SGStyleManager+SGCoreUI.h"

@implementation SGLabel

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
    self.font = [SGStyleManager systemFontWithSize:point];
  } else {
    self.font = [SGStyleManager systemFontWithTextStyle:style];
  }
}
  

@end
