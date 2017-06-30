//
//  NSString+Sizing.h
//  TripGo
//
//  Created by Adrian Schoenig on 20/09/13.
//
//

#import "SGKCrossPlatform.h"

@interface NSString (Sizing)

- (CGSize)sizeWithFont:(SGKFont *)font maximumWidth:(CGFloat)maxWidth;

@end
