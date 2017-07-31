//
//  UITableView+SafeReload.m
//  TripKit
//
//  Created by Adrian Schoenig on 23/12/16.
//
//

#import "UITableView+SafeReload.h"

@implementation UITableView (SafeReload)

- (void)safelyReloadRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
  @try {
    [self reloadRowsAtIndexPaths:indexPaths withRowAnimation:animation];
  }
  @catch (NSException *exception) {
    [self reloadData];
  }
}

@end
