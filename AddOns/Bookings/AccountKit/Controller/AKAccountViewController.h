//
//  AMKSimpleAccountViewController.h
//  TripGo
//
//  Created by Kuan Lun Huang on 27/02/2015.
//
//

#import "AKBaseTableViewController.h"

@class AMKUser;

@protocol AKAccountViewControllerDelegate;

@interface AKAccountViewController : AKBaseTableViewController

@property (nonatomic, strong) AMKUser *user;

@property (nonatomic, weak) id<AKAccountViewControllerDelegate> delegate;

@end

@protocol AKAccountViewControllerDelegate <NSObject>

@optional

- (void)accountViewControllerDidCompleteSignOut;

@end
