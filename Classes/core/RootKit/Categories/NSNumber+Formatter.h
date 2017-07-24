//
//  NSNumber+Formatter.h
//  TripKit
//
//  Created by Adrian Schönig on 18/01/12.
//  Copyright (c) 2012 SkedGo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNumber (Formatter)

- (NSString *)toMoneyString:(NSString *)currencySymbol;
- (NSString *)toCarbonString;


@end
