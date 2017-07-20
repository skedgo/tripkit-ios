//
//  SGBPOptionViewController.h
//  TripGo
//
//  Created by Kuan Lun Huang on 3/02/2015.
//
//

#import <UIKit/UIKit.h>

@class BPKSectionItem;

@protocol BPKOptionsViewControllerDelegate;

@interface BPKOptionsViewController : UITableViewController

@property (nonatomic, weak) id<BPKOptionsViewControllerDelegate> delegate;

- (instancetype)initWithItem:(BPKSectionItem *)item;

@end

@protocol BPKOptionsViewControllerDelegate <NSObject>

- (void)optionViewController:(BPKOptionsViewController *)ctr didSelectItemAtIndex:(NSInteger)index;

@end
