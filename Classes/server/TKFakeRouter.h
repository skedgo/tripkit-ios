//
//  BHFakeRouter.h
//  TripKit
//
//  Created by Adrian Schönig on 9/02/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKRouter.h"

@class TKRoutingParser;

@interface TKFakeRouter : TKRouter {
}

@property (nonatomic, strong) TKRoutingParser *parser;

@end
