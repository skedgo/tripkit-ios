//
//  UIViewController+RootPresenter.m
//  TripGo
//
//  Created by Kuan Lun Huang on 4/02/2015.
//
//

#import "UIViewController+RootPresenter.h"

@implementation UIViewController (RootPresenter)

- (UIViewController *)findRootPresenter
{
  UIViewController *immediate = self.presentingViewController;
  
  while (immediate.presentingViewController != nil) {
    immediate = immediate.presentingViewController;
  }
  
  return immediate;
}

@end
