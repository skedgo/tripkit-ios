//
//  TKCrossPlatform.h
//  SkedGoKit
//
//  Created by Adrian Schoenig on 1/08/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

#ifndef TKCrossPlatform_h
#define TKCrossPlatform_h

#include <TargetConditionals.h>

#if TARGET_OS_IPHONE

@import UIKit;
#define TKColor UIColor
#define TKImage UIImage
#define TKFont UIFont

#else
@import AppKit;
#define TKColor NSColor
#define TKImage NSImage
#define TKFont NSFont

#endif

#endif /* TKCrossPlatform_h */
