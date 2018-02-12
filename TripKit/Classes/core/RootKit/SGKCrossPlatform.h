//
//  SGKCrossPlatform.h
//  SkedGoKit
//
//  Created by Adrian Schoenig on 1/08/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

#ifndef SGKCrossPlatform_h
#define SGKCrossPlatform_h

#include <TargetConditionals.h>

#if TARGET_OS_IPHONE

@import UIKit;
#define SGKColor UIColor
#define SGKImage UIImage
#define SGKFont UIFont

#else
@import AppKit;
#define SGKColor NSColor
#define SGKImage NSImage
#define SGKFont NSFont

#endif

#endif /* SGKCrossPlatform_h */
