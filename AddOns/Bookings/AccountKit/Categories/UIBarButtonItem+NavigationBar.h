//
//  UIBarButtonItem+NavigationBar.h
//  TripGo
//
//  Created by Kuan Lun Huang on 6/07/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBarButtonItem (NavigationBar)

+ (UIBarButtonItem *)nextButtonWithSelector:(SEL)selector forController:(UIViewController *)controller;

+ (UIBarButtonItem *)closeButtonWithSelector:(SEL)selector forController:(UIViewController *)controller;

+ (UIBarButtonItem *)cancelButtonWithSelector:(SEL)selector forController:(UIViewController *)controller;

+ (UIBarButtonItem *)doneButtonWithSelector:(SEL)selector forController:(UIViewController *)controller;

+ (UIBarButtonItem *)saveButtonWithSelector:(SEL)selector forController:(UIViewController *)controller;

@end
