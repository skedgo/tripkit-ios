//
//  UIBarButtonItem+NavigationBar.m
//  TripKit
//
//  Created by Kuan Lun Huang on 6/07/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "UIBarButtonItem+NavigationBar.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#endif


@implementation UIBarButtonItem (NavigationBar)

+ (UIBarButtonItem *)closeButtonWithSelector:(SEL)selector forController:(UIViewController *)controller
{
  return [[UIBarButtonItem alloc] initWithTitle:Loc.Close
                                          style:UIBarButtonItemStylePlain
                                         target:controller
                                         action:selector];
}

+ (UIBarButtonItem *)cancelButtonWithSelector:(SEL)selector forController:(UIViewController *)controller
{
  return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                       target:controller
                                                       action:selector];
}

+ (UIBarButtonItem *)saveButtonWithSelector:(SEL)selector forController:(UIViewController *)controller
{
  return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                       target:controller
                                                       action:selector];
}



@end
