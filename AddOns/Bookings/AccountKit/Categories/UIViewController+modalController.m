//
//  UIViewController+modalController.m
//  TripGo
//
//  Created by Kuan Lun Huang on 2/06/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "UIViewController+modalController.h"

@implementation UIViewController (modalController)

- (BOOL)isModal
{
  if (self.navigationController != nil) {
    return self.navigationController.viewControllers.firstObject == self;
  }
  
  return NO;
}

@end
