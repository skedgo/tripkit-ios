//
//  NSString+Sizing.m
//  TripGo
//
//  Created by Adrian Schoenig on 20/09/13.
//
//

#import "NSString+Sizing.h"

@implementation NSString (Sizing)

- (CGSize)sizeWithFont:(SGKFont *)font maximumWidth:(CGFloat)maxWidth
{
  NSDictionary *atts = @{NSFontAttributeName: font};
  NSStringDrawingContext *context = [[NSStringDrawingContext alloc] init];
  context.minimumScaleFactor = 1;
  CGRect box = [self boundingRectWithSize:CGSizeMake(maxWidth, 0)
                                  options:NSStringDrawingUsesLineFragmentOrigin
                               attributes:atts
                                  context:context];
  return CGSizeMake((CGFloat) ceil(box.size.width), (CGFloat) ceil(box.size.height));
}

@end
