//
//  UITableView+SafeReload.h
//  Pods
//
//  Created by Adrian Schoenig on 23/12/16.
//
//

#import <UIKit/UIKit.h>

@interface UITableView (SafeReload)

- (void)safelyReloadRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation;

@end
